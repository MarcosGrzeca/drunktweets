library(tools)
library(text2vec)
library(data.table)
library(SnowballC)
library(keras)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

#Section: Dados classificar
dados <- getDadosBaseline()

#Preparação dos dados
maxlen <- 38
max_words <- 5000
tokenizer <-  text_tokenizer(num_words = max_words) %>%
              fit_text_tokenizer(dados$textEmbedding)

sequences <- texts_to_sequences(tokenizer, dados$textEmbedding)
word_index = tokenizer$word_index

vocab_size <- length(word_index)

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

#FIM generate sequences

fileName <- "ipm/results_q3_generate.Rdata"
source(file_path_as_absolute("ipm/loads.R"))

DESC <- "Exp3 Generate Embeddings - CNN + Semantic Enrichment + Word embeddings"

#Generate embeddings
dadosTreinarEmbeddings <- getDadosWordEmbeddings()

tokens <- dadosTreinarEmbeddings$textEmbedding %>% tolower %>% word_tokenizer

# create vocabulary
it = itoken(tokens)
v <- create_vocabulary(it, stopwords = tm::stopwords("en")) %>% prune_vocabulary(term_count_min = 2)

vectorizer <- vocab_vectorizer(v)

tcm <- create_tcm(it, vectorizer, skip_grams_window = 5L)

embedding_dim <- 100
glove = GlobalVectors$new(word_vectors_size = embedding_dim, vocabulary = v, x_max = 20)
word_vectors_main <- glove$fit_transform(tcm, n_iter = 10)

word_vectors_context = glove$components
embeddings_index = word_vectors_main + t(word_vectors_context)

word_vectors_context[["beer"]]
#Fim Generate embeddings

library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)

#load("rdas/baseline_embeddings_q3.RData")
max_words <- vocab_size

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

for (year in 1:10){
  #try({
		# Parameters --------------------------------------------------------------
		filters <- 200
		kernel_size <- 10
		hidden_dims <- 200

		main_input <- layer_input(shape = c(maxlen), dtype = "int32")
		relu <- main_input %>% 
		  layer_embedding(vocab_size, embedding_dims, input_length = maxlen) %>%
		  layer_dropout(0.1) %>%
		  layer_conv_1d(
		    filters, kernel_size,
		    padding = "valid", activation = "relu", strides = 1
		  ) %>%
		  layer_global_max_pooling_1d() %>%
		  layer_dense(hidden_dims)

		auxiliary_input <- layer_input(shape = c(max_sequence))
		entities_out <- auxiliary_input

		auxiliary_input_types <- layer_input(shape = c(max_sequence_types))
		types_out <- auxiliary_input_types

		main_output <- layer_concatenate(c(relu, entities_out, types_out)) %>%  
		  layer_dense(units = 64, activation = 'relu') %>% 
		  layer_dropout(0.2) %>%
		  layer_dense(units = 32, activation = "relu") %>%
		  layer_dense(units = 1, activation = 'sigmoid')

		model <- keras_model(
		  inputs = c(main_input, auxiliary_input, auxiliary_input_types),
		  outputs = main_output
		)
		
		get_layer(model, index = 1) %>%
		  set_weights(list(embedding_matrix)) %>%
		  freeze_weights()

		model %>% compile(
		  loss = "binary_crossentropy",
		  optimizer = "adam",
		  metrics = "accuracy"
		)

		# Training ----------------------------------------------------------------
		history <- model %>%
		  fit(
		    x = list(train_vec$textEmbedding, train_sequences, train_sequences_types),
		    y = array(dados_train$resposta),
		    batch_size = 64,
		    epochs = 3,
		    validation_split = 0.2
		  )

		# history
		predictions <- model %>% predict(list(test_vec$textEmbedding, test_sequences, test_sequences_types))
		predictions2 <- round(predictions, 0)

		matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
		resultados <- addRowAdpater(resultados, DESC, matriz)
  #})
}
#save.image(file=fileName)
resultados$F1
resultados$Precision
resultados$Recall