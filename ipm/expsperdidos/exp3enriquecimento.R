library(tools)

fileName <- "ipm/results_q2.Rdata"
source(file_path_as_absolute("ipm/loads.R"))

DESC <- "Exp3 - CNN + Semantic Enrichment + Word embeddings"

for (year in 1:10){
  try({
  	enriquecimento <- 0
    load("rdas/baseline_embeddings_q3.RData")
    # Data Preparation --------------------------------------------------------
	# Parameters --------------------------------------------------------------
	embedding_dims <- 100

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


	if (enriquecimento == 1) {
	  main_output <- layer_concatenate(c(relu, entities_out, types_out)) %>%  
	    layer_dense(units = 64, activation = 'relu') %>% 
	    layer_dropout(0.2) %>%
	    layer_dense(units = 32, activation = "relu") %>%
	    layer_dense(units = 1, activation = 'sigmoid')

	    model <- keras_model(
	    inputs = c(main_input, auxiliary_input, auxiliary_input_types),
	    outputs = main_output
	  )

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
	      batch_size = 164,
	      epochs = 4,
	      validation_split = 0.2
	    )

	  # history
	  predictions <- model %>% predict(list(test_vec$textEmbedding, test_sequences, test_sequences_types))
	} else {
	  main_output <- relu %>%  
	    layer_dense(units = 64, activation = 'relu') %>% 
	    layer_dropout(0.2) %>%
	    layer_dense(units = 32, activation = "relu") %>%
	    layer_dense(units = 1, activation = 'sigmoid')

	    model <- keras_model(
	    inputs = c(main_input),
	    outputs = main_output
	  )

	  model %>% compile(
	    loss = "binary_crossentropy",
	    optimizer = "adam",
	    metrics = "accuracy"
	  )

	  # Training ----------------------------------------------------------------
	  history <- model %>%
	    fit(
	      x = list(train_vec$textEmbedding),
	      y = array(dados_train$resposta),
	      batch_size = 164,
	      epochs = 3,
	      validation_split = 0.2
	    )

	  # history
	  predictions <- model %>% predict(list(test_vec$textEmbedding))
	}

	predictions2 <- round(predictions, 0)

	matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
	# matriz
	# print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))

	resultados <- addRowAdpater(resultados, DESC, matriz)
	#save.image(file=fileName)
  })
}
resultados$F1
resultados$Precision
resultados$Recall
