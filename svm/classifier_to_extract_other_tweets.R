resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")

library(tools)
library(caret)
library(doMC)
library(mlbench)
library(magrittr)

CORES <- 5
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
data_train <- as.data.frame(unclass(maFinal[ which(maFinal$testador=='0'),]))
data_train <- subset(data_train, select = -c(id, testador))

data_test  <- as.data.frame(unclass(maFinal[ which(maFinal$testador=='1'),]))

gramEntidadesSemTexto <- treinar(data_train)
gramEntidadesSemTexto

pred <- predict(gramEntidadesSemTexto, subset(data_test, select = -c(id, testador, resposta)))

library(rowr)
library(RWeka)
all_data <- cbind.fill(subset(data_test, select = c(id)), pred)

pos  <- as.data.frame(unclass(all_data[ which(all_data$object=='1'),]))
save(pos, file = "pos2.Rda")