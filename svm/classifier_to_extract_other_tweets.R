resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")

library(tools)
library(caret)
library(doMC)
library(mlbench)
library(magrittr)

CORES <- 2
registerDoMC(CORES)

treinar <- function(data_train){
    # registerDoMC(CORES)
    fit <- train(x = subset(data_train, select = -c(resposta)),
            y = data_train$resposta, 
            method = "svmLinear", 
            trControl = trainControl(method = "cv", number = 5, savePred=T))
    return (fit)
}

treinarPoly <- function(data_train){
    fit <- train(x = subset(data_train, select = -c(resposta)),
            y = data_train$resposta, 
            method = "svmPoly", 
            trControl = trainControl(method = "cv", number = 5, savePred=T))
    return (fit)
}

getMatriz <- function(fit, data_test) {
  pred <- predict(fit, subset(data_test, select = -c(resposta)))
  matriz <- confusionMatrix(data = pred, data_test$resposta, positive="1")
  return (matriz)
}

addRow <- function(resultados, baseline, matriz, ...) {
  print(baseline)
  newRes <- data.frame(baseline, matriz$byClass["F1"], matriz$byClass["Precision"], matriz$byClass["Recall"])
  rownames(newRes) <- baseline
  names(newRes) <- c("Baseline", "F1", "Precisão", "Revocação")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

set.seed(10)
split=0.80

load(file = "rdas/2gram-entidades-hora-erro-q2-teste-outro-classificador.Rda")
maFinal$resposta <- as.factor(maFinal$resposta)
str(maFinal$testador)

newdata <- maFinal[ which(maFinal$testador=='0'), ]
nrow(newdata)

  maFinal[ trainIndex,]

#   newdata <- mydata[ which(mydata$gender=='F' 
# & mydata$age > 65), ]
	
 #  trainIndex <- createDataPartition(maFinal$resposta, p=split, list=FALSE)
	# data_train <- as.data.frame(unclass(maFinal[ trainIndex,]))
	# data_test <- maFinal[-trainIndex,]

	# gramEntidadesSemTexto <- treinar(data_train)
	# gramEntidadesSemTexto
	# matrizGramSemTexto <- getMatriz(gramEntidadesSemTexto, data_test)
	# resultados <- addRow(resultados, "2 GRAM - Entidades - Erro - Sem texto", matrizGramSemTexto)
# })