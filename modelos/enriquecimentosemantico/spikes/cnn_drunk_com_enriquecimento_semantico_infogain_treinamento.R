library(keras)
library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
dados <- getDadosInfoGain()

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

# Texto
dadosTransformado <- dados_train %>%
  mutate(
    textOriginal = map(textOriginal, ~tokenize_words(.x)),
    entidades = map(entidades, ~tokenize_entities(.x))
  ) %>%
  select(textOriginal, entidades)

dadosTransformadoTest <- dados_test %>%
  mutate(
    textOriginal = map(textOriginal, ~tokenize_words(.x)),
    entidades = map(entidades, ~tokenize_entities(.x))
  ) %>%
  select(textOriginal, entidades)

all_data <- bind_rows(dadosTransformado, dadosTransformadoTest)

#Vocabulario texto
vocab <- c(unlist(dadosTransformado$textOriginal), unlist(dadosTransformadoTest$textOriginal)) %>%
  unique() %>%
  sort()

vocab_size <- length(vocab) + 1
maxlen <- map_int(all_data$textOriginal, ~length(.x)) %>% max()

train_vec <- vectorize_stories(dadosTransformado, vocab, maxlen)

#Vocabulario enttidades
vocabEntidades <- c(unlist(dadosTransformado$entidades), unlist(dadosTransformadoTest$entidades)) %>%
  unique() %>%
  sort()

maxlen_entidades <- map_int(all_data$entidades, ~length(.x)) %>% max()
sequences <- vectorize_entities(dadosTransformado, vocabEntidades, maxlen_entidades)

# Data Preparation --------------------------------------------------------
# Parameters --------------------------------------------------------------
batch_size <- 32
epochs <- 3
embedding_dims <- 100
filters <- 250
kernel_size <- 3
hidden_dims <- 250

main_input <- layer_input(shape = c(maxlen), dtype = "int32")
ccn_out <- main_input %>% 
  layer_embedding(vocab_size, embedding_dims, input_length = maxlen) %>%
  layer_dropout(0.2) %>%
  layer_conv_1d(
    filters, kernel_size, 
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  layer_global_max_pooling_1d() %>%
  layer_dense(hidden_dims) %>%
  layer_dropout(0.2) %>%
  layer_activation("relu")

auxiliary_input <- layer_input(shape = c(maxlen_entidades))

main_output <- layer_concatenate(c(ccn_out, auxiliary_input)) %>%  
  layer_dense(units = 64, activation = 'relu') %>% 
  layer_dense(units = 1, activation = 'sigmoid')

model <- keras_model(
  inputs = c(main_input, auxiliary_input),
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
    x = list(train_vec$new_textParser, sequences$entidades),
    y = array(dados_train$resposta),
    batch_size = batch_size,
    epochs = epochs,
    validation_split = 0.2
  )

history

#Generate Test
test_vec <- vectorize_stories(dadosTransformadoTest, vocab, maxlen)
sequences_test <- vectorize_entities(dadosTransformadoTest, vocabEntidades, maxlen_entidades)

evaluation <- model %>% evaluate(
  list(test_vec$new_textParser, sequences_test$entidades),
  array(dados_test$resposta),
  batch_size = batch_size
)
evaluation

predictions <- model %>% predict(list(test_vec$new_textParser, sequences_test$entidades))
predictions

predictions2 <- round(predictions, 0)

matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))

#load(file="rdas/treinamento_teste.RData")