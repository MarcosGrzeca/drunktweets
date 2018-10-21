library(tools)

fileName <- "ipm/results_q1_glove.Rdata"
source(file_path_as_absolute("ipm/loads.R"))

DESC <- "Exp1 SkipGram- CNN + Semantic Enrichment + Word embeddings"

load(file = "ipm/embeddings/skipgram_glove.Rda")

#Section: Dados classificar
dados <- getDadosBaseline()

try({
	maxlen <- 38
	max_words <- 7400
	epochs_num <- 4
	source(file_path_as_absolute("ipm/skipgram/ipmtrain_embedding.R"))
})
resultados$F1
resultados$Precision
resultados$Recall
