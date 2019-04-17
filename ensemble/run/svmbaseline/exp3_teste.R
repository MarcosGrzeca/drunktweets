library(tools)

imageFile <- "ensemble/resultados/exp3/imageFileBaseline.RData"

datasetFile <-"ensemble/datasets/exp3/3gram-25-q3-not-null.Rda"

baseResultsFiles <- "ensemble/resultados/exp3/"
baseResampleFiles <- "ensemble/resample/exp3/"

fileResults <- "ensemble/resultados/exp3/"

library(caret)

treinar <- function(data_train){
  fit <- train(x = subset(data_train, select = -c(resposta)),
               y = data_train$resposta, 
               method = "svmLinear", 
               trControl = trainControl(method = "cv", number = 5, savePred=T, classProbs = TRUE))
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

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")

library(tools)
library(caret)
library(doMC)
library(mlbench)
library(magrittr)

CORES <- 5
registerDoMC(CORES)

set.seed(10)
split=0.80
# for (year in 1:10){
#   try({

load(file = datasetFile)
levels(maFinal$resposta) <- make.names(levels(factor(maFinal$resposta)))


maFinal$resposta <- as.factor(maFinal$resposta)
make.names(maFinal)
~ .,

View(maFinal)


# trainIndex <- readRDS(file = paste0(baseResampleFiles, "trainIndex", year, ".rds"))
# data_train <- as.data.frame(unclass(maFinal[ trainIndex,]))
# data_test <- maFinal[-trainIndex,]

trainIndex <- createDataPartition(maFinal$resposta, p=split, list=FALSE)
data_train <- as.data.frame(unclass(maFinal[ trainIndex,]))
data_test <- maFinal[-trainIndex,]

treegram25NotNull <- treinar(data_train)
treegram25NotNull
# pred <- predict(treegram25NotNull, subset(data_test, select = -c(resposta)))
predict(treegram25NotNull, subset(data_test, select = -c(resposta)), type = "prob")

library(dplyr)
predict(treegram25NotNull, subset(data_test, select = -c(resposta)), type = "prob") %>% 
  mutate('class'=names(.)[apply(., 1, which.max)])

predict(treegram25NotNull, subset(data_test, select = -c(resposta)))

# 	matriz3Gram25NotNull <- confusionMatrix(data = pred, data_test$resposta, positive="1")
# resultados <- addRow(resultados, "2 GRAM - Entidades - Erro", matriz3Gram25NotNull)
#   })
# }

TN <- matriz3Gram25NotNull$table[1]
FP <- matriz3Gram25NotNull$table[2]
FN <- matriz3Gram25NotNull$table[3]
TP <- matriz3Gram25NotNull$table[4]

print(paste0("Precision rCaret: ", matriz3Gram25NotNull$byClass["Precision"]))
print(paste0("Precision: ", TP / (TP + FP)))
print(paste0("Recall rCaret: ", matriz3Gram25NotNull$byClass["Recall"]))
print(paste0("Recall: ", TP / (TP + FN)))

resultados