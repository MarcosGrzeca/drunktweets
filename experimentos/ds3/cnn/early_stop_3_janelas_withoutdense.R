library(tools)
source(file_path_as_absolute("ipm/loads.R"))

enriquecimento <- 0
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
		flag_integer("epochs", 4),
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

	main_output <- layer_concatenate(c(ccn_out_3, ccn_out_4, ccn_out_5)) %>% 
			layer_dropout(0.2) %>%
			layer_dense(units = 32, activation = "relu") %>%
			layer_dense(units = 1, activation = 'sigmoid')

	model <- keras_model(
		inputs = main_input,
		outputs = main_output
	)

	# Compile model
	model %>% compile(
		loss = "binary_crossentropy",
		optimizer = "adam",
		metrics = "accuracy"
	)

	history <- model %>%
		fit(
		  x = train_vec$new_textParser,
		  y = array(dados_train$resposta),
		  batch_size = FLAGS$batch_size,
		  epochs = FLAGS$epochs,
		  callbacks = callbacks_list,
		  validation_split = 0.2
		)
		
	predictions <- model %>% predict(test_vec$new_textParser)
	predictions2 <- round(predictions, 0)
	matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
	resultados <- addRowAdpater(resultados, paste0("Enriquecimento: ", enriquecimento, " - Early: ", early_stop), matriz)
}
resultados$F1
resultados$Precision
resultados$Recall