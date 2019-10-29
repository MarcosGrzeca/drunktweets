library(tools)
library(rword2vec)
library(lsa)
library(readr)
library(quanteda)
library(caret)

library(doMC)
Cores <- 12
registerDoMC(cores=Cores)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("utils/resultadoshelper.R"))
source(file_path_as_absolute("adhoc/quanteda/metrics.R"))

addRowAdpater <- function(resultados, baseline, matriz, ...) {
  newRes <- data.frame(baseline, matriz$byClass["F1"] * 100, matriz$byClass["Precision"] * 100, matriz$byClass["Recall"] * 100)
  rownames(newRes) <- baseline
  names(newRes) <- c("Baseline", "F1", "Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")

treinarPoly <- function(data_train, resposta) {
    fit <- train(
            x = data_train,
            y = resposta, 
            method = "svmPoly", 
			trControl = trainControl(method = "cv", number = 5, savePred=T, classProbs = TRUE))
    return (fit)
}

set.seed(10)

for (year in 1:5) {
	load(embeddingsFile)
	inTrain <- createDataPartition(y = X[, ncol(X)], p = split, list = FALSE)

	tam <- ncol(X) - 1
	one_hot_train <- X[inTrain, 1:tam]
	resposta <-  X[inTrain, ncol(X)]
	
	one_hot_test <- X[-inTrain, 1:tam]
	resposta_test <-  X[-inTrain, ncol(X)]
  
  	resposta <- as.factor(resposta)
	levels(resposta) <- make.names(levels(resposta))
	classifier <- treinarPoly(one_hot_train, as.factor(resposta))

  	# out-of-sample accuracy
  	predictions <- predict(classifier, one_hot_test)
	matriz <- confusionMatrix(data = as.factor(predictions), as.factor(resposta_test), positive="1")
	resultados <- addRowAdpater(resultados, "MARCOS", matriz)
	View(resultados)
}

resultados
mean(resultados$F1)
mean(resultados$Precision)
mean(resultados$Recall)