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

tokenizer <- text_tokenizer(num_words = 7500) %>%
  fit_text_tokenizer(dados$textEmbedding)

one_hot_results <- texts_to_matrix(tokenizer, dados$textEmbedding, mode = "binary")
word_index <- tokenizer$word_index
cat("Found", length(word_index), "unique tokens.\n")
#word_index

library(rowr)
dados <- cbind.fill(subset(dados, select = c(resposta)), one_hot_results)

#Separação teste e treinamento
set.seed(10)
split=0.80

trainIndex <- createDataPartition(dados$resposta, p=split, list=FALSE)

dados_train <- dados[ trainIndex,]
dados_test <- dados[-trainIndex,]

save.image(file="rdas/baseline_one_hot_q3.RData")
