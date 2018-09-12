library(keras)
library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)

load("rdas/baseline_embeddings.RData")

# Data Preparation --------------------------------------------------------
# Parameters --------------------------------------------------------------
max_features <- 10000

model <- keras_model_sequential() %>%
  layer_embedding(input_dim = max_features, output_dim = 75,
                  input_length = maxlen) %>%
  layer_lstm(units = 16, return_sequences = TRUE) %>%
  layer_lstm(units = 16, return_sequences = TRUE, recurrent_dropout = 0.2) %>%
  layer_lstm(units = 16) %>%
  layer_dense(units = 1, activation = 'sigmoid')

model %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = "accuracy"
)

# Training ----------------------------------------------------------------
history <- model %>%
  fit(
    train_vec$textEmbedding, array(dados_train$resposta),
    batch_size = 64,
    epochs = 4,
    validation_split = 0.2
  )

history

predictions <- model %>% predict_classes(test_vec$textEmbedding)
matriz <- confusionMatrix(data = as.factor(predictions), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))
