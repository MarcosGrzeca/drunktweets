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

#Configuracoes
DATABASE <- "icwsm"
dados <- getDadosChat()

fbcorpus <- corpus(dados$textParser)
fbdfm <- dfm(fbcorpus, remove=stopwords("english"), verbose=TRUE, remove_punct = TRUE)
fbdfm <- dfm_trim(fbdfm, min_docfreq = 2, verbose=TRUE)

dados$entidades = gsub(",", " ", dados$entidades)
entidades <- corpus(dados$entidades)
entidadesdfm <- dfm(entidades, verbose=TRUE)

dados$types = gsub(",", " ", dados$types)
types <- corpus(dados$types)
typesdfm <- dfm(types, verbose=TRUE)

#dfm(x, verbose = TRUE, toLower = TRUE,
#    removeNumbers = TRUE, removePunct = TRUE, removeSeparators = TRUE,
#    removeTwitter = FALSE, stem = FALSE, ignoredFeatures = NULL,
#    keptFeatures = NULL, language = "english", thesaurus = NULL,
#    dictionary = NULL, valuetype = c("glob", "regex", "fixed"), ..

set.seed(10)
library(xgboost)

#Com enriquecimento

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Name", "Precision", "Recall")

addRowSimple <- function(resultados, rowName, precision, recall) {
  newRes <- data.frame(rowName, precision, recall)
  rownames(newRes) <- rowName
  names(newRes) <- c("Name", "Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

for (iteracao in 1:10) {
  training <- sample(1:nrow(dados), floor(.80 * nrow(dados)))
  test <- (1:nrow(dados))[1:nrow(dados) %in% training == FALSE]
  
  # converting matrix object
  X <- as(fbdfm, "dgCMatrix")
  
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
                    label =  dados$resposta[training], 
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
  rf <- xgboost(data = X[training,], 
                label = dados$resposta[training], 
                max.depth = bestDepth,
                eta = bestEta, 
                nthread = Cores,
                nround = 500,
                print_every_n=500L,
                objective = "binary:logistic")
  
  # out-of-sample accuracy
  preds <- predict(rf, X[test,])
  resultados <- addRowSimple(resultados, "Sem", round(precision(preds>.50, dados$resposta[test]) * 100,6), round(recall(preds>.50, dados$resposta[test]) * 100,6))
  
  X <- as(cbind(fbdfm, typesdfm, entidadesdfm), "dgCMatrix")
  
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
                    label =  dados$resposta[training], 
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
  rf <- xgboost(data = X[training,], 
                label = dados$resposta[training], 
                max.depth = bestDepth,
                eta = bestEta, 
                nthread = Cores,
                nround = 500,
                print_every_n=500L,
                objective = "binary:logistic")
  
  # out-of-sample accuracy
  preds <- predict(rf, X[test,])
  resultados <- addRowSimple(resultados, "Com", round(precision(preds>.50, dados$resposta[test]) * 100,6), round(recall(preds>.50, dados$resposta[test]) * 100,6))
  
  teste <- cbind(dados$numeroErros, dados$turno, dados$emoticonPos, dados$emoticonNeg)
  X <- as(cbind(fbdfm, typesdfm, entidadesdfm, as.matrix(teste)), "dgCMatrix")
  
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
                    label =  dados$resposta[training], 
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
  rf <- xgboost(data = X[training,], 
                label = dados$resposta[training], 
                max.depth = bestDepth,
                eta = bestEta, 
                nthread = Cores,
                nround = 500,
                print_every_n=500L,
                objective = "binary:logistic")
  
  # out-of-sample accuracy
  preds <- predict(rf, X[test,])
  resultados <- addRowSimple(resultados, "Inteiro", round(precision(preds>.50, dados$resposta[test]) * 100,6), round(recall(preds>.50, dados$resposta[test]) * 100,6))

  cat("Iteracao = ",iteracao, "\n",sep="")
  View(resultados)
}

resultados