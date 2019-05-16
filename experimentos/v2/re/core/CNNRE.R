library(tools)

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")

early_stop <- 1

if (!isset(bow_opt)) {
	bow_opt <- 1
}

library(keras)
iteracoes <- 0
while (iteracoes < 20) {
	source(file_path_as_absolute(fileGetDados))
	word_index <- tokenizer$word_index
	embedding_dims <- 100


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

	FLAGS <- flags(
		flag_integer("epochs", 3),
		flag_integer("batch_size", 64)
	)

	# Data Preparation --------------------------------------------------------
	# Parameters --------------------------------------------------------------
	embedding_dims <- 100
	filters <- 24
	hidden_dims <- 10

	main_input <- layer_input(shape = c(maxlen), dtype = "int32")

	embedding_input <- 	main_input %>% 
				 		layer_embedding(input_dim = vocab_size, output_dim = embedding_dims, input_length = maxlen)
	
	input_bow <- layer_input(shape = c(max_words))
	bow_out <- input_bow

	auxiliary_input_entidades <- layer_input(shape = c(max_sequence))
	entities_out <- auxiliary_input_entidades

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
						layer_dense(units = 8, activation = "relu", kernel_regularizer = regularizer_l2(0.001))

		if (bow_opt) {
			auxilary_output <- layer_concatenate(c(bow_out, entities_out, types_out)) %>% 
							layer_dropout(0.2) %>%
							layer_dense(units = 8, activation = "relu", kernel_regularizer = regularizer_l2(0.001))
		} else {
			auxilary_output <- layer_concatenate(c(ntities_out, types_out)) %>% 
							layer_dropout(0.2) %>%
							layer_dense(units = 2, activation = "relu", kernel_regularizer = regularizer_l2(0.001))
		}
		
		main_output <- layer_concatenate(c(cnn_output, auxilary_output)) %>% 
				# layer_dropout(0.2) %>%
				layer_dense(units = 24, activation = "relu", kernel_regularizer = regularizer_l2(0.001)) %>%
				layer_dense(units = 1, activation = 'sigmoid')

		model <- keras_model(
			inputs = c(main_input, input_bow, auxiliary_input_entidades, auxiliary_input_types),
			outputs = main_output
		)
	} else {
		cnn_output <- layer_concatenate(c(ccn_out_3, ccn_out_4, ccn_out_5)) %>% 
						layer_dropout(0.2) %>%
						layer_dense(units = 8, activation = "relu", kernel_regularizer = regularizer_l2(0.001))

		if (bow_opt) {
			auxilary_output <- bow_out	%>% 
							layer_dropout(0.2) %>%
							layer_dense(units = 8, activation = "relu", kernel_regularizer = regularizer_l2(0.001))
		}
		
		if (bow_opt) {
			main_output <- layer_concatenate(c(cnn_output, auxilary_output)) %>% 
					layer_dense(units = 24, activation = "relu", kernel_regularizer = regularizer_l2(0.001)) %>%
					layer_dense(units = 1, activation = 'sigmoid')
		} else {
			main_output <- cnn_output %>% 
					layer_dense(units = 24, activation = "relu", kernel_regularizer = regularizer_l2(0.001)) %>%
					layer_dense(units = 1, activation = 'sigmoid')
		}

		model <- keras_model(
			inputs = c(main_input, input_bow),
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
		if (bow_opt == 1) {
			entrada <- list(dados_train_sequence, dataframebow_train, sequences, sequences_types)
		} else {
			entrada <- list(dados_train_sequence, sequences, sequences_types)
		}

		history <- model %>%
			fit(
			  x = entrada,
			  y = array(dados_train$resposta),
			  batch_size = FLAGS$batch_size,
			  epochs = epoca,
			  callbacks = callbacks_list,
			  validation_split = 0.2
			)
		if (bow_opt == 1) {
			predictions <- model %>% predict(list(dados_test_sequence, dataframebow_test, sequences_test, sequences_test_types))
		} else {
			predictions <- model %>% predict(list(dados_test_sequence, sequences_test, sequences_test_types))
		}
	} else {
		if (bow_opt == 1) {
			entrada <- list(dados_train_sequence, dataframebow_train)
		} else {
			entrada <- list(dados_train_sequence)
		}
		history <- model %>%
			fit(
			  x = entrada,
			  y = array(dados_train$resposta),
			  batch_size = FLAGS$batch_size,
			  epochs = epoca,
			  callbacks = callbacks_list,
			  validation_split = 0.2
			)

		if (bow_opt == 1) {
			predictions <- model %>% predict(list(dados_test_sequence, dataframebow_test))
		} else {
			predictions <- model %>% predict(list(dados_test_sequence))
		}
	}

	predictions2 <- round(predictions, 0)
	matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
	if (matriz$byClass["Recall"] * 100 > 50) {
		if (matriz$byClass["Precision"] * 100 > 50) {

			if (isset(die)) {
				if (die == 1) {
					library(dplyr)

					embedding_matrixTwo <- get_weights(model)[[1]]
					words <- data_frame(
					  word = names(tokenizer$word_index), 
					  id = as.integer(unlist(tokenizer$word_index))
					)

					words <- words %>%
					  filter(id <= tokenizer$num_words) %>%
					  arrange(id)

					row.names(embedding_matrixTwo) <- c("UNK", words$word)
					write.table(embedding_matrixTwo, embedding_result,sep=" ",row.names=TRUE)

					break;
				}
			}
	        iteracoes <- iteracoes + 1
			resultados <- addRowAdpater(resultados, paste0("Enriquecimento: ", enriquecimento, " - Early: ", early_stop), matriz)
		}
	}
}
resultados$F1
resultados$Precision
resultados$Recall