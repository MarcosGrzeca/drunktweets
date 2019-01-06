	library(tools)
	library(caret)
	library(doMC)
	library(mlbench)
	library(magrittr)
	library(caret)

	CORES <- 5 #Optional
	registerDoMC(CORES) #Optional

	load("chat/rdas/2gram-entidades-erro.Rda")

	set.seed(10)
	split=0.60

	maFinal$resposta <- as.factor(maFinal$resposta)
	trainIndex <- createDataPartition(maFinal$resposta, p=split, list=FALSE)
	data_train <- as.data.frame(unclass(maFinal[ trainIndex,]))
	data_test <- maFinal[-trainIndex,]

	treegram25NotNull <- train(
			x = subset(data_train, select = -c(resposta)),
	     	y = data_train$resposta, 
	     	method = "nb",
	     	linout = 1,
	     	trControl = trainControl(method = "cv", number = 5, savePred=T, sampling = "up"))
	treegram25NotNull