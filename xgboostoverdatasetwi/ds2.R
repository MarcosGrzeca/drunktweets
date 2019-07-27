library(tools)

try({
  Cores <- 8
  datasetFile <-"chat/rdas/2gram-entidades-erro-sem-key-words_orderbyid.Rda"
  source(file_path_as_absolute("xgboostoverdatasetwi/xcorewi.R"))
  resultados
})