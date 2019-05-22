library(caret)

treinar <- function(data_train, resposta){
    fit <- train(
            x = data_train,
            y = resposta, 
            method = "svmLinear", 
            trControl = trainControl(method = "cv", number = 5, savePred=T))
    return (fit)
}

treinarPoly <- function(data_train, resposta) {
    fit <- train(
            x = data_train,
            y = resposta, 
            method = "svmPoly", 
            trControl = trainControl(method = "cv", number = 5, savePred=T))
    return (fit)
}

getMatriz <- function(fit, data_test, resposta) {
  pred <- predict(fit, data_test)
  matriz <- confusionMatrix(data = pred, resposta, positive="1")
  return (matriz)
}

addRow <- function(resultados, rowName, matriz, ...) {
  newRes <- data.frame(matriz$byClass["F1"], matriz$byClass["Precision"], matriz$byClass["Recall"])
  rownames(newRes) <- rowName
  names(newRes) <- c("F1", "Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

addRowSimple <- function(resultados, rowName, precision, recall) {
  newRes <- data.frame(rowName, precision, recall)
  rownames(newRes) <- rowName
  names(newRes) <- c("Name", "Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}