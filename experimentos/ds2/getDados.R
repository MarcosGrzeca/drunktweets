library("tools")

maxlen <- 38
max_words <- 16615

if (bow == 1) {
	source(file_path_as_absolute("experimentos/ds2/sequence_generate_with_bow.R"))
} else {
	source(file_path_as_absolute("experimentos/ds2/sequence_generate.R"))
}