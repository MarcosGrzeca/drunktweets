library(tools)
source(file_path_as_absolute("ipm/loads.R"))
source(file_path_as_absolute("ipm/glove/load.R"))

epocas <- c(3,5,10,20)
enriquecimentos <- c(0,1)
metricas <- c("acc", "val_loss")
early_stop <- 1

files <- c("experimentos/ds3/cnnlstm/dupla_glove")

for (file in files) {
	redeDesc <- "CNNLSTMGlove"
	for (epoca in epocas) {
		for (metrica in metricas) {
			for (enriquecimento in enriquecimentos) {
				resultados <- data.frame(matrix(ncol = 4, nrow = 0))
				names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")
				source(file_path_as_absolute(file))
				logar("DS3", "GloVe", "CNN", epoca, 1, metrica, enriquecimento, resultados, model_to_json(model), redeDesc, file)
			}
		}
	}
}

system("init 0")

