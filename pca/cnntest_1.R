library(tools)
source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/getDadosAmazon.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("ipm/glove/load.R"))
source(file_path_as_absolute("pca/loader.R"))
baseResampleFiles <- "ensemblev2/resample/ds3/"

library(caret)
library(tools)
library(keras)

set.seed(10)
split=0.80

for (year in 1:20) {
  year <- 1
	trainIndex <- readRDS(file = paste0(baseResampleFiles, "trainIndex", year, ".rds"))
	# trainIndex <- createDataPartition(dados$resposta, p=0.8, list=FALSE)
	
	dados_train <- data[ trainIndex,]
	dados_test <- data[-trainIndex,]

	train_sequences <- pca_entities$x[ trainIndex,]
	train_sequences_types <- pca_types$x[ trainIndex,]

	test_sequences <- pca_entities$x[-trainIndex,]
	test_sequences_types <- pca_types$x[-trainIndex,]

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

	callbacks_list <- list(
		callback_early_stopping(
			monitor = "val_loss",
			patience = 1
			),
		callback_model_checkpoint(
			filepath = paste0("test_models.h5"),
			monitor = "val_loss",
			save_best_only = TRUE
			)
		)

	FLAGS <- 	flags(
					flag_integer("batch_size", 64)
				)

	# Data Preparation --------------------------------------------------------
	# Parameters --------------------------------------------------------------
	embedding_dims <- 100
	filters <- 164

	main_input <- layer_input(shape = c(maxlen), dtype = "int32")

	embedding_input <-  main_input %>% 
						layer_embedding(input_dim = vocab_size, output_dim = embedding_dims, input_length = maxlen)
	
	ccn_out_3 <- 	embedding_input %>% 
					layer_conv_1d(
						filters, 3,
						padding = "valid", activation = "relu", strides = 1
						) %>%
					layer_global_max_pooling_1d()

	ccn_out_4 <- 	embedding_input %>% 
					layer_conv_1d(
						filters, 4, 
						padding = "valid", activation = "relu", strides = 1
						) %>%
					layer_global_max_pooling_1d()

	ccn_out_5 <- 	embedding_input %>% 
					layer_conv_1d(
						filters, 5, 
						padding = "valid", activation = "relu", strides = 1
						) %>%
					layer_global_max_pooling_1d()

	cnn_output <- 	layer_concatenate(c(ccn_out_3, ccn_out_4, ccn_out_5)) %>% 
					layer_dropout(0.2) %>%
					layer_dense(units = 8, activation = "relu", kernel_regularizer = regularizer_l2(0.001))

	auxiliary_input_entidades <- layer_input(shape = c(max_sequence))
	auxiliary_input_types <- layer_input(shape = c(max_sequence_types))

	auxilary_output <- layer_concatenate(c(auxiliary_input_entidades, auxiliary_input_types))

	auxiliar <- 	auxilary_output %>% 
					layer_dropout(0.2) %>%
					layer_dense(units = 8, activation = "relu", kernel_regularizer = regularizer_l2(0.001))

	main_output <- 	layer_concatenate(c(cnn_output, auxiliar)) %>% 
					layer_dense(units = 24, activation = "relu", kernel_regularizer = regularizer_l2(0.001)) %>%
					layer_dense(units = 1, activation = 'sigmoid')

	model <- keras_model(
		inputs = c(main_input, auxiliary_input_entidades, auxiliary_input_types),
		outputs = main_output
	)

	get_layer(model, index = 1) %>%
	set_weights(list(embedding_matrix)) %>%
	freeze_weights()

	# Compile model
	model %>% compile(
		loss = "binary_crossentropy",
		optimizer = "adam",
		metrics = "accuracy"
		)

	history <- 	model %>%
				fit(
					x = list(dados_train, train_sequences, train_sequences_types),
					y = array(dados[trainIndex,]$resposta),
					batch_size = FLAGS$batch_size,
					epochs = 5,
					callbacks = callbacks_list,
					validation_split = 0.2
				)

	predictions <- model %>% predict(list(dados_test, test_sequences, test_sequences_types))
	predictions2 <- round(predictions, 0)

    matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados[-trainIndex,]$resposta), positive="1")
    matriz
    resultados <- addRowAdpater(resultados, "Com enriquecimento", matriz)
}

resultados$F1
resultados$Precision
resultados$Recall