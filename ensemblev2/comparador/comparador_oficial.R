library(caret)
library(dplyr)

expName <- "exp2"

for (year in 1:1) {
  year <- 1
	svmResults <- readRDS(file = paste0("ensemblev2/resultados/", expName, "/svm", year, ".rds"))
	xgboost <- readRDS(file = paste0("ensemblev2/resultados/", expName, "/xgboost", year, ".rds"))
	nnResults <- readRDS(file = paste0("ensemblev2/resultados/", expName, "/neuralprob", year, ".rds"))

	if (expName == "exp1") {
		datasetFile <-"ensemble/datasets/exp1/2-Gram-dbpedia-types-enriquecimento-info-q1-not-null_info_entidades.Rda"
	} else if (expName == "ds3") {
		#Verificar
		# load("amazon/rdas/2gram-entidades-erro.Rda")
	}
	
	load(datasetFile)

	trainIndex <- readRDS(file = paste0("ensemblev2/resample/", expName, "/", "trainIndex", year, ".rds"))
	data_train <- as.data.frame(unclass(maFinal[ trainIndex,]))
	data_test <- maFinal[-trainIndex,]
	
	str(svmResults)
	str(nnResults)
	str(xgboost)
	
	bigDataFrame <- bind_cols(list(as.numeric(as.character(svmResults)), as.numeric(as.character(nnResults)), as.numeric(as.character(xgboost))))
	View(bigDataFrameSum)
	
	bigDataFrameSum <- rowSums(bigDataFrame)
	
	result <- bigDataFrameSum / 3
	pred <- round(result,0)
		
	matriz <- confusionMatrix(data = as.factor(pred), as.factor(data_test$resposta), positive="1")
	print(matriz$byClass["F1"])
	print(matriz$byClass["Precision"])
	print(matriz$byClass["Recall"])
}
