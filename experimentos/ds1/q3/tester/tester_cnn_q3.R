library(tools)
source(file_path_as_absolute("ipm/loads.R"))

epocas <- c(3,5,10)
enriquecimentos <- c(0, 1)
metricas <- c("acc", "val_loss")
early_stop <- 1

#files <- c("experimentos/ds1/q3/cnn/cnn3janelas_q3.R") redeDesc <- "BAYFB9644C_DS1Q3"
files <- c("experimentos/ds1/q1/cnn/bow_q3.R")

for (file in files) {
	redeDesc <- "BoW_DS1Q3"
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
