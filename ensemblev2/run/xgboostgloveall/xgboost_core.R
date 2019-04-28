library(tools)
library(rword2vec)
library(lsa)
library(readr)
library(quanteda)

library(doMC)
Cores <- 5
registerDoMC(cores=Cores)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("utils/resultadoshelper.R"))
source(file_path_as_absolute("adhoc/quanteda/metrics.R"))

fbcorpus <- corpus(dados$textEmbedding)
fbdfm <- dfm(fbcorpus, remove=stopwords("english"), verbose=TRUE, remove_punct = TRUE)
#fbdfm <- dfm_trim(fbdfm, min_docfreq = 2, verbose=TRUE)

dados$entidades = gsub(",", " ", dados$entidades)
entidades <- corpus(dados$entidades)
entidadesdfm <- dfm(entidades, verbose=TRUE)

dados$types = gsub(",", " ", dados$types)
types <- corpus(dados$types)
typesdfm <- dfm(types, verbose=TRUE)

w2v <- readr::read_delim(embeddingFile, 
                  skip=1, delim=" ", quote="",
                  col_names=c("word", paste0("V", 1:100)))

w2v <- w2v[w2v$word %in% featnames(fbdfm),]

# creating new feature matrix for embeddings
embed <- matrix(NA, nrow=ndoc(fbdfm), ncol=100)
for (i in 1:ndoc(fbdfm)){
  if (i %% 100 == 0) message(i, '/', ndoc(fbdfm))
  vec <- as.numeric(fbdfm[i,])
  doc_words <- featnames(fbdfm)[vec>0]
  embed_vec <- w2v[w2v$word %in% doc_words, 2:101]
  embed[i,] <- colMeans(embed_vec, na.rm=TRUE)
  if (nrow(embed_vec)==0) embed[i,] <- 0
}

set.seed(10)
library(xgboost)

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Precision", "Recall")

addRowAdpater <- function(resultados, precision, recall) {
  newRes <- data.frame(precision, recall)
  rownames(newRes) <- "Exp"
  names(newRes) <- c("Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

for (year in 1:5) {
	trainFile <- readRDS(file = paste0(baseResampleFiles, "trainIndex", year, ".rds"))
	trainIndex <- as.data.frame(trainFile)$Resample1
	
	X <- as(cbind(embed, typesdfm, entidadesdfm), "dgCMatrix")
  
	# parameters to explore
	tryEta <- c(1,2,3)
	tryDepths <- c(1,2,4,6)

	# placeholders for now
	bestEta=NA
	bestDepth=NA
	bestAcc=0

	for(eta in tryEta){
		for(dp in tryDepths){ 
		  bst <- xgb.cv(data = X[trainIndex,], 
		                label =  dados$resposta[trainIndex], 
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
	rf <- xgboost(data = X[trainIndex,], 
	            label = dados$resposta[trainIndex], 
	            max.depth = bestDepth,
	            eta = bestEta, 
	            nthread = Cores,
	            nround = 500,
	            print_every_n=500L,
	            objective = "binary:logistic")

	# out-of-sample accuracy
	preds <- predict(rf, X[-trainIndex,])
  	resultados <- addRowAdpater(resultados, round(precision(preds>.50, dados$resposta[-trainIndex]) * 100,6), round(recall(preds>.50, dados$resposta[-trainIndex]) * 100,6))
}

cat(baseResultsFiles);
cat(embeddingFile)