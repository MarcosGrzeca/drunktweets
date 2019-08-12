library(caret)
library(dplyr)

expName <- "exp3"

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("F1", "Precision", "Recall")

addRowAdpaterBamos <- function(resultados, f1, precision, recall) {
  newRes <- data.frame(f1, precision, recall)
  rownames(newRes) <- "Exp"
  names(newRes) <- c("F1", "Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

for (year in 1:5) {
	svmResults <- readRDS(file = paste0("ensembles/ensemblev3/resultados/", expName, "/svm", year, ".rds"))
	xgboost <- readRDS(file = paste0("ensembles/ensemblev4/resultados/", expName, "/xgboost", year, ".rds"))
	nnResults <- readRDS(file = paste0("ensembles/ensemblev3/resultados/", expName, "/newdl/neuralprob", year, ".rds"))
	svmLoko <- readRDS(file = paste0("ensembles/ensemblev4/resultados/", expName, "/svmpoly", year, ".rds"))
	
	if (expName == "exp1") {
		datasetFile <-"ensembles/ensemble/datasets/exp1/2-Gram-dbpedia-types-enriquecimento-info-q1-not-null_info_entidades.Rda"
  } else if (expName == "exp2") {
    datasetFile <-"ensembles/ensemble/datasets/exp2/2-Gram-dbpedia-types-enriquecimento-info-q2-not-null_info_entidades.Rda"
  } else if (expName == "exp3") {
    datasetFile <-"ensembles/ensemble/datasets/exp3/2-Gram-dbpedia-types-enriquecimento-info-q3-not-null_info_entidades.Rda"
  } else if (expName == "ds2") {
    datasetFile <-"chat/rdas/2gram-entidades-erro-sem-key-words_orderbyid.Rda"
	} else if (expName == "ds3") {
	  datasetFile <-"amazon/rdas/2gram-entidades-erro.Rda"
	}
	
	load(datasetFile)

	trainIndex <- readRDS(file = paste0("ensembles/ensemblev2/resample/", expName, "/", "trainIndex", year, ".rds"))
	
	data_train <- as.data.frame(unclass(maFinal[ trainIndex,]))
	data_test <- maFinal[-trainIndex,]
	
	bigDataFrame <- bind_cols(list(as.numeric(as.character(svmLoko)), as.numeric(as.character(svmResults)), as.numeric(as.character(xgboost)), as.numeric(as.character(nnResults))))
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

	resultados <- addRowAdpaterBamos(resultados, matriz$byClass["F1"], matriz$byClass["Precision"], matriz$byClass["Recall"])
}

View(resultados)
mean(resultados$F1 * 100)
mean(resultados$Precision * 100)
mean(resultados$Recall * 100)
