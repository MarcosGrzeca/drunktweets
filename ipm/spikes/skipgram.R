library(tools)
library(text2vec)
library(data.table)
library(SnowballC)
library(keras)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

# dadosTreinarEmbeddings <- getDadosWordEmbeddings()
getDadosWordEmbeddingsV2 <- function() {
      # dados <- query("SELECT textEmbedding 
      #                 FROM tweets t
      #                 WHERE LENGTH(textEmbedding) > 5
      #                 UNION ALL
      #                 SELECT textSemPalavrasControle as textEmbedding
      #                 FROM chat_tweets t
      #                 WHERE contabilizar = 1
      #                 AND drunk IN ('N', 'S')
      #                 AND LENGTH(textEmbedding) > 5
      #                 UNION ALL
      #                 SELECT textEmbedding
      #                 FROM tweets_amazon t
      #                 WHERE q2 IN ('0', '1')
      #                 AND LENGTH(textEmbedding) > 5
      #                 ")

    dados <- query("SELECT textSemPalavrasControle as textEmbedding
                      FROM chat_tweets t
                      WHERE contabilizar = 1
                      AND drunk IN ('N', 'S')
                      AND LENGTH(textEmbedding) > 10
                    ")

  dados$textEmbedding <- enc2utf8(dados$textEmbedding)
  dados$textEmbedding <- iconv(dados$textEmbedding, to='ASCII//TRANSLIT')
  dados$textEmbedding <- stringi::stri_enc_toutf8(dados$textEmbedding)
  dados$textEmbedding = gsub("'", "", dados$textEmbedding, ignore.case=T)
  return (dados)
}

dadosTreinarEmbeddings <- getDadosWordEmbeddingsV2()

library(doMC)
library(mlbench)
library(tm)
CORES <- 5
registerDoMC(CORES)

# reviews = gsub("&amp", "", reviews)
# reviews = gsub("(RT|via)((?:\\b\\W*@\\w+)+)", "", reviews)
# reviews = gsub("@\\w+", "", reviews)
# reviews = gsub("[[:punct:]]", "", reviews)
# reviews = gsub("[[:digit:]]", "", reviews)
# reviews = gsub("http\\w+", "", reviews)
# reviews = gsub("[ \t]{2,}", "", reviews)
# reviews = gsub("^\\s+|\\s+$", "", reviews) 

reviews <- dadosTreinarEmbeddings$textEmbedding

# word_count <- str_count(reviews, "\\S+" )
# reviews <- reviews[word_count > 5]

library(keras)
tokenizer <- text_tokenizer(num_words = 20000)
tokenizer %>% fit_text_tokenizer(reviews)

reviews_check <- reviews %>% texts_to_sequences(tokenizer,.) %>% lapply(., function(x) length(x) > 1) %>% unlist(.)
reviews <- reviews[reviews_check]

library(reticulate)
library(purrr)

vectorize_local <- function(data, vocab, textParser_maxlen){
  
  textEmbedding <- map(data$textEmbedding, function(x){
    map_int(x, ~which(.x == vocab))
  })
  
  list(
    textEmbedding = pad_sequences(textEmbedding, maxlen = textParser_maxlen)
  )
}

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

model %>%
  fit_generator(
    skipgrams_generator(reviews, tokenizer, skip_window, negative_samples), 
    # steps_per_epoch = 100000, epochs = 10
    steps_per_epoch = 6000, epochs = 10
    )

library(dplyr)

embedding_matrix <- get_weights(model)[[1]]

words <- data_frame(
  word = names(tokenizer$word_index), 
  id = as.integer(unlist(tokenizer$word_index))
)

words <- words %>%
  filter(id <= tokenizer$num_words) %>%
  arrange(id)

row.names(embedding_matrix) <- c("UNK", words$word)

#write.table(embedding_matrixTwo, "adhoc/exportembedding/skipgrams_10_epocas.txt",sep=" ",row.names=TRUE)