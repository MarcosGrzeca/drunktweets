library(keras)
library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)
library(caret)

load("rdas/baseline_embeddings_q3.RData")

# Parameters --------------------------------------------------------------
embedding_dims <- 75
filters <- 30
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
  layer_dropout(0.2) %>%
  layer_dense(units = 16, activation = 'relu') %>% 
  layer_dense(units = 1, activation = 'sigmoid')

# Compile model
model_text %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = "accuracy"
)

history_text <- model_text %>%
  fit(
    x = train_vec$textEmbedding,
    y = array(dados_train$resposta),
    batch_size = 64,
    epochs = 3,
    validation_split = 0.2
  )

predictions_text <- model_text %>% predict(test_vec$textEmbedding)

#Rede entities
model_entities <- keras_model_sequential() %>%
                layer_dense(units = 32, activation = "relu", input_shape = c(max_sequence)) %>%
                layer_dense(units = 8, activation = 'relu')  %>%
                layer_dense(units = 1, activation = 'sigmoid')

# Compile model
model_entities %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = "accuracy"
)

history_entities <- model_entities %>%
  fit(
    x = train_sequences,
    y = array(dados_train$resposta),
    batch_size = 64,
    epochs = 3,
    validation_split = 0.2
  )

predictions_entities <- model_entities %>% predict(test_sequences)

#Rede types
model_types <- keras_model_sequential() %>%
              layer_dense(units = 32, activation = "relu", input_shape = c(max_sequence_types)) %>%
              layer_dense(units = 8, activation = 'relu') %>%
              layer_dense(units = 1, activation = 'sigmoid')

# Compile model
model_types %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = "accuracy"
)

history_entities <- model_types %>%
  fit(
    x = train_sequences_types,
    y = array(dados_train$resposta),
    batch_size = 64,
    epochs = 3,
    validation_split = 0.2
  )

predictions_types <- model_types %>% predict(test_sequences_types)

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

