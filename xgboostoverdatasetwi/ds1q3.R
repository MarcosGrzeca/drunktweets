library(tools)

try({
  Cores <- 8
  datasetFile <-"ensemble/datasets/exp3/2-Gram-dbpedia-types-enriquecimento-info-q3-not-null_info_entidades.Rda"
  source(file_path_as_absolute("xgboostoverdatasetwi/xcorewi.R"))
  resultados
})