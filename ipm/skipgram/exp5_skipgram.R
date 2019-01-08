library(tools)

fileName <- "ipm/results_q1_glove_sem_kw.Rdata"
source(file_path_as_absolute("ipm/loads.R"))

DESC <- "Exp5 SkipGram- CNN + Semantic Enrichment + Word embeddings"

load(file = "ipm/embeddings/skipgram_glove.Rda")

#Section: Dados classificar
dados <- getDadosChat()

try({
	maxlen <- 38
	max_words <- 40000
	epochs_num <- 3
	source(file_path_as_absolute("ipm/skipgram/ipmtrain_embedding.R"))
})
resultados$F1
resultados$Precision
resultados$Recall
