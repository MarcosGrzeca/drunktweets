library(tools)

imageFile <- "ensemble/resultados/exp2/imageFileRede.RData"

baseResultsFiles <- "ensemble/resultados/exp2/"
baseResampleFiles <- "ensemble/resample/exp2/"

fileResults <- "ensemble/resultados/exp2/"

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("ipm/glove/load.R"))

#Section: Dados classificar

imageFile <- "kk"
dados <- getDadosBaselineByQ("q2")

try({
	maxlen <- 38
	max_words <- 5000
	save <- 0
	source(file_path_as_absolute("ensemble/run/networkglove/ipmtrain_embedding_sem_enriquecimento.R"))
})
resultados$F1
resultados$Precision
resultados$Recall