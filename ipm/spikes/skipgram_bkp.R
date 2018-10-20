library(tools)
library(text2vec)
library(data.table)
library(SnowballC)
library(keras)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

#dadosTreinarEmbeddings <- getDadosWordEmbeddings()

dadosTreinarEmbeddings <- read.csv(file="teste2.csv", header=TRUE, sep=",")
reviews <- dadosTreinarEmbeddings$texto
reviews <- iconv(reviews, to = "UTF-8")

#View(reviews)

library(doMC)
library(mlbench)
CORES <- 5
registerDoMC(CORES)

word_count <- str_count(reviews, "\\S+" )
word_count
lengths(gregexpr("[A-z]\\W+", reviews)) + 1L

sapply(gregexpr("[[:alpha:]]+", reviews), function(x) sum(x > 0))

reviews_check <- reviews %>% texts_to_sequences(tokenizer,.) %>% lapply(., function(x) length(x) > 1) %>% unlist(.)
reviews_check

word_count[3]
#reviews <- dadosTreinarEmbeddings$textEmbedding[word_count > 4]

library(keras)
tokenizer <- text_tokenizer(num_words = 500)
tokenizer %>% fit_text_tokenizer(reviews)

#tokenizer %>% fit_text_tokenizer(dadosTreinarEmbeddings$textEmbedding)
#reviews_check <- dadosTreinarEmbeddings$textEmbedding %>% texts_to_sequences(tokenizer,.) %>% lapply(., function(x) length(x) > 1) %>% unlist(.)
#table(reviews_check)
#reviews <- dadosTreinarEmbeddings$textEmbedding[reviews_check]
#reviews <- reviews[reviews_check]

library(reticulate)
library(purrr)
skipgrams_generator <- function(text, tokenizer, window_size, negative_samples) {
  gen <- texts_to_sequences_generator(tokenizer, sample(text))
  
    function() {
    try({
      skip <- iter_next(gen) %>%
        skipgrams(
          vocabulary_size = tokenizer$num_words, 
          window_size = window_size, 
          negative_samples = 1
        )
      x <- transpose(skip$couples) %>% map(. %>% unlist %>% as.matrix(ncol = 1))
      y <- skip$labels %>% as.matrix(ncol = 1)
      list(x, y)
    })
  }
}

embedding_size <- 100  # Dimension of the embedding vector.
skip_window <- 5       # How many words to consider left and right.
num_sampled <- 1       # Number of negative examples to sample for each word.

input_target <- layer_input(shape = 1)
input_context <- layer_input(shape = 1)

embedding <- layer_embedding(
  input_dim = tokenizer$num_words + 1, 
  output_dim = embedding_size, 
  input_length = 1, 
  name = "embedding"
)

target_vector <- input_target %>% 
  embedding() %>% 
  layer_flatten()

context_vector <- input_context %>%
  embedding() %>%
  layer_flatten()

dot_product <- layer_dot(list(target_vector, context_vector), axes = 1)
output <- layer_dense(dot_product, units = 1, activation = "sigmoid")

model <- keras_model(list(input_target, input_context), output)
model %>% compile(loss = "binary_crossentropy", optimizer = "adam")

tokenizer$word_index

model %>%
  fit_generator(
    skipgrams_generator(reviews, tokenizer, skip_window, negative_samples), 
    steps_per_epoch = 15, epochs = 5
  )

library(dplyr)

embedding_matrix <- get_weights(model)[[1]]