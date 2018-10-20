#Geração dos dados

if (get_os() == "linux") {
	glove_dir = "/var/www/html/glove/glove.twitter.27B"
} else {
	glove_dir = "C:/wamp64/www/drunktweets/glove/glove.twitter.27B"
}

lines <- readLines(file.path(glove_dir, "glove.twitter.27B.100d.txt"))
embeddings_index <- new.env(hash = TRUE, parent = emptyenv())
for (i in 1:length(lines)) {
  line <- lines[[i]]
  values <- strsplit(line, " ")[[1]]
  word <- values[[1]]
  embeddings_index[[word]] <- as.double(values[-1])
}
cat("Found", length(embeddings_index), "word vectors.\n")