library(tools)
library(tm)

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

dados <- getDadosBaselineByQ("q2")
# dados$textEmbedding <- removePunctuation(dados$textEmbedding)

maxlen <- 38
max_words <- 4405

tokenizer <-  text_tokenizer(num_words = max_words) %>%
              fit_text_tokenizer(dados$textEmbedding)

sequences <- texts_to_sequences(tokenizer, dados$textEmbedding)
word_index = tokenizer$word_index

vocab_size <- length(word_index)
vocab_size <- vocab_size + 1
vocab_size

cat("Found", length(word_index), "unique tokens.\n")
data <- pad_sequences(sequences, maxlen = maxlen)

library(caret)
trainIndex <- createDataPartition(dados$resposta, p=0.8, list=FALSE)
dados_train <- dados[ trainIndex,]
dados_test <- dados[-trainIndex,]

dados_train_sequence <- data[ trainIndex,]
dados_test_sequence <- data[-trainIndex,]

max_words <- vocab_size
word_index <- tokenizer$word_index

# Data Preparation --------------------------------------------------------
# Parameters --------------------------------------------------------------
embedding_dims <- 100

# Parameters --------------------------------------------------------------
# filters <- 200
filters <- 164

main_input <- layer_input(shape = c(maxlen), dtype = "int32")
main_output <- main_input %>% 
  layer_embedding(vocab_size, embedding_dims, input_length = maxlen, name = "embedding") %>%
  bidirectional(
    layer_lstm(units = 128, return_sequences = TRUE)
  ) %>%
  bidirectional(
    layer_lstm(units = 64, return_sequences = TRUE, recurrent_dropout = 0.2)
  ) %>%
  bidirectional(
    layer_lstm(units = 32)
  ) %>%
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
    epochs = 10,
    #callbacks = callbacks_list,
    validation_split = 0.2
  )

addRowAdpater <- function(resultados, baseline, matriz, ...) {
  newRes <- data.frame(baseline, matriz$byClass["F1"] * 100, matriz$byClass["Precision"] * 100, matriz$byClass["Recall"] * 100)
  rownames(newRes) <- baseline
  names(newRes) <- c("Baseline", "F1", "Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")

predictions <- model %>% predict(list(dados_test_sequence))
predictions2 <- round(predictions, 0)
matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
resultados <- addRowAdpater(resultados, "TESTE", matriz)


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

embedding_file <- "ipmbilstm/exportembedding/ds1/q2/bilstm_10_epocas.txt"
write.table(embedding_matrixTwo, embedding_file, sep=" ",row.names=TRUE)
system(paste0("sed -i 's/\"//g' ", embedding_file))