library(tools)
library(rword2vec)
library(lsa)
library(readr)
library(quanteda)

library(doMC)

if (!require("kernlab")) {
  install.packages("kernlab")
}

if (!require("e1071")) {
  install.packages("e1071")
}

Cores <- 8
registerDoMC(cores=Cores)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("utils/resultadoshelper.R"))
source(file_path_as_absolute("adhoc/quanteda/metrics.R"))
source(file_path_as_absolute("adhoc/quanteda/svm/classifier/requires.R"))

#Configuracoes
DATABASE <- "icwsm"
dados <- getDadosBaselineByQ("q3")
dados$resposta <- as.factor(dados$resposta)

fbcorpus <- corpus(dados$textEmbedding)
fbdfm <- dfm(fbcorpus, remove=stopwords("english"), verbose=TRUE, remove_punct = TRUE)
fbdfm <- dfm_trim(fbdfm, min_docfreq = 2, verbose=TRUE)

dados$entidades = gsub(",", " ", dados$entidades)
entidades <- corpus(dados$entidades)
entidadesdfm <- dfm(entidades, verbose=TRUE)

dados$types = gsub(",", " ", dados$types)
types <- corpus(dados$types)
typesdfm <- dfm(types, verbose=TRUE)

dados$hashtags = gsub(",", " ", dados$hashtags)
hashtags <- corpus(dados$hashtags)
hashtagsdfm <- dfm(hashtags, verbose=TRUE)
hashtagsdfm <- dfm_trim(hashtagsdfm, min_docfreq = 2, verbose=TRUE)

#dfm(x, verbose = TRUE, toLower = TRUE,
#    removeNumbers = TRUE, removePunct = TRUE, removeSeparators = TRUE,
#    removeTwitter = FALSE, stem = FALSE, ignoredFeatures = NULL,
#    keptFeatures = NULL, language = "english", thesaurus = NULL,
#    dictionary = NULL, valuetype = c("glob", "regex", "fixed"), ..

w2v <- readr::read_delim("adhoc/exportembedding/ds1/q3/cnn_10_epocas_8_filters164.txt", 
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
library(xgboost)

#Com enriquecimento

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Name", "Precision", "Recall")

for (iteracao in 1:10) {
  training <- sample(1:nrow(dados), floor(.80 * nrow(dados)))
  test <- (1:nrow(dados))[1:nrow(dados) %in% training == FALSE]
  
  textoDF <- as.data.frame(embed)
  hashtagsDF <- as.data.frame(hashtagsdfm)
  hashtagsDF <- subset(hashtagsDF, select = -c(document))
  
  entidadesDF <- as.data.frame(entidadesdfm)
  entidadesDF <- subset(entidadesDF, select = -c(document))
  
  typesDF <- as.data.frame(typesdfm)
  typesDF <- subset(typesDF, select = -c(document))
  
  adidionalFeatures <- cbind(dados$numeroErros, dados$turno, dados$emoticonPos, dados$emoticonNeg)

  #marcos <- textoDF
  
  #Sem enriquecimento
  marcos <- cbind(textoDF, hashtagsDF)    
  fit <- treinar(marcos[training,], dados$resposta[training])
  fit
  
  matriz3Gram25NotNullBaseline <- getMatriz(fit, marcos[test,], dados$resposta[test])
  resultados <- addRow(resultados, "LinearSEM", matriz3Gram25NotNullBaseline)

  #Com enriquecimento
  marcos <- cbind(textoDF, hashtagsDF, entidadesDF, typesDF, adidionalFeatures)

  fit <- treinar(marcos[training,], dados$resposta[training])
  fit
  
  matriz3Gram25NotNullBaseline <- getMatriz(fit, marcos[test,], dados$resposta[test])
  resultados <- addRow(resultados, "LinearCom", matriz3Gram25NotNullBaseline)

  cat(iteracao, "\n")
  View(resultados)
}

resultados