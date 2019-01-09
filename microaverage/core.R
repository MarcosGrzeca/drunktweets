library(caret)
library(dplyr)

precision_globalTP <- 0
precision_subPrecision <- 0

recall_global <- 0
recall_globalDivider <- 0

precision <- 1 #VERIFICAR

if (ambas == 1) {
  classePositiva <- "0"
}

precisions <- c()
recalls <- c()

for (year in 1:10) {
  results <- readRDS(file = paste0("ensemble/resultados/", expName, "/", fileExpName, year, ".rds"))
  load(datasetFile)
  trainIndex <- readRDS(file = paste0("ensemble/resample/", expName, "/", "trainIndex", year, ".rds"))
  data_train <- as.data.frame(unclass(maFinal[ trainIndex,]))
  data_test <- maFinal[-trainIndex,]
  matriz <- confusionMatrix(data = as.factor(results), as.factor(data_test$resposta), positive=classePositiva)
  

  # print(paste0("F1: ", matriz$byClass["F1"]))
  # print(paste0("Precision: ", matriz$byClass["Precision"]))
  #print(paste0("Recall: ", matriz$byClass["Recall"]))
  
  precisions <- c(precisions, matriz$byClass["Precision"])
  recalls <- c(recalls, matriz$byClass["Recall"])

  if (classePositiva == "0") {
    TN <- matriz$table[4]
    FP <- matriz$table[3]
    FN <- matriz$table[2]
    TP <- matriz$table[1]
  }  else {
    TN <- matriz$table[1]
    FP <- matriz$table[2]
    FN <- matriz$table[3]
    TP <- matriz$table[4]
  }
  precision_globalTP <- precision_globalTP + TP
  precision_subPrecision <- precision_subPrecision + (TP + FP)
  
  recall_global <- recall_global + TP
  recall_globalDivider <- recall_globalDivider + (TP + FN)
}

if (ambas == 1) {
  classePositiva = "1"

  for (year in 1:10) {
    results <- readRDS(file = paste0("ensemble/resultados/", expName, "/", fileExpName, year, ".rds"))
    load(datasetFile)
    trainIndex <- readRDS(file = paste0("ensemble/resample/", expName, "/", "trainIndex", year, ".rds"))
    data_train <- as.data.frame(unclass(maFinal[ trainIndex,]))
    data_test <- maFinal[-trainIndex,]
    matriz <- confusionMatrix(data = as.factor(results), as.factor(data_test$resposta), positive=classePositiva)
    

    # print(paste0("F1: ", matriz$byClass["F1"]))
    # print(paste0("Precision: ", matriz$byClass["Precision"]))
    #print(paste0("Recall: ", matriz$byClass["Recall"]))
    
    precisions <- c(precisions, matriz$byClass["Precision"])
    recalls <- c(recalls, matriz$byClass["Recall"])
    
    if (classePositiva == "0") {
      TN <- matriz$table[4]
      FP <- matriz$table[3]
      FN <- matriz$table[2]
      TP <- matriz$table[1]
    }  else {
      TN <- matriz$table[1]
      FP <- matriz$table[2]
      FN <- matriz$table[3]
      TP <- matriz$table[4]
    }

    precision_globalTP <- precision_globalTP + TP
    precision_subPrecision <- precision_subPrecision + (TP + FP)
    
    recall_global <- recall_global + TP
    recall_globalDivider <- recall_globalDivider + (TP + FN)
  }
}

if (ambas == 1) {
  print("Micro")
  cat(precision_globalTP / precision_subPrecision * 100, "\t", recall_global / recall_globalDivider * 100, "\n")
}

print("Macro")
cat(mean(precisions) * 100, "\t", mean(recalls) * 100, "\n")

#print(paste0("Macro precision: ", mean(precisions) * 100))
#print(paste0("Macro recall: ", mean(recalls) * 100))


# print(paste0("Micro precision: ", precision_globalTP / precision_subPrecision * 100))
# print(paste0("Micro recall: ", recall_global / recall_globalDivider * 100))
