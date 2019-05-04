library(tools)
source(file_path_as_absolute("ipm/loads.R"))

epocas <- c(5)
enriquecimentos <- c(0, 1)
metricas <- c("val_loss")
early_stop <- 1

files <- c("experimentos/ds1/q3/cnn/cnn_random_embeddings_bow_q3.R")

for (file in files) {
	redeDesc <- "CNN_RE_DS1Q3"
	for (epoca in epocas) {
		for (metrica in metricas) {
			for (enriquecimento in enriquecimentos) {
				resultados <- data.frame(matrix(ncol = 4, nrow = 0))
				names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")
				source(file_path_as_absolute(file))
				logar("DS1-Q3", "Hidden", "CNN", epoca, 1, metrica, enriquecimento, resultados, model_to_json(model), redeDesc, file)
			}
		}
	}
}

system("init 0")
