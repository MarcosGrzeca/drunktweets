library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)

tokenize_words <- function(x){
  x <- x %>% 
    str_replace_all('([[:punct:]]+)', ' \\1') %>% 
    str_split(' ') %>%
    unlist()
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