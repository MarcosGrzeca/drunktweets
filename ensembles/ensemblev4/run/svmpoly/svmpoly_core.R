library(tools)
library(rword2vec)
library(lsa)
library(readr)
library(quanteda)
library(caret)

library(doMC)
Cores <- 8
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

for (year in 1:5) {
	load(embeddingsFile)
	inTrain <- readRDS(file = paste0(baseResampleFiles, "trainIndex", year, ".rds"))

	tam <- ncol(X) - 1
	one_hot_train <- X[inTrain, 1:tam]
	resposta <-  X[inTrain, ncol(X)]
	
	one_hot_test <- X[-inTrain, 1:tam]
	resposta_test <-  X[-inTrain, ncol(X)]
  
	classifier <- treinarPoly(one_hot_train, resposta)

  	# out-of-sample accuracy
  	preds <- predict(classifier, one_hot_test)
	saveRDS(preds, file = paste0(baseResultsFiles, "svmpoly", year, ".rds"))
}