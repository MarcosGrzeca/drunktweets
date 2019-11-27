#Geração dos dados

glove_dir = "/var/www/html"

lines <- readLines(file.path(glove_dir, "drunktweets/adhoc/exportembedding/ds1/q1/cnn_10_epocas.txt"))
embeddings_index <- new.env(hash = TRUE, parent = emptyenv())
for (i in 1:length(lines)) {
  line <- lines[[i]]
  values <- strsplit(line, " ")[[1]]
  word <- values[[1]]
  # embeddings_index[[word]] <- as.double(values[-1])
  embeddings_index[word] <- as.double(values[-1])
}
cat("Found", length(embeddings_index), "word vectors.\n")