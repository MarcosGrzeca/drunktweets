#Geração dos dados

if (get_os() == "linux") {
	glove_dir = "/var/www/html/drunktweets"
} else {
	glove_dir = "/var/www/html/drunktweets"
}

lines <- readLines(file.path(glove_dir, "word2vec_tokens.txt"))
embeddings_index <- new.env(hash = TRUE, parent = emptyenv())
for (i in 1:length(lines)) {
  line <- lines[[i]]
  values <- strsplit(line, " ")[[1]]
  word <- values[[1]]
  embeddings_index[[word]] <- as.double(values[-1])
}
cat("Found", length(embeddings_index), "word vectors.\n")