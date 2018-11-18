library(caret)
library(dplyr)

for (year in 1:5) {
	svmResults <- readRDS(file = paste0("ensemble/resultados/exp3/svm", year, ".rds"))
	rfResults <- readRDS(file = paste0("ensemble/resultados/exp3/rf", year, ".rds"))
	nnResults <- readRDS(file = paste0("ensemble/resultados/exp3/neural", year, ".rds"))
	
	load("ensemble/datasets/exp3/2-Gram-dbpedia-types-enriquecimento-info-q3-not-null_info_entidades.Rda")
	trainIndex <- readRDS(file = paste0("ensemble/resample/exp3/", "trainIndex", year, ".rds"))
	data_train <- as.data.frame(unclass(maFinal[ trainIndex,]))
	data_test <- maFinal[-trainIndex,]
	

	bigDataFrame <- bind_cols(list(as.numeric(as.character(svmResults)), as.numeric(as.character(nnResults)), as.numeric(as.character(rfResults))))
	
	bigDataFrameSum <- rowSums(bigDataFrame)
	
	result <- bigDataFrameSum / 3
	pred <- round(result,0)
	
	data_test$resposta
	matriz <- confusionMatrix(data = as.factor(pred), as.factor(data_test$resposta), positive="1")
	print(matriz$byClass["F1"])
	print(matriz$byClass["Precision"])
	print(matriz$byClass["Recall"])
}