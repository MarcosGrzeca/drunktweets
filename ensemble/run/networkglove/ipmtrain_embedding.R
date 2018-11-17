#Preparação dos dados

# maxlen <- 38
# max_words <- 5000

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")

try({
  load(imageFile)
})


for (year in 1:10){
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
  #trainIndex <- createDataPartition(dados$resposta, p=0.8, list=FALSE)
  trainIndex <- readRDS(file = paste0(baseResampleFiles, "trainIndex", year, ".rds"))
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

  try({
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

    library(keras)
    # Training ----------------------------------------------------------------        
    history <- model %>%
      fit(
        x = list(dados_train_sequence, train_sequences, train_sequences_types),
        y = array(dados_train$resposta),
        batch_size = 64,
        epochs = 3,
        validation_split = 0.2
      )

    # history
    predictions <- model %>% predict(list(dados_test_sequence, test_sequences, test_sequences_types))
    predictions2 <- round(predictions, 0)
    saveRDS(predictions2, file = paste0(baseResultsFiles, "neural", year, ".rds"))
    saveRDS(predictions, file = paste0(baseResultsFiles, "neuralprob", year, ".rds"))

    matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
    resultados <- addRowAdpater(resultados, DESC, matriz)
    save.image(file=imageFile)
  })
}