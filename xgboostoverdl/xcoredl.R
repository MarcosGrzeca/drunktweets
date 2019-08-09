library(tools)
library(rword2vec)
library(lsa)
library(readr)
library(quanteda)

library(doMC)
Cores <- 8
registerDoMC(cores=Cores)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("utils/resultadoshelper.R"))
source(file_path_as_absolute("adhoc/quanteda/metrics.R"))

set.seed(10)
library(xgboost)

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Name", "Precision", "Recall")

addRowSimple <- function(resultados, rowName, precision, recall) {
  newRes <- data.frame(rowName, precision, recall)
  rownames(newRes) <- rowName
  names(newRes) <- c("Name", "Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

for (year in 1:10) {
  load(embeddingsFile)
  inTrain <- readRDS(file = paste0(baseResampleFiles, "trainIndex", year, ".rds"))

  tam <- ncol(X) - 1
  one_hot_train <- X[inTrain, 1:tam]
  resposta <-  X[inTrain, ncol(X)]
  
  one_hot_test <- X[-inTrain, 1:tam]
  resposta_test <-  X[-inTrain, ncol(X)]
  
  # parameters to explore
  tryEta <- c(1,2,3)
  tryDepths <- c(1,2,4,6)

  # placeholders for now
  bestEta=NA
  bestDepth=NA
  bestAcc=0

  for(eta in tryEta){
    for(dp in tryDepths){ 
      bst <- xgb.cv(data = one_hot_train, 
                    label =  resposta, 
                    max.depth = dp,
                    eta = eta, 
                    nthread = Cores,
                    nround = 500,
                    nfold=5,
                    print_every_n = 500L,
                    objective = "binary:logistic")
      # cross-validated accuracy
      acc <- 1-mean(tail(bst$evaluation_log$test_error_mean))
      if(acc>bestAcc){
        bestEta=eta
        bestAcc=acc
        bestDepth=dp
     }
    }
  }

  # running best model
  rf <- xgboost(data = one_hot_train, 
              label = resposta, 
              max.depth = bestDepth,
              eta = bestEta, 
              nthread = Cores,
              nround = 500,
              print_every_n=500L,
              objective = "binary:logistic")

  # out-of-sample accuracy
  preds <- predict(rf, one_hot_test)
  resultados <- addRowSimple(resultados, "Com", round(precision(preds>.50, resposta_test) * 100,6), round(recall(preds>.50, resposta_test) * 100,6))
  cat("Iteracao = ",iteracao, "\n",sep="")
  View(resultados)
}