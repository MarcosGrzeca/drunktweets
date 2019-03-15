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

  flag_integer("epochs", 3),
  flag_integer("batch_size", 64)
)

# Data Preparation --------------------------------------------------------
# Parameters --------------------------------------------------------------
embedding_dims <- 50
filters <- 32
kernel_size <- 7
hidden_dims <- 50

main_input3 <- layer_input(shape = c(maxlen), dtype = "int32")
main_input4 <- layer_input(shape = c(maxlen), dtype = "int32")
main_input5 <- layer_input(shape = c(maxlen), dtype = "int32")

ccn_out3 <- main_input3 %>% 
  layer_embedding(vocab_size, embedding_dims, input_length = maxlen) %>%
  layer_conv_1d(
    filters, kernel_size, 
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  layer_global_max_pooling_1d()

ccn_out4 <- main_input4 %>% 
  layer_embedding(vocab_size, embedding_dims, input_length = maxlen) %>%
  layer_conv_1d(
    filters, kernel_size + 1, 
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  layer_global_max_pooling_1d()

ccn_out5 <- main_input5 %>% 
  layer_embedding(vocab_size, embedding_dims, input_length = maxlen) %>%
  layer_conv_1d(
    filters, kernel_size + 2, 
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  layer_global_max_pooling_1d()

auxiliary_input <- layer_input(shape = c(max_sequence))
entities_out <- auxiliary_input %>%  
                layer_dense(units = FLAGS$dense_units1, activation = 'relu')

auxiliary_input_types <- layer_input(shape = c(max_sequence_types))
types_out <- auxiliary_input_types %>%  
                layer_dense(units = FLAGS$dense_units1, activation = 'relu')

main_output <- layer_concatenate(c(ccn_out3, ccn_out4, ccn_out5)) %>%  
  layer_dense(units = FLAGS$dense_units2, activation = 'relu') %>% 
  layer_dense(units = 1, activation = 'sigmoid')

model <- keras_model(
  inputs = c(main_input3, main_input4, main_input5),
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
    x = list(train_vec$new_textParser, train_vec$new_textParser, train_vec$new_textParser),
    y = array(dados_train$resposta),
    batch_size = FLAGS$batch_size,
    epochs = FLAGS$epochs,
    validation_split = 0.2
  )

history

predictions <- model %>% predict(list(test_vec$new_textParser, test_vec$new_textParser, test_vec$new_textParser))
#predictions
predictions2 <- round(predictions, 0)

matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))
