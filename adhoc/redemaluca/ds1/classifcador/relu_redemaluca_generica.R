library(keras)
library(tools)
library(caret)

load("adhoc/redemaluca/ds1/dados/representacao_with_PCA.RData")

set.seed(10)
split=0.80

addRowAdpater <- function(resultados, baseline, matriz, ...) {
  print(baseline)
  newRes <- data.frame(baseline, matriz$byClass["F1"] * 100, matriz$byClass["Precision"] * 100, matriz$byClass["Recall"] * 100)
  rownames(newRes) <- baseline
  names(newRes) <- c("Baseline", "F1", "Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")

for (i in 1:10) {

  inTrain <- createDataPartition(y = X[, ncol(X)], p = split, list = FALSE)
  
  one_hot_train <- X[inTrain, 1:ncol(X) - 1]
  resposta <-  X[inTrain, ncol(X)]
  
  one_hot_test <- X[-inTrain, 1:ncol(X) - 1]
  resposta_test <-  X[-inTrain, ncol(X)]
  
  # MODEL --------------------------------------------------------------
  model <- keras_model_sequential() %>%
    layer_dense(units = 128, activation = "relu", input_shape = c(ncol(X) - 1)) %>%
    layer_dense(units = 64, activation = "relu") %>%
    layer_dense(units = 16, activation = "relu") %>%
    layer_dense(units = 1, activation = "sigmoid")

  # model <- keras_model_sequential() %>%
  #   layer_dense(units = 128, activation = "relu", input_shape = c(ncol(one_hot_train))) %>%
  #   layer_dropout(0.2) %>%
  #   layer_dense(units = 16, activation = "relu") %>%
  #   layer_dense(units = 1, activation = "sigmoid")
  
  
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
  matriz <- confusionMatrix(data = as.factor(predictions), as.factor(resposta_test), positive="1")
  #matriz
  
  #print(matriz$byClass["F1"] * 100)
  #print(matriz$byClass["Precision"] * 100)
  #print(matriz$byClass["Recall"] * 100)
  
  resultados <- addRowAdpater(resultados, "MARCOS", matriz)
  View(resultados)
}
resultados