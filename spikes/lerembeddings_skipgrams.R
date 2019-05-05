w2v <- readr::read_delim("adhoc/exportembedding/new_skipgrams_10_epocas_5l.txt", 
                         skip=1, delim=" ", quote="",
                         col_names=c("word", paste0("V", 1:100)))

a <- w2v[w2v$word %in% "tequila", 2:101]

embedding_dims <- 100
embedding_matrix <- array(0, c(max_words, embedding_dims))

for (word in names(word_index)) {
  index <- word_index[[word]]
  if (index < max_words) {
  	embedding_vector <- w2v[w2v$word %in% word, 2:101]
    if (!is.null(embedding_vector))
      embedding_matrix[index+1,] <- embedding_vector
  }
}