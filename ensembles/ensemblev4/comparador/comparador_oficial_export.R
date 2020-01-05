library(caret)
library(dplyr)

expName <- "exp1"

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("F1", "Precision", "Recall")

addRowAdpaterBamos <- function(resultados, f1, precision, recall) {
  newRes <- data.frame(f1, precision, recall)
  rownames(newRes) <- "Exp"
  names(newRes) <- c("F1", "Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

for (year in 1:1) {
	svmResults <- readRDS(file = paste0("ensembles/ensemblev3/resultados/", expName, "/svm", year, ".rds"))
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
	
	bigDataFrame <- bind_cols(list(as.numeric(as.character(svmLoko)), as.numeric(as.character(svmResults)), as.numeric(as.character(nnResults))))
	pred <- round(rowMeans(bigDataFrame),0)
	finalDataFrame <- bind_cols(list(data_test$idInterno), list(as.factor(data_test$resposta)), list(as.factor(pred)), list(as.factor(round(svmLoko, 0))), list(as.factor(round(svmResults, 0))), list(as.factor(round(nnResults, 0))))
	View(finalDataFrame)
}

f <- function(x, outputFile) {
  if (x[2] != x[3] && x[2] != x[4] && x[2] != x[5] && x[2] != x[6]) {
    print(paste(x[1], sep=","))
    cat(x[1], file=outputFile)
  }
}

apply(finalDataFrame, 1, f, "falhas/exp1.txt")
