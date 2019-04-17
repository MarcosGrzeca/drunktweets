library(tools)

try({
	datasetFile <-"ensemble/datasets/exp2/2-Gram-dbpedia-types-enriquecimento-info-q2-not-null_info_entidades.Rda"
	baseResultsFiles <- "ensemblev2/resultados/exp2/"
	baseResampleFiles <- "ensemblev2/resample/exp2/"
	library(caret)

	treinarPoly <- function(data_train){
		fit <- train(x = subset(data_train, select = -c(resposta)),
				y = data_train$resposta, 
				method = "svmPoly", 
				trControl = trainControl(method = "cv", number = 5, savePred=T, classProbs = TRUE))
		return (fit)
	}

	library(tools)
	library(caret)
	library(doMC)
	library(mlbench)
	library(magrittr)

	CORES <- 5
	registerDoMC(CORES)

	set.seed(10)
	split=0.80
	
	load(file = datasetFile)
	levels(maFinal$resposta) <- make.names(levels(factor(maFinal$resposta)))
	trainIndex <- readRDS(file = paste0(baseResampleFiles, "trainIndex", year, ".rds"))
	data_train <- as.data.frame(unclass(maFinal[ trainIndex,]))
	data_test <- maFinal[-trainIndex,]
	treegram25NotNull <- treinarPoly(data_train)

	pred <- predict(treegram25NotNull, subset(data_test, select = -c(resposta)), type = "prob") %>% 
  			mutate('class'=names(.)[apply(., 1, which.max)])

	saveRDS(pred$X1, file = paste0(baseResultsFiles, "svm", year, ".rds"))
	#source(file_path_as_absolute("ensemblev2/git.R"))
})
