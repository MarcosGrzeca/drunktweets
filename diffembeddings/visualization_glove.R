library(tools)

# source(file_path_as_absolute("ipm/glove/load.R"))
source(file_path_as_absolute("diffembeddings/load.R"))

library(text2vec)

find_similar_words <- function(word, embedding_matrix, n = 5) {
  similarities <- embedding_matrix[word, , drop = FALSE] %>%
    sim2(embedding_matrix, y = ., method = "cosine")
  
  similarities[,1] %>% sort(decreasing = TRUE) %>% head(n)
}
find_similar_words("beer", embeddings_index, n = 20)

library(ggplot2)
library(dplyr)
library(tibble)
library(broom)

search_synonyms <- function(word_vectors, selected_vector) {
  
  similarities <- word_vectors %*% selected_vector %>%
    tidy() %>%
    as_tibble() %>%
    rename(token = .rownames,
           similarity = unrowname.x.)
  
  similarities %>%
    arrange(-similarity)    
}

#beer <- search_synonyms(embedding_matrixTwo, embedding_matrixTwo["beer",])
#alcohol <- search_synonyms(embedding_matrixTwo, embedding_matrixTwo["alcohol",])
#drunk <- search_synonyms(embedding_matrixTwo, embedding_matrixTwo["drunk",])
#sober <- search_synonyms(embedding_matrixTwo, embedding_matrixTwo["sober",])

# beer <- convertSimilaridadeToTibble(find_similar_words("beer", embedding_matrixTwo, n = 15))
# alcohol <- convertSimilaridadeToTibble(find_similar_words("alcohol", embedding_matrixTwo, n = 15))
# drunk <- convertSimilaridadeToTibble(find_similar_words("drunk", embedding_matrixTwo, n = 15))
# sober <- convertSimilaridadeToTibble(find_similar_words("sober", embedding_matrixTwo, n = 15))

# beer %>%
#   mutate(selected = "beer") %>%
#   bind_rows(alcohol %>%
#               mutate(selected = "alcohol")) %>%
#   bind_rows(drunk %>%
#               mutate(selected = "drunk")) %>%
#   bind_rows(sober %>%
#               mutate(selected = "sober")) %>%
#   group_by(selected) %>%
#   top_n(15, similarity) %>%
#   ungroup %>%
#   mutate(token = reorder(token, similarity)) %>%
#   ggplot(aes(token, similarity, fill = selected)) +
#   geom_col(show.legend = FALSE) +
#   facet_wrap(~selected, scales = "free") +
#   coord_flip() +
#   theme(strip.text=element_text(hjust=0, size=12)) +
#   scale_y_continuous(expand = c(0,0))
