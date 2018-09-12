library(keras)
library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
dados <- getDadosBaseline()

tokenizer <- text_tokenizer(num_words = 100, char_level = TRUE) %>%
  fit_text_tokenizer(dados$textEmbedding)

word_index <- tokenizer$word_index
cat("Found", length(word_index), "unique tokens.\n")

#Separação teste e treinamento
set.seed(10)
split=0.80

trainIndex <- createDataPartition(dados$resposta, p=split, list=FALSE)

dados_train <- dados[ trainIndex,]
dados_test <- dados[-trainIndex,]

one_hot_train <- texts_to_matrix(tokenizer, dados_train$textEmbedding, mode = "binary")
one_hot_test  <- texts_to_matrix(tokenizer, dados_test$textEmbedding, mode = "binary")

save.image(file="rdas/baseline_one_hot_char_level.RData")