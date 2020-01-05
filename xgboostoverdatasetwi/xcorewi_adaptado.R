library(caret)
source(file_path_as_absolute("utils/functions.R"))

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Name", "Precision", "Recall")

addRowSimple <- function(resultados, rowName, precision, recall) {
  newRes <- data.frame(rowName, precision, recall)
  rownames(newRes) <- rowName
  names(newRes) <- c("Name", "Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

set.seed(10)
library(xgboost)

# for (iteracao in 1:10) {
for (iteracao in 1:1) {
  load(file = datasetFile)
  maFinal$resposta <- as.factor(maFinal$resposta)
  
  #training <- sample(1:nrow(maFinal), floor(.80 * nrow(maFinal)))
  #test <- (1:nrow(maFinal))[1:nrow(maFinal) %in% training == FALSE]
  
  #maFinalWithoutResponse <- subset(maFinal, select = -c(resposta))
  #matSparse <- as(as.matrix(maFinalWithoutResponse), "sparseMatrix")
  #X <- as(matSparse, "dgCMatrix")
  
  maFinal[,"idInterno":=NULL]
  
  trainIndex <- createDataPartition(maFinal$resposta, p=0.8, list=FALSE)
  dados_train <- maFinal[ trainIndex,]
  dados_test <- maFinal[-trainIndex,]
  
  sparse_matrix_train <- sparse.model.matrix(resposta ~ ., data = dados_train)[,-1]
  sparse_matrix_test <- sparse.model.matrix(resposta ~ ., data = dados_test)[,-1]
  
  # parameters to explore
  tryEta <- c(1,2,3)
  tryDepths <- c(1,2,4,6)

  #A
  tryEta <- c(1,2,3)
  tryDepths <- c(1,2,4,6)
  
  # placeholders for now
  bestEta=NA
  bestDepth=NA
  bestAcc=0
  
  for(eta in tryEta){
    for(dp in tryDepths){ 
      bst <- xgb.cv(data = sparse_matrix_train, 
                    label =  array(maFinal$resposta[trainIndex]), 
                    max.depth = dp,
                    eta = eta, 
                    nthread = 8,
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
  rf <- xgboost(data = sparse_matrix_train, 
                label = array(maFinal$resposta[trainIndex]), 
                max.depth = bestDepth,
                eta = bestEta, 
                nthread = Cores,
                nround = 500,
                print_every_n=500L,
                objective = "binary:logistic")
  
  predict(rf, sparse_matrix_test)
  maFinal$resposta[-trainIndex]
  
  marcos <- cbind(predict(rf, sparse_matrix_test), preds, maFinal$resposta[-trainIndex])
  View(marcos)
  
  # out-of-sample accuracy
  preds <- as.factor(round(predict(rf, sparse_matrix_test)))
  preds
  
  
  matriz <- confusionMatrix(data = preds, maFinal$resposta[-trainIndex], positive="1")
  matriz
  cat(matriz$byClass["F1"], matriz$byClass["Precision"], matriz$byClass["Recall"])
  
  maFinal$resposta[-trainIndex]
  
  preds
  as.factor(maFinal$resposta[-trainIndex])
  
  resultados <- addRowSimple(resultados, "Sem", round(precision(preds, as.factor(maFinal$resposta[-trainIndex])) * 100,6), round(recall(preds, maFinal$resposta[-trainIndex]) * 100,6))
  
  cat("Iteracao = ",iteracao, "\n",sep="")
  View(resultados)
}
