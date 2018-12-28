library(tools)

fileName <- "ipm/results_q1_glove.Rdata"
source(file_path_as_absolute("ipm/loads.R"))

DESC <- "Exp1 GloVe- CNN + Semantic Enrichment + Word embeddings"

source(file_path_as_absolute("ipm/glove/load.R"))

#Section: Dados classificar
dados <- getDadosBaseline()

#Preparação dos dados
maxlen <- 38
max_words <- 7500

tokenizer <-  text_tokenizer(num_words = max_words) %>%
              fit_text_tokenizer(dados$textEmbedding)

sequences <- texts_to_sequences(tokenizer, dados$textEmbedding)
word_index = tokenizer$word_index

vocab_size <- length(word_index)
vocab_size <- vocab_size + 1

cat("Found", length(word_index), "unique tokens.\n")
data <- pad_sequences(sequences, maxlen = maxlen)

tokenizer_entities <- text_tokenizer(num_words = 1000) %>%
  fit_text_tokenizer(dados$entidades)

vocabEntitiesLenght <- length(tokenizer_entities$word_index)
dados$sequences <- texts_to_sequences(tokenizer_entities, dados$entidades)

tokenizer_types <- text_tokenizer(num_words = 1000) %>%
  fit_text_tokenizer(dados$types)
vocabTypesLenght <- length(tokenizer_types$word_index)
dados$sequences_types <- texts_to_sequences(tokenizer_types, dados$types)

library(caret)
trainIndex <- createDataPartition(dados$resposta, p=0.8, list=FALSE)
dados_train <- dados[ trainIndex,]
dados_test <- dados[-trainIndex,]

dados_train_sequence <- data[ trainIndex,]
dados_test_sequence <- data[-trainIndex,]

max_sequence <- max(sapply(dados_train$sequences, max))
max_sequence_types <- max(sapply(dados_train$sequences_types, max))

train_sequences <- vectorize_sequences(dados_train$sequences, dimension = max_sequence)
train_sequences_types <- vectorize_sequences(dados_train$sequences_types, dimension = max_sequence_types)

test_sequences <- vectorize_sequences(dados_test$sequences, dimension = max_sequence)
test_sequences_types <- vectorize_sequences(dados_test$sequences_types, dimension = max_sequence_types)

max_words <- vocab_size
word_index <- tokenizer$word_index
embedding_dims <- 100
embedding_matrix <- array(0, c(max_words, embedding_dims))

for (word in names(word_index)) {
  index <- word_index[[word]]
  if (index < max_words) {
    embedding_vector <- embeddings_index[[word]]
    if (!is.null(embedding_vector))
      embedding_matrix[index+1,] <- embedding_vector
  }
}

# Parameters --------------------------------------------------------------
filters <- 200
kernel_size <- 10
hidden_dims <- 200

main_input <- layer_input(shape = c(maxlen), dtype = "int32")
relu <- main_input %>% 
  layer_embedding(vocab_size, embedding_dims, input_length = maxlen) %>%
  layer_dropout(0.1) %>%
  layer_conv_1d(
    filters, kernel_size,
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  layer_global_max_pooling_1d() %>%
  layer_dense(hidden_dims)

auxiliary_input <- layer_input(shape = c(max_sequence))
entities_out <- auxiliary_input

auxiliary_input_types <- layer_input(shape = c(max_sequence_types))
types_out <- auxiliary_input_types

main_output <- layer_concatenate(c(relu, entities_out, types_out)) %>%  
  layer_dense(units = 64, activation = 'relu') %>% 
  layer_dropout(0.2) %>%
  layer_dense(units = 32, activation = "relu") %>%
  layer_dense(units = 1, activation = 'sigmoid')

model <- keras_model(
  inputs = c(main_input, auxiliary_input, auxiliary_input_types),
  outputs = main_output
)

get_layer(model, index = 1) %>%
  set_weights(list(embedding_matrix)) %>%
  freeze_weights()

model %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = "accuracy"
)

library(keras)
# Training ----------------------------------------------------------------        
history <- model %>%
  fit(
    x = list(dados_train_sequence, train_sequences, train_sequences_types),
    y = array(dados_train$resposta),
    batch_size = 64,
    epochs = 3,
    validation_split = 0.2
  )

# history
predictions <- model %>% predict(list(dados_test_sequence, test_sequences, test_sequences_types))
predictions2 <- round(predictions, 0)

matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
resultados <- addRowAdpater(resultados, DESC, matriz)

##
library(dplyr)

embedding_matrixTwo <- get_weights(model)[[1]]

words <- data_frame(
  word = names(tokenizer$word_index), 
  id = as.integer(unlist(tokenizer$word_index))
)

words <- words %>%
  filter(id <= tokenizer$num_words) %>%
  arrange(id)

row.names(embedding_matrixTwo) <- c("UNK", words$word)

library(text2vec)

find_similar_words <- function(word, embedding_matrix, n = 5) {
  similarities <- embedding_matrix[word, , drop = FALSE] %>%
    sim2(embedding_matrix, y = ., method = "cosine")
  
  similarities[,1] %>% sort(decreasing = TRUE) %>% head(n)
}
find_similar_words("beer", embedding_matrixTwo, n = 20)

# > find_similar_words("beer", embedding_matrixTwo, n = 20)
#      beer      wine     drink    drinks    coffee     beers  drinking    bottle
# 1.0000000 0.8526084 0.7997232 0.7799885 0.7744594 0.7730991 0.7705956 0.7221602
#   whiskey       tea      brew     booze      food      pint     water    liquor
# 0.6919562 0.6875389 0.6800749 0.6795899 0.6692315 0.6675983 0.6645441 0.6549108
#   bottles      soda     vodka       ice
# 0.6492445 0.6429363 0.6407327 0.6367506


#man.vec <- vector.normalize( colSums( word.vector.df[ grep( "^man$", word.list), -1] ) )

library(ggplot2)
library(dplyr)
library(tibble)
library(broom)

search_synonyms <- function(word_vectors, selected_vector) {
  
  similarities <- word_vectors %*% selected_vector %>%
    tidy() %>%
    as_tibble() %>%
    rename(token = .rownames,
           similarity = unrowname.x.)
  
  similarities %>%
    arrange(-similarity)    
}

#beer <- search_synonyms(embedding_matrixTwo, embedding_matrixTwo["beer",])
#alcohol <- search_synonyms(embedding_matrixTwo, embedding_matrixTwo["alcohol",])
#drunk <- search_synonyms(embedding_matrixTwo, embedding_matrixTwo["drunk",])
#sober <- search_synonyms(embedding_matrixTwo, embedding_matrixTwo["sober",])

beer <- convertSimilaridadeToTibble(find_similar_words("beer", embedding_matrixTwo, n = 15))
alcohol <- convertSimilaridadeToTibble(find_similar_words("alcohol", embedding_matrixTwo, n = 15))
drunk <- convertSimilaridadeToTibble(find_similar_words("drunk", embedding_matrixTwo, n = 15))
sober <- convertSimilaridadeToTibble(find_similar_words("sober", embedding_matrixTwo, n = 15))

beer %>%
  mutate(selected = "beer") %>%
  bind_rows(alcohol %>%
              mutate(selected = "alcohol")) %>%
  bind_rows(drunk %>%
              mutate(selected = "drunk")) %>%
  bind_rows(sober %>%
              mutate(selected = "sober")) %>%
  group_by(selected) %>%
  top_n(15, similarity) %>%
  ungroup %>%
  mutate(token = reorder(token, similarity)) %>%
  ggplot(aes(token, similarity, fill = selected)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~selected, scales = "free") +
  coord_flip() +
  theme(strip.text=element_text(hjust=0, size=12)) +
  scale_y_continuous(expand = c(0,0))
