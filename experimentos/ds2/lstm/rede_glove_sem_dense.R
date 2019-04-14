library(tools)

#max_words <- vocab_size
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

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")

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

	# Data Preparation --------------------------------------------------------
	# Parameters --------------------------------------------------------------
	embedding_dims <- 100
	filters <- 20
	hidden_dims <- 10

	main_input <- layer_input(shape = c(maxlen), dtype = "int32")

	embedding_input <- 	main_input %>% 
				 		layer_embedding(input_dim = vocab_size, output_dim = embedding_dims, input_length = maxlen)

	auxiliary_input <- layer_input(shape = c(max_sequence))
	entities_out <- auxiliary_input

	auxiliary_input_types <- layer_input(shape = c(max_sequence_types))
	types_out <- auxiliary_input_types

    lstm_out <- embedding_input %>% 
    		layer_lstm(units = 16, return_sequences = TRUE) %>%
  			layer_lstm(units = 16, return_sequences = TRUE, recurrent_dropout = 0.2) %>%
  			layer_lstm(units = 16)

	if (enriquecimento == 1) {
		main_output <- layer_concatenate(c(lstm_out, entities_out, types_out)) %>% 
				layer_dropout(0.2) %>%
				layer_dense(units = 4, activation = "relu") %>%
				layer_dense(units = 1, activation = 'sigmoid')

		model <- keras_model(
			inputs = c(main_input, auxiliary_input, auxiliary_input_types),
			outputs = main_output
		)
	} else {
		main_output <- lstm_out %>% 
				layer_dropout(0.2) %>%
				layer_dense(units = 4, activation = "relu") %>%
				layer_dense(units = 1, activation = 'sigmoid')

		model <- keras_model(
			inputs = c(main_input),
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
			  x = list(dados_train_sequence, sequences, sequences_types),
			  y = array(dados_train$resposta),
			  batch_size = FLAGS$batch_size,
			  epochs = epoca,
			  callbacks = callbacks_list,
			  validation_split = 0.2
			)
		predictions <- model %>% predict(list(dados_test_sequence, sequences_test, sequences_test_types))
	} else {
		history <- model %>%
			fit(
			  x = list(dados_train_sequence),
			  y = array(dados_train$resposta),
			  batch_size = FLAGS$batch_size,
			  epochs = epoca,
			  callbacks = callbacks_list,
			  validation_split = 0.2
			)
		predictions <- model %>% predict(list(dados_test_sequence))
	}

	predictions2 <- round(predictions, 0)
	matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
	resultados <- addRowAdpater(resultados, paste0("Enriquecimento: ", enriquecimento, " - Early: ", early_stop), matriz)
}
resultados$F1
resultados$Precision
resultados$Recall