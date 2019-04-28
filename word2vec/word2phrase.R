library(devtools)
library(rword2vec)
library(lsa)
library(readr)
library(quanteda)

word2phrase(train_file = "word2vec/alltweets.txt", output_file = "word2vec/phrase_alltweets.txt")

model = word2vec(train_file = "word2vec/phrase_alltweets.txt", output_file = "word2vec/phrase_vec.bin", binary=1)

bin_to_txt("word2vec/phrase_vec.bin", "word2vec/phrase_vec.txt")