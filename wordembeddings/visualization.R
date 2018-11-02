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

#dump(wiki, "embedgins.csv")

# create vocabulary
tokens <- space_tokenizer(wiki)
it = itoken(tokens)
stop_words <- tm::stopwords("en")
vocab <- create_vocabulary(it, stopwords = stop_words)
vocab <- prune_vocabulary(vocab)

#vectorizer = vocab_vectorizer(vocab, grow_dtm = F, skip_grams_window = 5)
vectorizer <- vocab_vectorizer(vocab)

tcm <- create_tcm(it, vectorizer, skip_grams_window = 5L)

glove <- GlobalVectors$new(word_vectors_size = 100, vocabulary = vocab, x_max = 10)
wv_main <- fit_transform(tcm, glove, n_iter = 25)
wv_context <- glove$components
word_vectors <- wv_main + t(wv_context)
#save(word_vectors, file = "ipm/embeddings/skipgram_glove.Rda")

library(Rtsne)
library(ggplot2)
library(plotly)

#tsne <- Rtsne(word_vectors, perplexity = 50, pca = TRUE)
#tsne <- Rtsne(word_vectors[1:1500,], perplexity = 1, pca = TRUE)

#conjunto <- c("beer", "drink", "alcohol", "marijuana", "mother")
conjunto <- vocabTeste$term

tsne <- Rtsne(word_vectors[conjunto,], perplexity = 30, pca = TRUE, max_iter = 3000)

tsne_plot <- tsne$Y %>%
  as.data.frame() %>%
  #mutate(word = row.names(word_vectors[1:1500,])) %>%
  mutate(word = row.names(word_vectors[conjunto,])) %>%
  ggplot(aes(x = V1, y = V2, label = word)) + 
  geom_text(size = 3)
tsne_plot


find_similar_words <- function(word, embedding_matrix, n = 5) {
  similarities <- embedding_matrix[word, , drop = FALSE] %>%
    sim2(embedding_matrix, y = ., method = "cosine")
  
  similarities[,1] %>% sort(decreasing = TRUE) %>% head(n)
}


vocabTeste <- prune_vocabulary(vocab, term_count_min = 60)


find_similar_words("drunk", word_vectors, 10)

#  beer  drinking     drink      need    bottle      wine   alcohol       can         I     night         ?      just      like 
# 1.0000000 0.6629333 0.6334025 0.6146806 0.6125733 0.5867721 0.5548209 0.5472582 0.5371698 0.5360620 0.5265826 0.5250713 0.5235160 
#       get      last      much  #mention     party     &amp;      cold 
# 0.5226401 0.5116191 0.5109690 0.5106544 0.5048830 0.5044898 0.4926627 