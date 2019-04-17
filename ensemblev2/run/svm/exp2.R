library(tools)

try({
	datasetFile <-"ensemblev2/datasets/exp2/2-Gram-dbpedia-types-enriquecimento-info-q2-not-null_info_entidades.Rda"
	baseResultsFiles <- "ensemblev2/resultados/exp2/"
	baseResampleFiles <- "ensemblev2/resample/exp2/"
	source(file_path_as_absolute("ensemblev2/run/svm/core.R"))
	source(file_path_as_absolute("ensemblev2/git.R"))
}