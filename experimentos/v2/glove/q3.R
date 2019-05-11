library(tools)
source(file_path_as_absolute("ipm/loads.R"))
source(file_path_as_absolute("ipm/glove/load.R"))

set.seed(10)
epocas <- c(5)
enriquecimentos <- c(0, 1)
metricas <- c("val_loss")
early_stop <- 1

library("tools")

maxlen <- 38
max_words <- 3036
questionAval <- "q3"

files <- c("experimentos/v2/glove/core/CNNGlove.R","experimentos/v2/glove/core/CNNGlove.R","experimentos/v2/glove/core/CNNGlove.R","experimentos/v2/glove/core/CNNGlove.R","experimentos/v2/glove/core/CNNGlove.R","experimentos/v2/glove/core/CNNGlove.R")

fileGetDados <- "experimentos/ds1/sequence_generate_with_bow.R"

for (file in files) {
	redeDesc <- "V4_CNNGloveBowDS1-Q3"
	indicador <- as.integer(runif(1, min=10, max=1000))
	redeDesc <- paste0(redeDesc, indicador)

	for (epoca in epocas) {
		for (metrica in metricas) {
			for (enriquecimento in enriquecimentos) {
				set.seed(10)
				resultados <- data.frame(matrix(ncol = 4, nrow = 0))
				names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")
				source(file_path_as_absolute(file))
				logar("DS1-Q3", "GloVe", "CNN", epoca, 1, metrica, enriquecimento, resultados, model_to_json(model), redeDesc, file)
			}
		}
	}
}

#source(file_path_as_absolute("shutdown.R"))
