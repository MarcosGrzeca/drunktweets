library(keras)
library(tools)

# Data Preparation --------------------------------------------------------
load("rdas/baseline_one_hot_char_level_q3.RData")

# MODEL --------------------------------------------------------------
model <- keras_model_sequential() %>%
  layer_dense(units = 32, activation = "relu", input_shape = c(ncol(one_hot_train))) %>%
  layer_dropout(0.5) %>%
  layer_dense(units = 16, activation = "relu") %>%
  layer_dense(units = 1, activation = "sigmoid")

model %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = "accuracy"
)

# Training ----------------------------------------------------------------
history <- model %>%
  fit(
    one_hot_train, array(dados_train$resposta),
    batch_size = 64,
    epochs = 5,
    validation_split = 0.2
  )

history

predictions <- model %>% predict_classes(one_hot_test)
matriz <- confusionMatrix(data = as.factor(predictions), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))
