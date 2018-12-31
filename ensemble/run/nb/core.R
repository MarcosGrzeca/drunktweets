library(caret)

treinarNB <- function(data_train){
	mtry <- sqrt(ncol(data_train))
	tunegrid <- expand.grid(.mtry=mtry)
	fit <- train(x = subset(data_train, select = -c(resposta)),
			y = data_train$resposta, 
			method = "nb",
			trControl = trainControl(method = "cv", number = 5, savePred=T, sampling = "up"))
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
for (year in 1:10){
	load(file = datasetFile)
	maFinal$resposta <- as.factor(maFinal$resposta)
	trainIndex <- readRDS(file = paste0(baseResampleFiles, "trainIndex", year, ".rds"))

	data_train <- as.data.frame(unclass(maFinal[ trainIndex,]))
	data_test <- maFinal[-trainIndex,]

	treegram25NotNull <- treinarNB(data_train)
	treegram25NotNull
	pred <- predict(treegram25NotNull, subset(data_test, select = -c(resposta)))

	saveRDS(pred, file = paste0(baseResultsFiles, "nb", year, ".rds"))
 	matriz3Gram25NotNull <- confusionMatrix(data = pred, data_test$resposta, positive="1")
	resultados <- addRow(resultados, "2 GRAM - Entidades - Erro", matriz3Gram25NotNull)
	save.image(file=imageFile)
}
