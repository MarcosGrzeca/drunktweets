library(tools)
library(caret)
library(mlbench)

load("ensemble/resultados/exp6/imageFile.RData")

importance <- varImp(treegram25NotNull, scale=FALSE)
# summarize importance
marcos <- print(importance, top = 50)