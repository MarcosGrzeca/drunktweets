options(max.print = 99999999)

library(tools)
library(rowr)
library(text2vec)
library(data.table)
library(SnowballC)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

#Configuracoes
DATABASE <- "icwsm"

dados <- getDadosChat()

setDT(dados)
setkey(dados, id)

#Text

it_train = itoken(dados$textParser, 
                  preprocessor = tolower,
                  tokenizer = word_tokenizer,
                  ids = dados$id, 
                  progressbar = TRUE)

vocab = create_vocabulary(it_train, stopwords = tm::stopwords("en"), ngram = c(1L, 3L))
vocab = prune_vocabulary(vocab, term_count_min = 3)
vectorizer = vocab_vectorizer(vocab)
dtm_train_texto = create_dtm(it_train, vectorizer)

dataFrameTexto <- as.data.frame(as.matrix(dtm_train_texto))
cols <- colnames(dataFrameTexto)
aspectos <- sort(colSums(dataFrameTexto), decreasing = TRUE)
manter <- round(length(aspectos) * 0.25)
aspectosManter <- c()
aspectosRemover <- c()

for(i in 1:length(aspectos)) {
  if (i <= manter) {
    aspectosManter <- c(aspectosManter, aspectos[i])
  } else {
    aspectosRemover <- c(aspectosRemover, aspectos[i])
  }
}

dataFrameTexto <- dataFrameTexto[names(aspectosManter)]

#Hashtags

it_train_hash = itoken(dados$hashtags, 
                       preprocessor = tolower, 
                       tokenizer = word_tokenizer, 
                       ids = dados$id, 
                       progressbar = TRUE)

vocabHashTags = create_vocabulary(it_train_hash)
vocabHashTags = prune_vocabulary(vocabHashTags, term_count_min = 2)
vectorizerHashTags = vocab_vectorizer(vocabHashTags)
dtm_train_hash_tags = create_dtm(it_train_hash, vectorizerHashTags)
dataFrameHash <- as.data.frame(as.matrix(dtm_train_hash_tags))

maFinal <- cbind.fill(subset(dados, select = -c(textParser, id, textOriginal, textEmbedding, numeroErros, entidades, types, hashtags)), dataFrameTexto)
maFinal <- cbind.fill(maFinal, dataFrameHash)
# save(maFinal, file = "chat/rdas/3gram-25-baseline.Rda")
save(maFinal, file = "chat/rdas/3gram-25-new.Rda")