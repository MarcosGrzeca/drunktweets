library(tools)
source(file_path_as_absolute("ipm/loads.R"))
source(file_path_as_absolute("ipm/glove/load.R"))

epocas <- c(3,5,10)
enriquecimentos <- c(0, 1)
metricas <- c("acc", "val_loss")
early_stop <- 1

files <- c("experimentos/ds3/lstm/bidirectional/glove_sem_dense.R")

for (file in files) {
	redeDesc <- "TTVYS0458Y_SEM_DENSE"
	for (epoca in epocas) {
		for (metrica in metricas) {
			for (enriquecimento in enriquecimentos) {
				resultados <- data.frame(matrix(ncol = 4, nrow = 0))
				names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")
				source(file_path_as_absolute(file))
				logar("DS3", "GloVe", "LSTM", epoca, 1, metrica, enriquecimento, resultados, model_to_json(model), redeDesc, file)
			}
		}
	}
}

system("init 0")
