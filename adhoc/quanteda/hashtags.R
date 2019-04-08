library(tools)
library(rword2vec)
library(lsa)
library(readr)
library(quanteda)

library(doMC)
registerDoMC(cores=4)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("utils/resultadoshelper.R"))
source(file_path_as_absolute("utils/getDadosAmazon.R"))
source(file_path_as_absolute("adhoc/quanteda/metrics.R"))

#Configuracoes
DATABASE <- "icwsm"
dados <- getDadosAmazon()

fbcorpus <- corpus(dados$verdade)
fbdfm <- dfm(fbcorpus, verbose=TRUE, remove_punct = TRUE)
fbdfm <- dfm_trim(fbdfm, min_docfreq = 2, verbose=TRUE)
tag_dfm <- dfm_select(tweet_dfm, pattern = ("#*"))
toptag <- names(topfeatures(tag_dfm, 50))

tag_fcm <- fcm(tag_dfm)
head(tag_fcm)

topgat_fcm <- fcm_select(tag_fcm, pattern = toptag)
textplot_network(topgat_fcm, min_freq = 0.1, edge_alpha = 0.8, edge_size = 5)