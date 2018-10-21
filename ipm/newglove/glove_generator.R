library(tools)
library(text2vec)

library(text2vec)
text8_file = "text8"
wiki = readLines(text8_file, n = 1, warn = FALSE)

# create vocabulary
tokens <- space_tokenizer(wiki)
it = itoken(tokens)
stop_words <- tm::stopwords("en")
vocab <- create_vocabulary(it, stopwords = stop_words)
vocab <- prune_vocabulary(vocab, term_count_min = 2)

vectorizer = vocab_vectorizer(vocab, grow_dtm = F, skip_grams_window = 5)

tcm <- create_tcm(it, vectorizer, skip_grams_window = 5L)

#Alternativa 2
glove = GlobalVectors$new(word_vectors_size = 50, vocabulary = vocab, x_max = 10)
wv_main = fit_transform(tcm, glove, n_iter = 20)
wv_context = glove$components
word_vectors = wv_main + t(wv_context)