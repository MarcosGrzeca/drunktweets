library(tools)
library(rword2vec)
library(lsa)
library(readr)
library(quanteda)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("utils/resultadoshelper.R"))
source(file_path_as_absolute("utils/getDadosAmazon.R"))

#Configuracoes
DATABASE <- "icwsm"
dados <- getDadosAmazon()

fbcorpus <- corpus(dados$textParser)
fbdfm <- dfm(fbcorpus, remove=stopwords("english"), verbose=TRUE)
fbdfm <- dfm_trim(fbdfm, min_docfreq = 2, verbose=TRUE)

w2v <- readr::read_delim("adhoc/quanteda/code/FBvector.txt", 
                  skip=1, delim=" ", quote="",
                  col_names=c("word", paste0("V", 1:100)))

w2v <- w2v[w2v$word %in% featnames(fbdfm),]