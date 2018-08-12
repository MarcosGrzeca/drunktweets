options(max.print = 99999999)

library(tools)
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

#Configuracoes
DATABASE <- "icwsm"
clearConsole();

dados <- getDadosSVM()
dados$hashtags = gsub("#", "#tag_", dados$hashtags)
dados$textParser = gsub("'", "", dados$textParser)
dados$numeroErros[dados$numeroErros > 1] <- 1
dados <- discretizarTurno(dados)
clearConsole()

if (!require("text2vec")) {
  install.packages("text2vec")
}
library(text2vec)
library(data.table)
library(SnowballC)

setDT(dados)
setkey(dados, id)

it_train = itoken(dados$textParser, 
                  preprocessor = tolower,
                  tokenizer = word_tokenizer,
                  ids = dados$id, 
                  progressbar = TRUE)

vocab = create_vocabulary(it_train, stopwords = tm::stopwords("en"), ngram = c(1L, 2L))
vectorizer = vocab_vectorizer(vocab)
dtm_train_texto = create_dtm(it_train, vectorizer)

it_train_hash = itoken(dados$hashtags, 
                       preprocessor = tolower, 
                       tokenizer = word_tokenizer, 
                       ids = dados$id, 
                       progressbar = TRUE)

vocabHashTags = create_vocabulary(it_train_hash)
vectorizerHashTags = vocab_vectorizer(vocabHashTags)
dtm_train_hash_tags = create_dtm(it_train_hash, vectorizerHashTags)

it_train = itoken(strsplit(dados$entidades, ","),
                  preprocessor = tolower, 
                  tokenizer = word_tokenizer,
                  ids = dados$id, 
                  progressbar = TRUE)

vocab = create_vocabulary(it_train)
vectorizer = vocab_vectorizer(vocab)
dataFrameEntidades = create_dtm(it_train, vectorizer)
dataFrameEntidades <- as.data.frame(as.matrix(dataFrameEntidades))

#Concatenar resultados
dataFrameTexto <- as.data.frame(as.matrix(dtm_train_texto))
dataFrameHash <- as.data.frame(as.matrix(dtm_train_hash_tags))
clearConsole()

library(rowr)
library(RWeka)

maFinal <- cbind.fill(dados, dataFrameTexto)
maFinal <- cbind.fill(maFinal, dataFrameHash)
maFinal <- cbind.fill(maFinal, dataFrameEntidades)
maFinal <- subset(maFinal, select = -c(textParser, id, hashtags, textoCompleto, entidades))
save(maFinal, file = "rdas/2gram-entidades-hora-erro.Rda")
