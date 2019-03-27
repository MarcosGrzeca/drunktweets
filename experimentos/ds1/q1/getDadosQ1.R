library("tools")

maxlen <- 38
max_words <- 7574
questionAval <- "q1"

if (bow == 1) {
	source(file_path_as_absolute("experimentos/ds1/sequence_generate_with_bow.R"))
} else {
	source(file_path_as_absolute("experimentos/ds1/sequence_generate.R"))
}