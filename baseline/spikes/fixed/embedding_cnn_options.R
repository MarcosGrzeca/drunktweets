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

model <- keras_model_sequential()
model %>% 
  layer_embedding(max_features, embedding_dims, input_length = maxlen) %>%
  layer_flatten() %>%
  layer_dense(units = 64, activation = "relu") %>%
  layer_dropout(0.2) %>%
  layer_dense(units = 32, activation = "relu") %>%
  layer_dense(units = 1, activation = 'sigmoid')



# ccn_out3 <- main_input3 %>% 
#   layer_embedding(vocab_size, embedding_dims, input_length = maxlen) %>%
#   layer_conv_1d(
#     filters, kernel_size, 
#     padding = "valid", activation = "relu", strides = 1
#   ) %>%
#   layer_global_max_pooling_1d()

# layer_conv_2d(filters = 32, kernel_size = c(3, 3), activation = "relu",
#               input_shape = c(28, 28, 1)) %>%
# layer_conv_2d(filters = 64, kernel_size = c(3, 3), activation = "relu") %>%
# layer_conv_2d(filters = 64, kernel_size = c(3, 3), activation = "relu")


model %>% 
  # Start off with an efficient embedding layer which maps
  # the vocab indices into embedding_dims dimensions
  layer_embedding(max_features, embedding_dims, input_length = maxlen) %>%
  layer_dropout(0.2) %>%
  
  # Add a Convolution1D, which will learn filters
  # Word group filters of size filter_length:
  layer_conv_1d(
    filters, kernel_size, 
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  # Apply max pooling:
  layer_global_max_pooling_1d() %>%
  
  # Add a vanilla hidden layer:
  layer_dense(hidden_dims) %>%
  
  # Apply 20% layer dropout
  layer_dropout(0.2) %>%
  layer_activation("relu") %>%
  
  # Project onto a single unit output layer, and squash it with a sigmoid
  
  layer_dense(1) %>%
  layer_activation("sigmoid")


ccn_out4 <- main_input4 %>% 
  layer_embedding(vocab_size, embedding_dims, input_length = maxlen) %>%
  layer_conv_1d(
    filters, kernel_size + 1, 
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  layer_max_pooling_1d(pool_size = 5) %>%
  layer_conv_1d(
    filters, kernel_size + 1, 
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  layer_global_max_pooling_1d()


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

# history

predictions <- model %>% predict_classes(test_vec$textEmbedding)

matriz <- confusionMatrix(data = as.factor(predictions), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))
