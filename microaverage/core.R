library(caret)
library(dplyr)

precision_globalTP <- 0
precision_subPrecision <- 0

recall_global <- 0
recall_globalDivider <- 0

for (year in 1:10) {
  results <- readRDS(file = paste0("ensemble/resultados/", expName, "/", fileExpName, year, ".rds"))
  load(datasetFile)
  trainIndex <- readRDS(file = paste0("ensemble/resample/", expName, "/", "trainIndex", year, ".rds"))
  data_train <- as.data.frame(unclass(maFinal[ trainIndex,]))
  data_test <- maFinal[-trainIndex,]
  matriz <- confusionMatrix(data = as.factor(results), as.factor(data_test$resposta), positive="1")
  
  TN <- matriz$table[1]
  FP <- matriz$table[2]
  FN <- matriz$table[3]
  TP <- matriz$table[4]
  
  # if (year == 1) {
  #   TP <- 12
  #   FP <- 9
  #   FN <- 3
  # } else {
  #   TP <- 50
  #   FP <- 23
  #   FN <- 9
  # }
  precision_globalTP <- precision_globalTP + TP
  precision_subPrecision <- precision_subPrecision + (TP + FP)
  
  recall_global <- recall_global + TP
  recall_globalDivider <- recall_globalDivider + (TP + FN)
}

print(paste0("Micro precision: ", precision_globalTP / precision_subPrecision * 100))
print(paste0("Micro recall: ", recall_global / recall_globalDivider * 100))