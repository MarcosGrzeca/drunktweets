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
clearConsole();

dados <- getDadosSVM()
dados$hashtags = gsub("#", "#tag_", dados$hashtags)
dados$textParser = gsub("'", "", dados$textParser)
dados$numeroErros[dados$numeroErros > 1] <- 1
dados <- discretizarTurno(dados)
clearConsole()

setDT(dados)
setkey(dados, id)

it_train = itoken(dados$textParser, 
                  preprocessor = tolower,
                  tokenizer = word_tokenizer,
                  ids = dados$id, 
                  progressbar = TRUE)

vocab = create_vocabulary(it_train, stopwords = tm::stopwords("en"), ngram = c(1L, 2L))
vocab = prune_vocabulary(vocab, term_count_min = 3)
vectorizer = vocab_vectorizer(vocab)
dtm_train_texto = create_dtm(it_train, vectorizer)

it_train_hash = itoken(dados$hashtags, 
                       preprocessor = tolower, 
                       tokenizer = word_tokenizer, 
                       ids = dados$id, 
                       progressbar = TRUE)

vocabHashTags = create_vocabulary(it_train_hash)
vocabHashTags = prune_vocabulary(vocabHashTags, term_count_min = 2)
vectorizerHashTags = vocab_vectorizer(vocabHashTags)
dtm_train_hash_tags = create_dtm(it_train_hash, vectorizerHashTags)

it_train = itoken(strsplit(dados$entidades, ","),
                  preprocessor = tolower, 
                  tokenizer = word_tokenizer,
                  ids = dados$id, 
                  progressbar = TRUE)

vocab = create_vocabulary(it_train)
vocab = prune_vocabulary(vocab, term_count_min = 2)
vectorizer = vocab_vectorizer(vocab)
dataFrameEntidades = create_dtm(it_train, vectorizer)

#Concatenar resultados
dataFrameTexto <- as.data.frame(as.matrix(dtm_train_texto))
dataFrameHash <- as.data.frame(as.matrix(dtm_train_hash_tags))
dataFrameEntidades <- as.data.frame(as.matrix(dataFrameEntidades))

maFinal <- cbind.fill(subset(dados, select = -c(textParser, id, hashtags, textOriginal, entidades, enriquecimentoTypes, types)), dataFrameTexto)
maFinal <- cbind.fill(maFinal, dataFrameHash)
maFinal <- cbind.fill(maFinal, dataFrameEntidades)
save(maFinal, file = "rdas/2gram-entidades-hora-erro.Rda")