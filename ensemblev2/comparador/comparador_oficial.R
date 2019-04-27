library(caret)
library(dplyr)

expName <- "ds2"

for (year in 1:5) {
	svmResults <- readRDS(file = paste0("ensemblev2/resultados/", expName, "/svm", year, ".rds"))
	xgboost <- readRDS(file = paste0("ensemblev2/resultados/", expName, "/xgboost", year, ".rds"))
	nnResults <- readRDS(file = paste0("ensemblev2/resultados/", expName, "/neuralprob", year, ".rds"))

	if (expName == "exp1") {
		datasetFile <-"ensemble/datasets/exp1/2-Gram-dbpedia-types-enriquecimento-info-q1-not-null_info_entidades.Rda"
  } else if (expName == "exp2") {
    datasetFile <-"ensemble/datasets/exp2/2-Gram-dbpedia-types-enriquecimento-info-q2-not-null_info_entidades.Rda"
  } else if (expName == "exp3") {
    datasetFile <-"ensemble/datasets/exp3/2-Gram-dbpedia-types-enriquecimento-info-q3-not-null_info_entidades.Rda"
  } else if (expName == "ds2") {
    datasetFile <-"chat/rdas/2gram-entidades-erro-sem-key-words_orderbyid.Rda"
	} else if (expName == "ds3") {
	  datasetFile <-"amazon/rdas/2gram-entidades-erro.Rda"
	}
	
	load(datasetFile)

	trainIndex <- readRDS(file = paste0("ensemblev2/resample/", expName, "/", "trainIndex", year, ".rds"))
	
	data_train <- as.data.frame(unclass(maFinal[ trainIndex,]))
	data_test <- maFinal[-trainIndex,]
	
	bigDataFrame <- bind_cols(list(as.numeric(as.character(svmResults)), as.numeric(as.character(xgboost))))
	pred <- round(rowMeans(bigDataFrame),0)
	
	#bigDataFrame <- bind_cols(list(as.numeric(as.character(svmResults)), as.numeric(as.character(xgboost))))
	#pred <- round(rowMeans(bigDataFrame),0)
	
	# bigDataFrame <- as.numeric(as.character(svmResults))
	# pred <- round(bigDataFrame,0)
	
	pred
		
	matriz <- confusionMatrix(data = as.factor(pred), as.factor(data_test$resposta), positive="1")
	print(matriz$byClass["F1"])
	print(matriz$byClass["Precision"])
	print(matriz$byClass["Recall"])
}
