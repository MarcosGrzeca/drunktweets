library(tools)
library(tm)

source(file_path_as_absolute("ipm/loads.R"))
source(file_path_as_absolute("utils/getDadosAmazon.R"))

#Section: Dados classificar
dados <- getDadosAmazon()

dados$textEmbedding <- removePunctuation(dados$textEmbedding)

#Preparação dos dados
maxlen <- 38
#max_words <- 9322
max_words <- 9444

tokenizer <-  text_tokenizer(num_words = max_words) %>%
              fit_text_tokenizer(dados$textEmbedding)

sequences <- texts_to_sequences(tokenizer, dados$textEmbedding)
word_index = tokenizer$word_index

vocab_size <- length(word_index)
vocab_size <- vocab_size + 1
vocab_size

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

# Data Preparation --------------------------------------------------------
# Parameters --------------------------------------------------------------
embedding_dims <- 100

# Parameters --------------------------------------------------------------
filters <- 200
kernel_size <- 10
hidden_dims <- 200

main_input <- layer_input(shape = c(maxlen), dtype = "int32")
main_output <- main_input %>% 
  layer_embedding(vocab_size, embedding_dims, input_length = maxlen, name = "embedding") %>%
  layer_lstm(units = 16, return_sequences = TRUE) %>%
  layer_lstm(units = 16, return_sequences = TRUE, recurrent_dropout = 0.2) %>%
  layer_lstm(units = 16) %>%
  layer_dense(units = 1, activation = 'sigmoid')


model <- keras_model(
  inputs = c(main_input),
  outputs = main_output
)

model %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = "accuracy"
)

library(keras)
# Training ----------------------------------------------------------------        
history <- model %>%
  fit(
    x = list(dados_train_sequence),
    y = array(dados_train$resposta),
    batch_size = 64,
    epochs = 5,
    validation_split = 0.2
  )

history
# predictions <- model %>% predict(list(dados_test_sequence))
# predictions2 <- round(predictions, 0
# matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
# resultados <- addRowAdpater(resultados, DESC, matriz)

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

write.table(embedding_matrixTwo, "adhoc/exportembedding/lstm_5_epocas.txt",sep=" ",row.names=TRUE)
