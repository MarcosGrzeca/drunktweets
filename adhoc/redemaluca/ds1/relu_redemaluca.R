library(keras)
library(tools)

load("adhoc/redemaluca/ds1/representacao.RData")

one_hot_train <- X[, 1:100]
resposta <-  X[, 101]

# MODEL --------------------------------------------------------------
model <- keras_model_sequential() %>%
  layer_dense(units = 128, activation = "relu", input_shape = c(100)) %>%
  layer_dense(units = 64, activation = "relu") %>%
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
    one_hot_train, resposta,
    batch_size = 64,
    epochs = 5,
    validation_split = 0.2
  )

history

predictions <- model %>% predict_classes(one_hot_test)
matriz <- confusionMatrix(data = as.factor(predictions), as.factor(dados_test$resposta), positive="1")
matriz