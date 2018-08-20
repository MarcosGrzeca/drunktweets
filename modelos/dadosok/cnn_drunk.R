library(keras)
library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

load("rdas/sequences.RData")

FLAGS <- flags(
  flag_numeric("dropout1", 0.2),
  flag_numeric("dropout2", 0.2),

  flag_integer("dense_units1", 128),
  flag_integer("dense_units2", 128),

  flag_integer("epochs", 4),
  flag_integer("batch_size", 64),
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
  layer_dropout(FLAGS$dropout1) %>%
  layer_conv_1d(
    filters, kernel_size, 
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  layer_global_max_pooling_1d() %>%
  layer_dense(hidden_dims) %>%
  layer_dropout(FLAGS$dropout2) %>%
  layer_activation("relu")

auxiliary_input <- layer_input(shape = c(max_sequence))
entities_out <- auxiliary_input %>%  
                layer_dense(units = FLAGS$dense_units1, activation = 'relu')

auxiliary_input_types <- layer_input(shape = c(max_sequence_types))
types_out <- auxiliary_input_types %>%  
                layer_dense(units = FLAGS$dense_units1, activation = 'relu')

main_output <- layer_concatenate(c(ccn_out, entities_out, types_out)) %>%  
  layer_dense(units = FLAGS$dense_units2, activation = 'relu') %>% 
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

history <- model %>%
  fit(
    x = list(train_vec$new_textParser, sequences, sequences_types),
    y = array(dados_train$resposta),
    batch_size = FLAGS$batch_size,
    epochs = FLAGS$epochs,
    validation_split = 0.2
  )

history

evaluation <- model %>% evaluate(
  list(test_vec$new_textParser, sequences_test, sequences_test_types),
  array(dados_test$resposta),
  batch_size = FLAGS$batch_size
)
evaluation

predictions <- model %>% predict(list(test_vec$new_textParser, sequences_test, sequences_test_types))
#predictions
predictions2 <- round(predictions, 0)

matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))