library(tools)

fileName <- "ipm/results_q2.Rdata"
source(file_path_as_absolute("ipm/loads.R"))

epochs <- c(2,3,4)
batchs <- c(32, 64, 128, 164, 200)

for (epoch in epochs) {
	for (batch in batchs) {
		for (year in 1:10){
		  try({
		  	enriquecimento <- 1
		  	load("chat/rdas/sequencesexp5-semkw.RData")
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
			      batch_size = batch,
			      epochs = epoch,
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
			      batch_size = batch,
			      epochs = epoch,
			      validation_split = 0.2
			    )

			  # history
			  predictions <- model %>% predict(list(test_vec$textEmbedding))
			}

			predictions2 <- round(predictions, 0)
			matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
			resultados <- addRowAdpater(resultados, paste0("Exp 5 - Hidden - Enr: ", enriquecimento, " Ep: ", epoch, " - Ba: ", " - ", batch), matriz)
			saveRDS(resultados, file = "ipm/expsperdidos/resultadosautomatico/resultados_exp5_enriquecidos_1.rds"))
		  })
		}
	}
}
resultados$F1
resultados$Precision
resultados$Recall