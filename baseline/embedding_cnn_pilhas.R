library(keras)
library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)

load("rdas/baseline_embeddings_q3.RData")

# Data Preparation --------------------------------------------------------
# Parameters --------------------------------------------------------------
embedding_dims <- 75
max_features <- 10000
filters <- 32
kernel_size <- 7
hidden_dims <- 50

model <- keras_model_sequential() %>%
  layer_embedding(input_dim = max_features, output_dim = 75,
                  input_length = maxlen) %>%
  layer_conv_1d(filters = 32, kernel_size = 7, activation = "relu") %>%
  layer_max_pooling_1d(pool_size = 4) %>%
  layer_conv_1d(filters = 32, kernel_size = 7, activation = "relu") %>%
  layer_global_max_pooling_1d() %>%
  layer_dense(units = 64, activation = "relu") %>%
  layer_dropout(0.2) %>%
  layer_dense(units = 32, activation = "relu") %>%
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
    epochs = 3,
    validation_split = 0.2
  )

history

predictions <- model %>% predict_classes(test_vec$textEmbedding)
matriz <- confusionMatrix(data = as.factor(predictions), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))
