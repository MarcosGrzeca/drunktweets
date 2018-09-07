library(keras)
library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
dados <- getDadosCFS()

tokenizer <- text_tokenizer(num_words = 1000) %>%
             fit_text_tokenizer(dados$entidades)
vocabEntitiesLenght <- length(tokenizer$word_index)
dados$sequences_entities <- texts_to_sequences(tokenizer, dados$entidades)
max_sequence <- max(sapply(dados$sequences_entities, max))

tokenizer_types <- text_tokenizer(num_words = 1000) %>%
             fit_text_tokenizer(dados$types)
vocabTypesLenght <- length(tokenizer_types$word_index)
dados$sequences_types <- texts_to_sequences(tokenizer_types, dados$types)
max_sequence_types <- max(sapply(dados$sequences_types, max))

library(doMC)
library(mlbench)

CORES <- 4
registerDoMC(CORES)

#Separação teste e treinamento
set.seed(10)
split=0.80

trainIndex <- createDataPartition(dados$resposta, p=split, list=FALSE)
dados_train <- dados[ trainIndex,]
dados_test <- dados[-trainIndex,]

#Texto
dadosTransformado <- dados_train %>%
  mutate(
    textOriginal = map(textOriginal, ~tokenize_words(.x))
  ) %>%
  select(textOriginal, entidades)

dadosTransformadoTest <- dados_test %>%
  mutate(
    textOriginal = map(textOriginal, ~tokenize_words(.x))
  ) %>%
  select(textOriginal, entidades)

all_data <- bind_rows(dadosTransformado, dadosTransformadoTest)

#Vocabulario texto
vocab <- c(unlist(dadosTransformado$textOriginal), unlist(dadosTransformadoTest$textOriginal)) %>%
  unique() %>%
  sort()

vocab_size <- length(vocab) + 1
maxlen <- map_int(all_data$textOriginal, ~length(.x)) %>% max()
text_train <- vectorize_stories(dadosTransformado, vocab, maxlen)
text_test <- vectorize_stories(dadosTransformadoTest, vocab, maxlen)

#Entities
entities_train <- vectorize_sequences(dados_train$sequences_entities, dimension = max_sequence)
entities_test  <- vectorize_sequences(dados_test$sequences_entities,  dimension = max_sequence)

#Types
types_train <- vectorize_sequences(dados_train$sequences_types, dimension = max_sequence_types)
types_test  <- vectorize_sequences(dados_test$sequences_types,  dimension = max_sequence_types)

# Data Preparation --------------------------------------------------------
# Parameters --------------------------------------------------------------
batch_size <- 32
epochs <- 3
embedding_dims <- 100
filters <- 200
kernel_size <- 10
hidden_dims <- 200

main_input <- layer_input(shape = c(maxlen), dtype = "int32")
ccn_out <- main_input %>% 
  layer_embedding(vocab_size, embedding_dims, input_length = maxlen) %>%
  layer_conv_1d(
    filters, kernel_size,
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  layer_global_max_pooling_1d() %>%
  layer_dense(hidden_dims) %>%
  layer_dropout(0.2) %>%
  layer_activation("relu")

auxiliary_input <- layer_input(shape = c(max_sequence))
entities_out <- auxiliary_input

auxiliary_input_types <- layer_input(shape = c(max_sequence_types))
types_out <- auxiliary_input_types

main_output <- layer_concatenate(c(ccn_out, entities_out, types_out)) %>%  
layer_dense(units = 64, activation = 'relu') %>% 
layer_dense(units = 1, activation = 'sigmoid')

model <- keras_model(
  inputs = c(main_input, auxiliary_input, auxiliary_input_types),
  outputs = main_output
  )

# Compile model
model %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = "accuracy"
  )

history <- model %>%
fit(
  x = list(text_train$new_textParser, entities_train, types_train),
  y = array(dados_train$resposta),
  batch_size = batch_size,
  epochs = epochs,
  validation_split = 0.2
)

history
predictions <- model %>% predict(list(text_test$new_textParser, entities_test, types_test))
predictions2 <- round(predictions, 0)
matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))

adicionarResultadosTestes("relu_concatenate.R apenas semântico", matriz$byClass["F1"] * 100, matriz$byClass["Precision"] * 100, matriz$byClass["Recall"] * 100)