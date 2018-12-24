library(tools)
library(caret)
library(mlbench)

importance <- varImp(treegram25NotNull, scale=FALSE)
# summarize importance
marcos <- print(importance, top = 50)