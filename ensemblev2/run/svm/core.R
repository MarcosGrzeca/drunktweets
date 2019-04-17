# https://rpubs.com/Minxing2046/396053
library(caret)

treinarPoly <- function(data_train){
	fit <- train(x = subset(data_train, select = -c(resposta)),
			y = data_train$resposta, 
			# method = "svmPoly", 
			method = "svmLinear", 
			trControl = trainControl(method = "cv", number = 5, savePred=T, classProbs = TRUE))
	return (fit)
}

library(tools)
library(caret)
library(doMC)
library(mlbench)
library(magrittr)

if (isset(coreCustomizado)) {
	CORES <- coreCustomizado
} else {
	CORES <- 5
}
registerDoMC(CORES)

set.seed(10)
split=0.80
for (year in 1:5) {
  try({
	load(file = datasetFile)
	levels(maFinal$resposta) <- make.names(levels(factor(maFinal$resposta)))
	if (datasetFile == "amazon/rdas/2gram-entidades-erro.Rda") {
		trainIndex <- createDataPartition(maFinal$resposta, p=split, list=FALSE)
		saveRDS(trainIndex, file = paste0(baseResampleFiles, "trainIndex", year, ".rds"))
	} else {
		trainIndex <- readRDS(file = paste0(baseResampleFiles, "trainIndex", year, ".rds"))
	}
	data_train <- as.data.frame(unclass(maFinal[ trainIndex,]))
	data_test <- maFinal[-trainIndex,]
	treegram25NotNull <- treinarPoly(data_train)

	pred <- predict(treegram25NotNull, subset(data_test, select = -c(resposta)), type = "prob") %>% 
  			mutate('class'=names(.)[apply(., 1, which.max)])

	saveRDS(pred$X1, file = paste0(baseResultsFiles, "svm", year, ".rds"))
  })
}
