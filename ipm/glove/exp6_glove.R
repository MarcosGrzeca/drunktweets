library(tools)

fileName <- "ipm/results_exp6.Rdata"
source(file_path_as_absolute("ipm/loads.R"))

DESC <- "Exp6 GloVe- CNN + Semantic Enrichment + Word embeddings"

source(file_path_as_absolute("ipm/glove/load.R"))
source(file_path_as_absolute("utils/getDadosAmazon.R"))
source(file_path_as_absolute("utils/getDados.R"))

dados <- getDadosAmazon()

try({
	maxlen <- 45
	max_words <- 15000
	source(file_path_as_absolute("ipm/glove/ipmtrain_embedding.R"))
})
resultados$F1
resultados$Precision
resultados$Recall