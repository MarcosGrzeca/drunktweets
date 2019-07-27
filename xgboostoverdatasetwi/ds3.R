library(tools)

try({
  Cores <- 8
  datasetFile <- "amazon/rdas/2gram-entidades-erro.Rda"
  source(file_path_as_absolute("xgboostoverdatasetwi/xcorewi.R"))
  resultados
})