library(tools)
library(rword2vec)
library(lsa)
library(readr)
library(quanteda)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("utils/resultadoshelper.R"))
source(file_path_as_absolute("utils/getDadosAmazon.R"))

#Configuracoes
DATABASE <- "icwsm"
dados <- getDadosAmazon()

fbcorpus <- corpus(dados$textParser)
fbdfm <- dfm(fbcorpus, remove=stopwords("english"), verbose=TRUE, stem = TRUE, remove_punct = TRUE)

#dfm(x, verbose = TRUE, toLower = TRUE,
#    removeNumbers = TRUE, removePunct = TRUE, removeSeparators = TRUE,
#    removeTwitter = FALSE, stem = FALSE, ignoredFeatures = NULL,
#    keptFeatures = NULL, language = "english", thesaurus = NULL,
#    dictionary = NULL, valuetype = c("glob", "regex", "fixed"), ..


fbdfm <- dfm_trim(fbdfm, min_docfreq = 2, verbose=TRUE)

w2v <- readr::read_delim("adhoc/quanteda/code/FBvector.txt", 
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

set.seed(123)
training <- sample(1:nrow(fb), floor(.80 * nrow(fb)))
test <- (1:nrow(fb))[1:nrow(fb) %in% training == FALSE]

View(fbdfm[1,])
