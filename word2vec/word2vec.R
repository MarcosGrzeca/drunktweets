library(devtools)
library(rword2vec)

model=word2vec(train_file = "text8",output_file = "word2vec/vec.bin", binary=1)