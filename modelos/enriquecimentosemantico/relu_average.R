library(keras)
library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)

source(file_path_as_absolute("utils/getDados.R"))
load("rdas/sequences.RData")

CORES <- 4
registerDoMC(CORES)

# Data Preparation --------------------------------------------------------
# Parameters --------------------------------------------------------------
batch_size <- 32
epochs <- 3

auxiliary_input <- layer_input(shape = c(max_sequence))
entities_out <- auxiliary_input %>%  
                layer_dense(units = 32, activation = 'relu')

auxiliary_input_types <- layer_input(shape = c(max_sequence_types))
types_out <- auxiliary_input_types %>%  
             layer_dense(units = 32, activation = 'relu')

main_output <- layer_maximum(c(entities_out, types_out)) %>%  
layer_dense(units = 16, activation = 'relu') %>% 
layer_dense(units = 1, activation = 'sigmoid')

model <- keras_model(
  inputs = c(auxiliary_input, auxiliary_input_types),
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
  x = list(sequences, sequences_types),
  y = array(dados_train$resposta),
  batch_size = batch_size,
  epochs = epochs,
  validation_split = 0.2
  )

history
predictions <- model %>% predict(list(sequences_test, sequences_test_types))
predictions2 <- round(predictions, 0)
matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))

adicionarResultadosTestes("relu_concatenate.R apenas semântico", matriz$byClass["F1"] * 100, matriz$byClass["Precision"] * 100, matriz$byClass["Recall"] * 100)