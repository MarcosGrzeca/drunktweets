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
  training <- sample(1:nrow(maFinal), floor(.80 * nrow(maFinal)))
  test <- (1:nrow(maFinal))[1:nrow(maFinal) %in% training == FALSE]
  maFinalWithoutResponse <- subset(maFinal, select = -c(resposta))

  # converting matrix object
  # X <- as(cbind(embed,typesdfm,entidadesdfm), "dgCMatrix")
 
  # X <- as(matSparse, "dgCMatrix")
  
  # training
  
  # options("experssion" = 9500000)
  # require(xgboost)
  # require(Matrix)
  # require(data.table)
  # sparse_matrix <- sparse.model.matrix(resposta ~ ., data = maFinal)[,-1]
  
  # sparse_matrix <- sparse.model.matrix(resposta ~ .-1, data = maFinal)
  
  # sparse_matrix
  
  
  
  
  # matSparse
  
  
  
  # X <- xgb.DMatrix(label = resposta, data= as.matrix(maFinal))
  
  # marcos <- as.matrix(maFinal)
  # View(marcos)
  
  # X <- xgb.DMatrix(label = resposta, marcos)
  
  # marcos$resposta
  
  
  matSparse <- as(as.matrix(maFinalWithoutResponse), "sparseMatrix")
  X <- as(matSparse, "dgCMatrix")
  
  # parameters to explore
  tryEta <- c(1,2,3)
  tryDepths <- c(1,2,4,6)
  # placeholders for now
  bestEta=NA
  bestDepth=NA
  bestAcc=0
  
  for(eta in tryEta){
    for(dp in tryDepths){ 
      bst <- xgb.cv(data = X[training,], 
                    label =  array(maFinal$resposta[training]), 
                    max.depth = dp,
                    eta = eta, 
                    nthread = 16,
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
  rf <- xgboost(data = X[training,], 
                label = array(maFinal$resposta[training]), 
                max.depth = bestDepth,
                eta = bestEta, 
                nthread = Cores,
                nround = 500,
                print_every_n=500L,
                objective = "binary:logistic")
  
  # out-of-sample accuracy
  preds <- as.factor(round(predict(rf, X[test,])))
  resultados <- addRowSimple(resultados, "Sem", round(precision(preds>.50, maFinal$resposta[test]) * 100,6), round(recall(preds>.50, maFinal$resposta[test]) * 100,6))
  
  cat("Iteracao = ",iteracao, "\n",sep="")
  View(resultados)
}
