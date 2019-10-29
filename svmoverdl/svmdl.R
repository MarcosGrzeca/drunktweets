library(tools)
library(rword2vec)
library(lsa)
library(readr)
library(quanteda)
library(caret)

library(doMC)
Cores <- 36
registerDoMC(cores=Cores)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("utils/resultadoshelper.R"))
source(file_path_as_absolute("adhoc/quanteda/metrics.R"))

treinarPoly <- function(data_train, resposta) {
    fit <- train(
            x = data_train,
            y = resposta, 
            method = "svmPoly", 
            trControl = trainControl(method = "cv", number = 5, savePred=T))
    return (fit)
}

set.seed(10)
library(xgboost)

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Name", "Precision", "Recall")

addRowSimple <- function(resultados, rowName, precision, recall) {
  newRes <- data.frame(rowName, precision, recall)
  rownames(newRes) <- rowName
  names(newRes) <- c("Name", "Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

for (year in 1:10) {
  load(embeddingsFile)
  inTrain <- sample(1:nrow(X), floor(.80 * nrow(X)))

  tam <- ncol(X) - 1
  one_hot_train <- X[inTrain, 1:tam]
  resposta <-  X[inTrain, ncol(X)]
  resposta <- as.factor(resposta)
  levels(resposta) <- make.names(levels(resposta))
  
  one_hot_test <- X[-inTrain, 1:tam]
  resposta_test <-  X[-inTrain, ncol(X)]
  resposta_test <- as.factor(resposta_test)
  levels(resposta_test) <- make.names(levels(resposta_test))

    
  classifier <- treinarPoly(one_hot_train, resposta)

  # out-of-sample accuracy
  preds <- predict(classifier, one_hot_test)

      resposta_test <- as.factor(resposta_test)
    levels(resposta_test) <- make.names(levels(resposta_test))
    
  matriz <- confusionMatrix(data = predictions, resposta_test, positive="X1")

  matriz <- confusionMatrix(data = preds, resposta_test, positive="X1")
  resultados <- addRowSimple(resultados, "Com", round(matriz$byClass["Precision"] * 100,6), round(matriz$byClass["Recall"] * 100,6))
  View(resultados)
}