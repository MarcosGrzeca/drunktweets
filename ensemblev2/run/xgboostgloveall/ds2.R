library(tools)

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

baseResultsFiles <- "ensemblev2/resultados/ds2/"
baseResampleFiles <- "ensemblev2/resample/ds2/"
embeddingFile <- "word2vec/embeddings.txt"

dados <- getDadosChat()

try({
	source(file_path_as_absolute("ensemblev2/run/xgboostgloveall/xgboost_core.R"))
	#source(file_path_as_absolute("ensemblev2/git.R"))
})
