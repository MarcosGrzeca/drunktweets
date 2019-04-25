library(tools)
library(text2vec)
library(data.table)
library(SnowballC)
library(keras)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

#Section: Gerar embeddings
dadosTreinarEmbeddings <- getDadosWordEmbeddingsV2()

tokens <- dadosTreinarEmbeddings$textEmbedding %>% tolower %>% word_tokenizer

# create vocabulary
it = itoken(tokens)
v <- create_vocabulary(it, stopwords = tm::stopwords("en")) %>% prune_vocabulary(term_count_min = 2)
# v <- create_vocabulary(it)

vectorizer <- vocab_vectorizer(v)
#vectorizer = vocab_vectorizer(v, grow_dtm = F, skip_grams_window = 5)

tcm <- create_tcm(it, vectorizer, skip_grams_window = 5L)

embedding_dim <- 100
glove = GlobalVectors$new(word_vectors_size = embedding_dim, vocabulary = v, x_max = 20)
word_vectors_main <- glove$fit_transform(tcm, n_iter = 50)

word_vectors_context = glove$components
word_vectorsSkip = word_vectors_main + t(word_vectors_context)

write.table(word_vectorsSkip, "adhoc/exportembedding/glove_50epocas_5l_sem_stopwords.txt",sep=" ",row.names=TRUE)