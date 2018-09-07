library(keras)
library(caret)
library(tools)
source(file_path_as_absolute("utils/functions.R"))

load("rdas/sequences.RData")

# Data Preparation --------------------------------------------------------
# Parameters --------------------------------------------------------------
epochs <- 4
embedding_dims <- 100
filters <- 200
kernel_size <- 10
hidden_dims <- 200

main_input <- layer_input(shape = c(maxlen), dtype = "int32")
ccn_out <- main_input %>% 
  layer_embedding(vocab_size, embedding_dims, input_length = maxlen) %>%
  layer_dropout(0.2) %>%
  layer_conv_1d(
    filters, kernel_size, 
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  layer_global_max_pooling_1d() %>%
  layer_dense(hidden_dims) %>%
  layer_dense(units = 64, activation = 'relu')

auxiliary_input <- layer_input(shape = c(max_sequence))
entities_out <- auxiliary_input %>%  
                layer_dense(units = 64, activation = 'relu')

auxiliary_input_types <- layer_input(shape = c(max_sequence_types))
types_out <- auxiliary_input_types %>%  
                layer_dense(units = 64, activation = 'relu')

main_output <- layer_multiply(c(ccn_out, entities_out, types_out)) %>%  
  layer_dense(units = 64, activation = 'relu') %>% 
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

callbacks = list(
  callback_tensorboard(
    log_dir = "tensorruns/c",
    histogram_freq = 1,
    embeddings_freq = 1
  )
)

history <- model %>%
  fit(
    x = list(train_vec$new_textParser, sequences, sequences_types),
    y = array(dados_train$resposta),
    batch_size = 128,
    epochs = 4,
    validation_split = 0.2
    #, callbacks = callbacks
  )

history

predictions <- model %>% predict(list(test_vec$new_textParser, sequences_test, sequences_test_types))
predictions2 <- round(predictions, 0)

matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))

adicionarResultadosTestes("Multiply", matriz$byClass["F1"] * 100, matriz$byClass["Precision"] * 100, matriz$byClass["Recall"] * 100)
