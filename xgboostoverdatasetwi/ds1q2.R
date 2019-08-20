library(tools)

try({
  Cores <- 8
  datasetFile <-"ensembles/ensemble/datasets/exp2/2-Gram-dbpedia-types-enriquecimento-info-q2-not-null_info_entidades.Rda"
  source(file_path_as_absolute("xgboostoverdatasetwi/xcorewi.R"))
  resultados
})