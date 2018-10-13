library(tools)

fileName <- "ipm/results_q2.Rdata"
source(file_path_as_absolute("ipm/loads.R"))

DESC <- "Exp2 - CNN + Semantic Enrichment + Word embeddings"

for (year in 1:10){
  try({
    load("rdas/baseline_embeddings_q2.RData")
    source(file_path_as_absolute("ipm/ipmtrain.R"))
  })
}
resultados$F1
resultados$Precision
resultados$Recall
