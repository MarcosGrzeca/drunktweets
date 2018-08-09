library(keras)
library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

resultados <- data.frame(matrix(ncol = 1, nrow = 0))
names(resultados) <- c("entidades")

resultados2 <- data.frame(matrix(ncol = 1, nrow = 0))
names(resultados2) <- c("entidades")

addRowResultado <- function(row) {
  newRes <- data.frame(row)
  names(newRes) <- c("entidades")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

addRowResultado2 <- function(row) {
  newRes <- data.frame(row)
  names(newRes) <- c("entidades")
  newdf <- rbind(resultados2, newRes)
  return (newdf)
}
resultados <- addRowResultado("ahha, antonio, delma")
resultados <- addRowResultado("maria")

resultados2 <- addRowResultado2("delma, fran")
resultados2 <- addRowResultado2("maria")


dados1 <- resultados %>%
  mutate(
    entidades = map(entidades, ~tokenize_words(.x))
  ) %>%
  select(entidades)

dados2 <- resultados2 %>%
  mutate(
    entidades = map(entidades, ~tokenize_words(.x))
  ) %>%
  select(entidades)

all_data <- bind_rows(dados1, dados2)
vocab <- c(unlist(dados1$entidades), unlist(dados2$entidades)) %>%
  unique() %>%
  sort()

vocab

vocab_size <- length(vocab) + 1
maxlen <- map_int(all_data$entidades, ~length(.x)) %>% max()

resultados
vectorize_entities(dados1, vocab, maxlen)
vectorize_entities(dados2, vocab, maxlen)









library("tokenizers")
tokenize_words("MArcos a Augusto. Vamos almoçar")
tokenize_words("MArcos a Augusto. Vamos almoçar", lowercase = TRUE)

