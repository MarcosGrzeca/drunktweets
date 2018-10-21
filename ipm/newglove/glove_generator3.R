library(tools)
library(text2vec)

library(text2vec)

library(tools)
library(text2vec)
library(data.table)
library(SnowballC)
library(keras)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

dadosTreinarEmbeddings <- getDadosWordEmbeddings()
wiki <- dadosTreinarEmbeddings$textEmbedding

# create vocabulary
tokens <- space_tokenizer(wiki)
it = itoken(tokens)
stop_words <- tm::stopwords("en")
#vocab <- create_vocabulary(it, stopwords = stop_words)
vocab <- create_vocabulary(it)
vocab <- prune_vocabulary(vocab)

#vectorizer = vocab_vectorizer(vocab, grow_dtm = F, skip_grams_window = 5)
vectorizer <- vocab_vectorizer(vocab)

tcm <- create_tcm(it, vectorizer, skip_grams_window = 5L)

glove <- GlobalVectors$new(word_vectors_size = 100, vocabulary = vocab, x_max = 10)
wv_main <- fit_transform(tcm, glove, n_iter = 25)
wv_context <- glove$components
word_vectors <- wv_main + t(wv_context)
save(word_vectors, file = "ipm/embeddings/skipgram_glove.Rda")
