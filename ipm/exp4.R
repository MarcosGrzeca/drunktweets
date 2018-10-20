library(tools)

#tensorboard("tensorruns")

fileName <- "ipm/results_q4.Rdata"
source(file_path_as_absolute("ipm/loads.R"))

DESC <- "Exp4 - CNN + Semantic Enrichment + Word embeddings"

for (year in 1:10){
  try({
    load("rdas/sequences.RData")
    FLAGS <- flags(
	  flag_integer("epochs", 3),
	  flag_integer("batch_size", 64)
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

	main_output <- layer_concatenate(c(ccn_out, entities_out, types_out)) %>%  
	  layer_dense(units = 64, activation = 'relu') %>% 
	  layer_dropout(0.2) %>%
	  layer_dense(units = 32, activation = "relu") %>%
	  layer_dense(units = 1, activation = 'sigmoid')

	model <- keras_model(
	  inputs = c(main_input, auxiliary_input, auxiliary_input_types),
	  outputs = main_output
	)

	# Compile model
	model %>% compile(
	  loss = "binary_crossentropy",
	  optimizer = "adam",
	  metrics = "accuracy"
	)

	# callbacks = list(
	#   callback_tensorboard(
	#     log_dir = "tensorruns/exp4",
	#     histogram_freq = 1,
	#     embeddings_freq = 1
	#   )
	# )

	history <- model %>%
	  fit(
	    x = list(train_vec$new_textParser, sequences, sequences_types),
	    y = array(dados_train$resposta),
	    batch_size = FLAGS$batch_size,
	    epochs = FLAGS$epochs,
	    validation_split = 0.2
	    #, callbacks = callbacks
	  )

	predictions <- model %>% predict(list(test_vec$new_textParser, sequences_test, sequences_test_types))
	predictions2 <- round(predictions, 0)
	matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
	resultados <- addRowAdpater(resultados, DESC, matriz)
  })
}
# save.image(file=fileName)
resultados$F1
resultados$Precision
resultados$Recall