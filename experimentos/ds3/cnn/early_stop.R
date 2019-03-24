library(tools)
source(file_path_as_absolute("ipm/loads.R"))

enriquecimento <- 1
early_stop <- 1

for (year in 1:20) {
	load("amazon/rdas/sequencesexp6.RData")

	library(keras)

	callbacks_list <- list(
		callback_early_stopping(
			monitor = "acc",
			patience = 1
		),
		callback_model_checkpoint(
			filepath = paste0(enriquecimento, "", early_stop, "", "test_models.h5"),
			monitor = "val_loss",
			save_best_only = TRUE
		)
	)

	FLAGS <- flags(
		flag_integer("epochs", 5),
		flag_integer("batch_size", 64)
	)

	# Data Preparation --------------------------------------------------------
	# Parameters --------------------------------------------------------------
	embedding_dims <- 100
	filters <- 128
	# kernel_size <- 7
	# kernel_size <- 7
	kernel_size <- 5
	kernel_size <- c(3,4,5)
	hidden_dims <- 10

	main_input <- layer_input(shape = c(maxlen), dtype = "int32")
	ccn_out <- main_input %>% 
		layer_embedding(vocab_size, embedding_dims, input_length = maxlen) %>%
		layer_dropout(0.1) %>%
		layer_conv_1d(
		  filters, c(3,5), 
		  padding = "valid", activation = "relu", strides = 1
		) %>%
		# layer_global_max_pooling_1d(4) %>%
		layer_max_pooling_1d(4) %>%
		layer_lstm(70) %>%
		layer_dense(hidden_dims)
		# layer_max_pooling_1d(pool_size = 4) %>%
  # 		layer_conv_1d(filters = 32, kernel_size = 7, activation = "relu") %>%

	auxiliary_input <- layer_input(shape = c(max_sequence))
	entities_out <- auxiliary_input

	auxiliary_input_types <- layer_input(shape = c(max_sequence_types))
	types_out <- auxiliary_input_types

	if (enriquecimento == 1) {
		main_output <- layer_concatenate(c(ccn_out, entities_out, types_out)) %>%  
			layer_dense(units = 64, activation = 'relu') %>% 
			layer_dropout(0.2) %>%
			layer_dense(units = 32, activation = "relu") %>%
			layer_dense(units = 1, activation = 'sigmoid')

		model <- keras_model(
			inputs = c(main_input, auxiliary_input, auxiliary_input_types),
			outputs = main_output
		)
	} else {
		main_output <- ccn_out %>%  
			layer_dense(units = 32, activation = 'relu') %>% 
			layer_dropout(0.2) %>%
			layer_dense(units = 16, activation = "relu") %>%
			layer_dense(units = 1, activation = 'sigmoid')

		model <- keras_model(
			inputs = main_input,
			outputs = main_output
		)
	}

	# Compile model
	model %>% compile(
		loss = "binary_crossentropy",
		optimizer = "adam",
		metrics = "accuracy"
	)

	if (enriquecimento == 1) {
		if (early_stop == 1) {
			history <- model %>%
				fit(
				  x = list(train_vec$new_textParser, sequences, sequences_types),
				  y = array(dados_train$resposta),
				  batch_size = FLAGS$batch_size,
				  epochs = FLAGS$epochs,
				  callbacks = callbacks_list,
				  validation_split = 0.2
				)
		} else {
			history <- model %>%
			fit(
			  x = list(train_vec$new_textParser, sequences, sequences_types),
			  y = array(dados_train$resposta),
			  batch_size = FLAGS$batch_size,
			  epochs = FLAGS$epochs,
			  validation_split = 0.2
			)
		}

		predictions <- model %>% predict(list(test_vec$new_textParser, sequences_test, sequences_test_types))
		predictions2 <- round(predictions, 0)
	} else {
		if (early_stop == 1) {
			history <- model %>%
				fit(
				  x = train_vec$new_textParser,
				  y = array(dados_train$resposta),
				  batch_size = FLAGS$batch_size,
				  epochs = FLAGS$epochs,
				  callbacks = callbacks_list,
				  validation_split = 0.2
				)
		} else {
			history <- model %>%
			fit(
			  x = train_vec$new_textParser,
			  y = array(dados_train$resposta),
			  batch_size = FLAGS$batch_size,
			  epochs = FLAGS$epochs,
			  validation_split = 0.2
			)

		}

		predictions <- model %>% predict(test_vec$new_textParser)
		predictions2 <- round(predictions, 0)
	}
	matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
	resultados <- addRowAdpater(resultados, paste0("Enriquecimento: ", enriquecimento, " - Early: ", early_stop), matriz)
}
resultados$F1
resultados$Precision
resultados$Recall