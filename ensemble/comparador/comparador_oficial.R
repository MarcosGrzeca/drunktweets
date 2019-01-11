library(caret)
library(dplyr)

#install.packages("caret")

for (year in 1:5) {
  year <- 1
	svmResults <- readRDS(file = paste0("ensemble/resultados/exp4/svm", year, ".rds"))
	# rfResults <- readRDS(file = paste0("ensemble/resultados/exp4/rf", year, ".rds"))
	rfResults <- readRDS(file = paste0("ensemble/resultados/exp4/nb", year, ".rds"))
	nnResults <- readRDS(file = paste0("ensemble/resultados/exp4/neural", year, ".rds"))
	
	# load("ensemble/datasets/exp1/2-Gram-dbpedia-types-enriquecimento-info-q1-not-null_info_entidades.Rda")
	#load("ensemble/datasets/exp2/2-Gram-dbpedia-types-enriquecimento-info-q2-not-null_info_entidades.Rda")
	#load("ensemble/datasets/exp3/2-Gram-dbpedia-types-enriquecimento-info-q3-not-null_info_entidades.Rda")
	load("rdas/2gram-entidades-hora-erro-semkeywords.Rda")
	# load("chat/rdas/2gram-entidades-erro-sem-key-words.Rda")
	
	trainIndex <- readRDS(file = paste0("ensemble/resample/exp4/", "trainIndex", year, ".rds"))
	data_train <- as.data.frame(unclass(maFinal[ trainIndex,]))
	data_test <- maFinal[-trainIndex,]
	
	rm(maFinal)
	

	bigDataFrame <- bind_cols(list(as.numeric(as.character(svmResults)), as.numeric(as.character(nnResults)), as.numeric(as.character(rfResults))))
	
	bigDataFrameSum <- rowSums(bigDataFrame)
	
	result <- bigDataFrameSum / 3
	pred <- round(result,0)
	
	
	matriz <- confusionMatrix(data = as.factor(pred), as.factor(data_test$resposta), positive="1")
	print(matriz$byClass["F1"])
	print(matriz$byClass["Precision"])
	print(matriz$byClass["Recall"])
}
