#FEITO

library(tools)
source(file_path_as_absolute("ipm/loads.R"))

epocas <- c(3,5,10,20)
enriquecimentos <- c(0, 1)
metricas <- c("acc", "val_loss")
early_stop <- 1

filesFeitos <- c()

files <- c("experimentos/early_stop_3_janelas_enriquecimentov_sem_denses_glove.R")

source(file_path_as_absolute("ipm/glove/load.R"))

for (file in files) {
	redeDesc <- generateHash(1)
	for (epoca in epocas) {
		for (metrica in metricas) {
			for (enriquecimento in enriquecimentos) {
				resultados <- data.frame(matrix(ncol = 4, nrow = 0))
				names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")
				source(file_path_as_absolute(file))
				logar("DS3", "GloVe", "CNN", epoca, 1, metrica, enriquecimento, resultados, model_to_json(model), redeDesc)
			}
		}
	}
}

system("init 0")