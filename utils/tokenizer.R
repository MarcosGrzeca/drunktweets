library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)

trim <- function (x) gsub("^\\s+|\\s+$", "", x)

tokenize_words <- function(x){
  x <- x %>% 
    tolower %>%
    str_replace_all('([[:punct:]]+)', ' \\1') %>% 
    str_split(' ') %>%
    unlist()
  x <- trim(x)
  x[x != ""]
}

tokenize_entities <- function(x){
  x <- x %>% 
    tolower %>%
    str_replace_all('([[:punct:]]+)', ' \\1') %>% 
    str_split(',') %>%
    unlist()
  x <- trim(x)
  x[x != ""]
}

# Function definition -----------------------------------------------------
vectorize_stories <- function(data, vocab, textParser_maxlen){
  
  textParsers <- map(data$textOriginal, function(x){
    map_int(x, ~which(.x == vocab))
  })
  
  list(
    new_textParser = pad_sequences(textParsers, maxlen = textParser_maxlen)
  )
}

vectorize_entities <- function(data, vocab, max_len){
  entities <- map(data$entidades, function(x){
    # map_if(is_empty(x), ~ NA_character_) %>%
    map_int(x, ~which(.x == vocab))
  })
  
  list(
    entidades = pad_sequences(entities, maxlen = max_len)
  )
}