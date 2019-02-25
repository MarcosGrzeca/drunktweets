library(tools)

fileName <- "ipm/results_exp6_glove.Rdata"
source(file_path_as_absolute("ipm/loads.R"))
source(file_path_as_absolute("utils/getDadosAmazon.R"))

DESC <- "Exp6 SkipGram- CNN + Semantic Enrichment + Word embeddings"

load(file = "ipm/embeddings/skipgram_glove.Rda")

#Section: Dados classificar
dados <- getDadosAmazon()

try({
	maxlen <- 45
	max_words <- 10000
	epochs_num <- 3
	source(file_path_as_absolute("ipm/skipgram/ipmtrain_embedding.R"))
})
resultados$F1
resultados$Precision
resultados$Recall
