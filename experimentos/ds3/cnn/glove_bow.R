library(tools)
source(file_path_as_absolute("utils/getDadosAmazon.R"))
source(file_path_as_absolute("utils/getDados.R"))

dados <- getDadosAmazon()
 
maxlen <- 40
max_words <- 15000

tokenizer <-  text_tokenizer(num_words = max_words) %>%
              fit_text_tokenizer(dados$textEmbedding)

sequences <- texts_to_sequences(tokenizer, dados$textEmbedding)
word_index = tokenizer$word_index

vocab_size <- length(word_index)
vocab_size <- vocab_size + 1

cat("Found", length(word_index), "unique tokens.\n")
data <- pad_sequences(sequences, maxlen = maxlen)

tokenizer_entities <- text_tokenizer(num_words = 1000) %>%
  fit_text_tokenizer(dados$entidades)

vocabEntitiesLenght <- length(tokenizer_entities$word_index)
dados$sequences <- texts_to_sequences(tokenizer_entities, dados$entidades)

tokenizer_types <- text_tokenizer(num_words = 1000) %>%
  fit_text_tokenizer(dados$types)
vocabTypesLenght <- length(tokenizer_types$word_index)
dados$sequences_types <- texts_to_sequences(tokenizer_types, dados$types)

library(caret)
trainIndex <- createDataPartition(dados$resposta, p=0.8, list=FALSE)
dados_train <- dados[ trainIndex,]
dados_test <- dados[-trainIndex,]

dados_train_sequence <- data[ trainIndex,]
dados_test_sequence <- data[-trainIndex,]

max_sequence <- max(sapply(dados_train$sequences, max))
max_sequence_types <- max(sapply(dados_train$sequences_types, max))

train_sequences <- vectorize_sequences(dados_train$sequences, dimension = max_sequence)
train_sequences_types <- vectorize_sequences(dados_train$sequences_types, dimension = max_sequence_types)

test_sequences <- vectorize_sequences(dados_test$sequences, dimension = max_sequence)
test_sequences_types <- vectorize_sequences(dados_test$sequences_types, dimension = max_sequence_types)

#Text parser BoW
tokenizerBow <- text_tokenizer(num_words = 8000) %>%
  fit_text_tokenizer(dados$textParser)

dataframebow_train <- texts_to_matrix(tokenizerBow, dados_train$textParser, mode = "binary")
dataframebow_test  <- texts_to_matrix(tokenizerBow, dados_test$textParser,  mode = "binary")

max_words <- vocab_size
word_index <- tokenizer$word_index
embedding_dims <- 100
embedding_matrix <- array(0, c(max_words, embedding_dims))

for (word in names(word_index)) {
  index <- word_index[[word]]
  if (index < max_words) {
    embedding_vector <- embeddings_index[[word]]
    if (!is.null(embedding_vector))
      embedding_matrix[index+1,] <- embedding_vector
  }
}

library(tools)

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")
# enriquecimento <- 1
# early_stop <- 1

library(keras)
for (year in 1:20) {
	callbacks_list <- list(
		callback_early_stopping(
			monitor = metrica,
			patience = 1
		),
		callback_model_checkpoint(
			filepath = paste0(redeDesc, "", enriquecimento, "", early_stop, "", "test_models.h5"),
			monitor = "val_loss",
			save_best_only = TRUE
		)
	)

	FLAGS <- flags(
		flag_integer("epochs", 3),
		flag_integer("batch_size", 64)
	)

	# Data Preparation --------------------------------------------------------
	# Parameters --------------------------------------------------------------
	embedding_dims <- 100
	filters <- 20
	hidden_dims <- 10

	main_input <- layer_input(shape = c(maxlen), dtype = "int32")

	embedding_input <- 	main_input %>% 
				 		layer_embedding(input_dim = vocab_size, output_dim = embedding_dims, input_length = maxlen)
	
	input_bow <- layer_input(shape = c(8000))
	bow_out <- input_bow

	auxiliary_input_entidades <- layer_input(shape = c(max_sequence))
	entities_out <- auxiliary_input_entidades

	auxiliary_input_types <- layer_input(shape = c(max_sequence_types))
	types_out <- auxiliary_input_types

	ccn_out_3 <- embedding_input %>% 
		layer_conv_1d(
			filters, 3,
		 	padding = "valid", activation = "relu", strides = 1
		) %>%
		layer_global_max_pooling_1d()

	ccn_out_4 <- embedding_input %>% 
		layer_conv_1d(
		  filters, 4, 
		  padding = "valid", activation = "relu", strides = 1
		) %>%
		layer_global_max_pooling_1d()

	ccn_out_5 <- embedding_input %>% 
		layer_conv_1d(
		  filters, 5, 
		  padding = "valid", activation = "relu", strides = 1
		) %>%
		layer_global_max_pooling_1d()

	if (enriquecimento == 1) {
		cnn_output <- layer_concatenate(c(ccn_out_3, ccn_out_4, ccn_out_5)) %>% 
						layer_dropout(0.2) %>%
						layer_dense(units = 8, activation = "relu", kernel_regularizer = regularizer_l2(0.001))

		auxilary_output <- layer_concatenate(c(bow_out, entities_out, types_out)) %>% 
						layer_dropout(0.2) %>%
						layer_dense(units = 8, activation = "relu", kernel_regularizer = regularizer_l2(0.001))
		
		main_output <- layer_concatenate(c(cnn_output, auxilary_output)) %>% 
				# layer_dropout(0.2) %>%
				layer_dense(units = 2, activation = "relu", kernel_regularizer = regularizer_l2(0.001)) %>%
				layer_dense(units = 1, activation = 'sigmoid')

		model <- keras_model(
			inputs = c(main_input, input_bow, auxiliary_input_entidades, auxiliary_input_types),
			outputs = main_output
		)
	} else {
		cnn_output <- layer_concatenate(c(ccn_out_3, ccn_out_4, ccn_out_5)) %>% 
						layer_dropout(0.2) %>%
						layer_dense(units = 8, activation = "relu", kernel_regularizer = regularizer_l2(0.001))

		auxilary_output <- bow_out	%>% 
						layer_dropout(0.2) %>%
						layer_dense(units = 8, activation = "relu", kernel_regularizer = regularizer_l2(0.001))
		
		main_output <- layer_concatenate(c(cnn_output, auxilary_output)) %>% 
				layer_dense(units = 2, activation = "relu", kernel_regularizer = regularizer_l2(0.001)) %>%
				layer_dense(units = 1, activation = 'sigmoid')

		model <- keras_model(
			inputs = c(main_input, input_bow),
			outputs = main_output
		)
	}

	get_layer(model, index = 1) %>%
      set_weights(list(embedding_matrix)) %>%
      freeze_weights()

	# Compile model
	model %>% compile(
		loss = "binary_crossentropy",
		optimizer = "adam",
		metrics = "accuracy"
	)

	if (enriquecimento == 1) {
		history <- model %>%
			fit(
			  x = list(dados_train_sequence, dataframebow_train, train_sequences, train_sequences_types),
			  y = array(dados_train$resposta),
			  batch_size = FLAGS$batch_size,
			  epochs = epoca,
			  callbacks = callbacks_list,
			  validation_split = 0.2
			)
		predictions <- model %>% predict(list(dados_test_sequence, dataframebow_test, test_sequences, test_sequences_types))
	} else {
		history <- model %>%
			fit(
			  x = list(dados_train_sequence, dataframebow_train),
			  y = array(dados_train$resposta),
			  batch_size = FLAGS$batch_size,
			  epochs = epoca,
			  callbacks = callbacks_list,
			  validation_split = 0.2
			)
		predictions <- model %>% predict(list(dados_test_sequence, dataframebow_test))
	}

	predictions2 <- round(predictions, 0)
	matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
	resultados <- addRowAdpater(resultados, paste0("Enriquecimento: ", enriquecimento, " - Early: ", early_stop), matriz)
}
resultados$F1
resultados$Precision
resultados$Recall