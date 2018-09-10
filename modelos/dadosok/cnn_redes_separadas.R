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
  flag_integer("batch_size", 64)
)

# Data Preparation --------------------------------------------------------

# Rede text

# Parameters --------------------------------------------------------------
embedding_dims <- 100
filters <- 20
kernel_size <- 10
hidden_dims <- 200

model_text <- keras_model_sequential()
model_text %>% 
  layer_embedding(vocab_size, embedding_dims, input_length = maxlen) %>%
  layer_conv_1d(
    filters, kernel_size, 
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  layer_global_max_pooling_1d() %>%
  layer_dense(hidden_dims) %>%
  layer_dropout(FLAGS$dropout2) %>%
  layer_dense(units = FLAGS$dense_units2, activation = 'relu') %>% 
  layer_dense(units = 1, activation = 'sigmoid')

# Compile model
model_text %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = "accuracy"
)

history_text <- model_text %>%
  fit(
    x = train_vec$new_textParser,
    y = array(dados_train$resposta),
    batch_size = FLAGS$batch_size,
    epochs = FLAGS$epochs,
    validation_split = 0.2
  )

predictions_text <- model_text %>% predict(test_vec$new_textParser)

#Rede entities
model_entities <- keras_model_sequential() %>%
                layer_dense(units = FLAGS$dense_units1, activation = "relu", input_shape = c(max_sequence)) %>%
                layer_dense(units = FLAGS$dense_units2, activation = 'relu')  %>%
                layer_dense(units = 1, activation = 'sigmoid')

# Compile model
model_entities %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = "accuracy"
)

history_entities <- model_entities %>%
  fit(
    x = sequences,
    y = array(dados_train$resposta),
    batch_size = FLAGS$batch_size,
    epochs = FLAGS$epochs,
    validation_split = 0.2
  )

predictions_entities <- model_entities %>% predict(sequences_test)

#Rede types
model_types <- keras_model_sequential() %>%
              layer_dense(units = FLAGS$dense_units1, activation = "relu", input_shape = c(max_sequence_types)) %>%
              layer_dense(units = FLAGS$dense_units2, activation = 'relu') %>%
              layer_dense(units = 1, activation = 'sigmoid')

# Compile model
model_types %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = "accuracy"
)

history_entities <- model_types %>%
  fit(
    x = sequences_types,
    y = array(dados_train$resposta),
    batch_size = FLAGS$batch_size,
    epochs = FLAGS$epochs,
    validation_split = 0.2
  )

predictions_types <- model_types %>% predict(sequences_test_types)

library(rowr)
maFinal <- cbind.fill(predictions_text, predictions_entities)
maFinal <- cbind.fill(maFinal, predictions_types)
names(maFinal) <- c("text", "entities", "types")

resultadao <- transform(maFinal, prod=text*0.7+entities*0.20+types*0.10)
predictions2 <- round(resultadao$prod, 0)

matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))


resultadao <- transform(maFinal, prod=text*0.7+entities*0.30)
predictions2 <- round(resultadao$prod, 0)

matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))