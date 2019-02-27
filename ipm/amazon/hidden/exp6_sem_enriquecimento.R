library(tools)

fileName <- "ipm/results_q6.Rdata"
source(file_path_as_absolute("ipm/loads.R"))

DESC <- "Exp6 - CNN + Semantic Enrichment + Word embeddings"

for (year in 1:10){
	try({
		load("amazon/rdas/sequencesexp6.RData")
		
		FLAGS <- flags(
			flag_integer("epochs", 2),
			flag_integer("batch_size", 164)
		)

		# Data Preparation --------------------------------------------------------
		# Parameters --------------------------------------------------------------
		embedding_dims <- 100
		filters <- 200
		kernel_size <- 10
		hidden_dims <- 200

		main_input <- layer_input(shape = c(maxlen), dtype = "int32")
		ccn_out <- main_input %>% 
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

		main_output <- ccn_out %>%  
			layer_dense(units = 64, activation = 'relu') %>% 
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
			  validation_split = 0.2
			)
		
		history

		predictions <- model %>% predict(test_vec$new_textParser)
		predictions2 <- round(predictions, 0)
		matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
		resultados <- addRowAdpater(resultados, DESC, matriz)
	  })
}
resultados$F1
resultados$Precision
resultados$Recall
