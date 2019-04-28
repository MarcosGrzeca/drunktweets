library(devtools)
library(rword2vec)

model = word2vec(train_file = "word2vec/alltweets.txt",output_file = "word2vec/vec.bin", binary=1)

# gsub("[\r\n]", "", x)


# library(stringr)
# str_replace_all(x, "[\r\n]" , "")

dist=distance(file_name = "word2vec/vec.bin",search_word = "beer",num = 20)