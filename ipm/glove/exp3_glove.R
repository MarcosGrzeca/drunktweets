library(tools)

fileName <- "ipm/results_q1_glove.Rdata"
source(file_path_as_absolute("ipm/loads.R"))

DESC <- "Exp1 GloVe- CNN + Semantic Enrichment + Word embeddings"

source(file_path_as_absolute("ipm/glove/load.R"))

#Section: Dados classificar
dados <- getDadosBaseline()

try({
	source(file_path_as_absolute("ipm/glove/ipmtrain_embedding.R"))
	})
resultados$F1
resultados$Precision
resultados$Recall