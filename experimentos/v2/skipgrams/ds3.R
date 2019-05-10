library(tools)
source(file_path_as_absolute("ipm/loads.R"))

set.seed(10)
epocas <- c(5)
enriquecimentos <- c(0, 1)
metricas <- c("val_loss")
early_stop <- 1

library("tools")

maxlen <- 38
max_words <- 16615

files <- c("experimentos/v2/skipgrams/core/CNNSKP.R")

fileGetDados <- "experimentos/ds3/getDadosDS3.R"

for (file in files) {
	redeDesc <- "V2_CNNSKPCERTOBowDS3"
	for (epoca in epocas) {
		for (metrica in metricas) {
			for (enriquecimento in enriquecimentos) {
				set.seed(10)
				resultados <- data.frame(matrix(ncol = 4, nrow = 0))
				names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")
				source(file_path_as_absolute(file))
				logar("DS3", "Hidden", "CNN", epoca, 1, metrica, enriquecimento, resultados, model_to_json(model), redeDesc, file)
			}
		}
	}
}

#source(file_path_as_absolute("shutdown.R"))
