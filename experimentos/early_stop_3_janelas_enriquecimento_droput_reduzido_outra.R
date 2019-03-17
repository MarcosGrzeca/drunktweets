library(tools)
source(file_path_as_absolute("ipm/loads.R"))

enriquecimento <- 1
early_stop <- 1

for (year in 1:20) {
	load("amazon/rdas/sequencesexp6.RData")

	library(keras)

	callbacks_list <- list(
		callback_early_stopping(
			# monitor = "val_loss",
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
		flag_integer("epochs", 10),
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

	auxiliary_input <- layer_input(shape = c(max_sequence))
	entities_out <- auxiliary_input

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
										layer_dense(units = 4, activation = "relu", kernel_regularizer = regularizer_l2(0.001))

		enriquecimento_output <- layer_concatenate(c(entities_out, types_out)) %>% 
										layer_dense(units = 2, activation = "relu", kernel_regularizer = regularizer_l2(0.001))

		main_output <- layer_concatenate(c(cnn_output, enriquecimento_output)) %>% 
										layer_dropout(0.1) %>%
										layer_dense(units = 1, activation = 'sigmoid')
		model <- keras_model(
			inputs = c(main_input, auxiliary_input, auxiliary_input_types),
			outputs = main_output
		)
	} else {
		cnn_output <- layer_concatenate(c(ccn_out_3, ccn_out_4, ccn_out_5)) %>% 
										layer_dropout(0.2) %>%
										layer_dense(units = 4, activation = "relu")

		main_output <- cnn_output %>%
						layer_dropout(0.1) %>%
						layer_dense(units = 1, activation = 'sigmoid')

		model <- keras_model(
			inputs = c(main_input),
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
		history <- model %>%
			fit(
			  x = list(train_vec$new_textParser, sequences, sequences_types),
			  y = array(dados_train$resposta),
			  batch_size = FLAGS$batch_size,
			  epochs = FLAGS$epochs,
			  callbacks = callbacks_list,
			  validation_split = 0.2
			)	
		predictions <- model %>% predict(list(test_vec$new_textParser, sequences_test, sequences_test_types))
	} else {
		history <- model %>%
			fit(
			  x = list(train_vec$new_textParser),
			  y = array(dados_train$resposta),
			  batch_size = FLAGS$batch_size,
			  epochs = FLAGS$epochs,
			  callbacks = callbacks_list,
			  validation_split = 0.2
			)
			
		predictions <- model %>% predict(list(test_vec$new_textParser))
	}
	predictions2 <- round(predictions, 0)
	matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
	resultados <- addRowAdpater(resultados, paste0("Enriquecimento: ", enriquecimento, " - Early: ", early_stop), matriz)
}
resultados$F1
resultados$Precision
resultados$Recall