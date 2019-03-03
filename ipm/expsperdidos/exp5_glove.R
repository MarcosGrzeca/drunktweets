library(tools)

fileName <- "ipm/results_q1_glove_sem_kw.Rdata"
source(file_path_as_absolute("ipm/loads.R"))

expName <- "Exp5"

source(file_path_as_absolute("ipm/glove/load.R"))
source(file_path_as_absolute("utils/getDados.R"))

#Section: Dados classificar
dados <- getDadosChat()

try({
	enriquecimento <- 1
	maxlen <- 50
	max_words <- 40000
	source(file_path_as_absolute("ipm/expsperdidos/ipmtrain_embedding.R"))
})
resultados$F1
resultados$Precision
resultados$Recall