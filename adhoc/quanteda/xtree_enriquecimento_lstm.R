library(tools)
library(rword2vec)
library(lsa)
library(readr)
library(quanteda)

library(doMC)
registerDoMC(cores=4)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("utils/resultadoshelper.R"))
source(file_path_as_absolute("utils/getDadosAmazon.R"))
source(file_path_as_absolute("adhoc/quanteda/metrics.R"))

#Configuracoes
DATABASE <- "icwsm"
dados <- getDadosAmazon()

fbcorpus <- corpus(dados$textEmbedding)
#fbdfm <- dfm(fbcorpus, remove=stopwords("english"), verbose=TRUE, stem = TRUE, remove_punct = TRUE)
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

w2v <- readr::read_delim("adhoc/exportembedding/lstm_epocas.txt", 
                  skip=1, delim=" ", quote="",
                  col_names=c("word", paste0("V", 1:100)))

w2v <- w2v[w2v$word %in% featnames(fbdfm),]

# creating new feature matrix for embeddings
embed <- matrix(NA, nrow=ndoc(fbdfm), ncol=100)
for (i in 1:ndoc(fbdfm)){
  if (i %% 100 == 0) message(i, '/', ndoc(fbdfm))
  # extract word counts
  vec <- as.numeric(fbdfm[i,])
  # keep words with counts of 1 or more
  doc_words <- featnames(fbdfm)[vec>0]
  # extract embeddings for those words
  embed_vec <- w2v[w2v$word %in% doc_words, 2:101]
  # aggregate from word- to document-level embeddings by taking AVG
  embed[i,] <- colMeans(embed_vec, na.rm=TRUE)
  # if no words in embeddings, simply set to 0
  if (nrow(embed_vec)==0) embed[i,] <- 0
}

set.seed(10)
training <- sample(1:nrow(dados), floor(.80 * nrow(dados)))
test <- (1:nrow(dados))[1:nrow(dados) %in% training == FALSE]

library(xgboost)

for (iteracao in 1:3) {
  # converting matrix object
  X <- as(cbind(fbdfm, embed,typesdfm,entidadesdfm), "dgCMatrix")
  
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
                    nthread = 4,
                    nround = 500,
                    nfold=5,
                    print_every_n = 500L,
                    objective = "binary:logistic")
      # cross-validated accuracy
      acc <- 1-mean(tail(bst$evaluation_log$test_error_mean))
      cat("Results for eta=",eta," and depth=", dp, " : ",
          acc," accuracy.\n",sep="")
      if(acc>bestAcc){
        bestEta=eta
        bestAcc=acc
        bestDepth=dp
      }
    }
  }
  
  cat("Best model has eta=",bestEta," and depth=", bestDepth, " : ", bestAcc," accuracy.\n",sep="")
  
  # running best model
  rf <- xgboost(data = X[training,], 
                label = dados$resposta[training], 
                max.depth = bestDepth,
                eta = bestEta, 
                nthread = 4,
                nround = 500,
                print_every_n=500L,
                objective = "binary:logistic")
  
  # out-of-sample accuracy
  preds <- predict(rf, X[test,])
  
  cat("\nAccuracy on test set=", round(accuracy(preds>.50, dados$resposta[test]) * 100,6))
  cat("\nPrecision(1) on test set=", round(precision(preds>.50, dados$resposta[test]) * 100,6))
  cat("\nRecall(1) on test set=", round(recall(preds>.50, dados$resposta[test]) * 100,6))
  
  #cat("\nPrecision(0) on test set=", round(precision(preds<.50, fb$attacks[test]==0),3))
  #cat("\nRecall(0) on test set=", round(recall(preds<.50, fb$attacks[test]==0),3))
}
