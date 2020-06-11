library(caret)
library(dplyr)

library(doMC)
library(mlbench)
library(magrittr)

CORES <- 10
registerDoMC(CORES)

expName <- "ds3"

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("F1", "Precision", "Recall")

addRowAdpaterBamos <- function(resultados, f1, precision, recall) {
  newRes <- data.frame(f1, precision, recall)
  rownames(newRes) <- "Exp"
  names(newRes) <- c("F1", "Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

treinarPoly <- function(data_train, resposta) {
    fit <- train(
            x = data_train,
            y = resposta, 
            method = "svmPoly", 
            trControl = trainControl(method = "cv", number = 5))
    return (fit)
}

set.seed(10)

for (year in 1:5) {
	svmResults <- readRDS(file = paste0("ensembles/ensemblev3/resultados/", expName, "/svm", year, ".rds"))
	svmLoko <- readRDS(file = paste0("ensembles/ensemblev4/resultados/", expName, "/svmpoly", year, ".rds"))
	nnResults <- readRDS(file = paste0("ensembles/ensemblev3/resultados/", expName, "/newdl/neuralprob", year, ".rds"))
	
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
	
	dados <- bind_cols(list(as.numeric(as.character(svmResults)), as.numeric(as.character(svmLoko)), as.numeric(as.character(nnResults))))
	resposta <- maFinal[-trainIndex,]$resposta
	
	resposta <- as.factor(resposta)
	levels(resposta) <- make.names(levels(resposta))


	trainIndexNew <- createDataPartition(resposta, p=0.9, list=FALSE)
	dados_train <- dados[ trainIndexNew,]
	dados_test <- dados[-trainIndexNew,]
	
	classifier <- treinarPoly(dados_train, as.factor(resposta[trainIndexNew]))
	
	# out-of-sample accuracy
	pred <- predict(classifier, dados_test)


	# bigDataFrame <- as.numeric(as.character(svmResults))
	matriz <- confusionMatrix(pred, resposta[-trainIndexNew], positive="X1")
	print(matriz$byClass["F1"])
	print(matriz$byClass["Precision"])
	print(matriz$byClass["Recall"])
	resultados <- addRowAdpaterBamos(resultados, matriz$byClass["F1"], matriz$byClass["Precision"], matriz$byClass["Recall"])
}

View(resultados)
mean(resultados$F1 * 100)
mean(resultados$Precision * 100)
mean(resultados$Recall * 100)
