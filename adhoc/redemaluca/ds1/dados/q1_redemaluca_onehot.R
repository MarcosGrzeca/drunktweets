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
dados <- getDadosBaselineByQ("q1")

fbcorpus <- corpus(dados$textEmbedding)
fbdfm <- dfm(fbcorpus, remove=stopwords("english"), verbose=TRUE, remove_punct = TRUE)
#fbdfm <- dfm_trim(fbdfm, min_docfreq = 2, verbose=TRUE)

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

w2v <- readr::read_delim("adhoc/exportembedding/ds1/q1/cnn_10_epocas_8_filters164.txt", 
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

addRowSimple <- function(resultados, rowName, precision, recall) {
  newRes <- data.frame(rowName, precision, recall)
  rownames(newRes) <- rowName
  names(newRes) <- c("Name", "Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

entidadesDF <- as.data.frame(entidadesdfm)
entidadesDF <- subset(entidadesDF, select = -c(document))

typesDF <- as.data.frame(typesdfm)
typesDF <- subset(typesDF, select = -c(document))

X <- cbind(embed,entidadesDF,typesDF,dados$resposta)
save(X, file = "adhoc/redemaluca/ds1/representacao_one_hot.RData")


library(keras)
tokenizer_entities <- text_tokenizer(num_words = 100) %>%
                      fit_text_tokenizer(dados$entidades)
vocabEntitiesLenght <- length(tokenizer_entities$word_index)
entidades <- texts_to_sequences(tokenizer_entities, dados$entidades)

max_sequence <- max(sapply(entidades, max))
max_sequence

enti <- vectorize_sequences(entidades, dimension = max_sequence)

View(enti)


vectorize_sequences <- function(sequences, dimension = max_features) {
  results <- matrix(0, nrow = length(sequences), ncol = dimension)
  for (i in 1:length(sequences)) {
    if (length(sequences[[i]])) {
      results[i, sequences[[i]]] <- 1
    }
  }
  return (results)
}
