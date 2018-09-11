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

vectorize_local <- function(data, vocab, textParser_maxlen){
  
  textEmbedding <- map(data$textEmbedding, function(x){
    map_int(x, ~which(.x == vocab))
  })
  
  list(
    textEmbedding = pad_sequences(textEmbedding, maxlen = textParser_maxlen)
  )
}

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
    textEmbedding = map(textEmbedding, ~tokenize_words(.x))
  ) %>%
  select(textEmbedding)

dadosTransformadoTest <- dados_test %>%
  mutate(
    textEmbedding = map(textEmbedding, ~tokenize_words(.x))
  ) %>%
  select(textEmbedding)

all_data <- bind_rows(dadosTransformado, dadosTransformadoTest)

#Vocabulario texto
vocab <- c(unlist(dadosTransformado$textEmbedding), unlist(dadosTransformadoTest$textEmbedding)) %>%
  unique() %>%
  sort()

vocab_size <- length(vocab) + 1
maxlen <- map_int(all_data$textEmbedding, ~length(.x)) %>% max()

train_vec <- vectorize_local(dadosTransformado, vocab, maxlen)

#Generate Test
test_vec <- vectorize_local(dadosTransformadoTest, vocab, maxlen)

save.image(file="rdas/baseline_embeddings.RData")