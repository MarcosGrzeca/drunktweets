library(tools)

imageFile <- "ensemble/resultados/exp4/imageFileNB.RData"
datasetFile <-"rdas/2gram-entidades-hora-erro-semkeywords.Rda"

baseResultsFiles <- "ensemble/resultados/exp4/"
baseResampleFiles <- "ensemble/resample/exp4/"

fileResults <- "ensemble/resultados/exp4/"

# source(file_path_as_absolute("ensemble/run/nb/core.R"))

library(caret)

treinarNB <- function(data_train){
	mtry <- sqrt(ncol(data_train))
	tunegrid <- expand.grid(.mtry=mtry)
	fit <- train(x = subset(data_train, select = -c(resposta)),
			y = data_train$resposta, 
			method = "nb",
			trControl = trainControl(method = "cv", number = 5, savePred=T))
	return (fit)
}

getMatriz <- function(fit, data_test) {
  pred <- predict(fit, subset(data_test, select = -c(resposta)))
  matriz <- confusionMatrix(data = pred, data_test$resposta, positive="1")
  return (matriz)
}

addRow <- function(resultados, baseline, matriz, ...) {
  print(baseline)
  newRes <- data.frame(baseline, matriz$byClass["F1"], matriz$byClass["Precision"], matriz$byClass["Recall"])
  rownames(newRes) <- baseline
  names(newRes) <- c("Baseline", "F1", "Precisão", "Revocação")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")

library(tools)
library(caret)
library(doMC)
library(mlbench)
library(magrittr)

try({
  load(imageFile)
})

CORES <- 5
registerDoMC(CORES)

set.seed(10)
split=0.80
for ( in 1:1){
year <- 1
load(file = datasetFile)
maFinal$resposta <- as.factor(maFinal$resposta)
trainIndex <- readRDS(file = paste0(baseResampleFiles, "trainIndex", year, ".rds"))

# data_train <- as.data.frame(unclass(maFinal[ trainIndex,]))
data_train <- maFinal[-trainIndex,]
data_test <- maFinal[-trainIndex,]

treegram25NotNull <- treinarNB(data_train)