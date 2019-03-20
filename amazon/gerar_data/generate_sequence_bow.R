library(keras)
library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("utils/getDadosAmazon.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
dados <- getDadosAmazon()

#library(tm)
#dados$textOriginal <- removePunctuation(dados$textOriginal)

tokenizer <- text_tokenizer(num_words = 1000) %>%
             fit_text_tokenizer(dados$entidades)
vocabEntitiesLenght <- length(tokenizer$word_index)
dados$sequences <- texts_to_sequences(tokenizer, dados$entidades)

tokenizer_types <- text_tokenizer(num_words = 1000) %>%
             fit_text_tokenizer(dados$types)
vocabTypesLenght <- length(tokenizer_types$word_index)
dados$sequences_types <- texts_to_sequences(tokenizer_types, dados$types)

library(doMC)
library(mlbench)

#Separação teste e treinamento
set.seed(10)
split=0.80

trainIndex <- createDataPartition(dados$resposta, p=split, list=FALSE)

dados_train <- dados[ trainIndex,]
dados_test <- dados[-trainIndex,]

# Texto
dadosTransformado <- dados_train %>%
  mutate(
    textOriginal = map(textOriginal, ~tokenize_words(.x))
  ) %>%
  select(textOriginal)

dadosTransformadoTest <- dados_test %>%
  mutate(
    textOriginal = map(textOriginal, ~tokenize_words(.x))
  ) %>%
  select(textOriginal)

all_data <- bind_rows(dadosTransformado, dadosTransformadoTest)

#Vocabulario texto
vocab <- c(unlist(dadosTransformado$textOriginal), unlist(dadosTransformadoTest$textOriginal)) %>%
  unique() %>%
  sort()

vocab_size <- length(vocab) + 1
maxlen <- map_int(all_data$textOriginal, ~length(.x)) %>% max()

train_vec <- vectorize_stories(dadosTransformado, vocab, maxlen)

#Vocabulario enttidades
max_sequence <- max(sapply(dados_train$sequences, max))
sequences <- vectorize_sequences(dados_train$sequences, dimension = max_sequence)

max_sequence_types <- max(sapply(dados_train$sequences_types, max))
sequences_types <- vectorize_sequences(dados_train$sequences_types, dimension = max_sequence_types)

#Generate Test
test_vec <- vectorize_stories(dadosTransformadoTest, vocab, maxlen)
sequences_test <- vectorize_sequences(dados_test$sequences, dimension = max_sequence)
sequences_test_types <- vectorize_sequences(dados_test$sequences_types, dimension = max_sequence_types)

#Generate Bow
tokenizerBow <- text_tokenizer(num_words = 8000) %>%
  fit_text_tokenizer(dados$textParser)

dataframebow_train <- texts_to_matrix(tokenizerBow, dados_train$textParser, mode = "binary")
dataframebow_test  <- texts_to_matrix(tokenizerBow, dados_test$textParser,  mode = "binary")
save.image(file="amazon/rdas/sequencesexp6_bow.RData")