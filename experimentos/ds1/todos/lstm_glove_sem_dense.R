library(tools)
source(file_path_as_absolute("ipm/loads.R"))
source(file_path_as_absolute("ipm/glove/load.R"))
early_stop <- 1

epocas <- c(3,5,10,20)
enriquecimentos <- c(0, 1)
metricas <- c("acc", "val_loss")

files <- c("experimentos/ds1/q1/lstm/lstm_glove_sem_dense.R")

for (file in files) {
	redeDesc <- "TTVYS0458Y-DS1Q1"
	for (epoca in epocas) {
		for (metrica in metricas) {
			for (enriquecimento in enriquecimentos) {
				resultados <- data.frame(matrix(ncol = 4, nrow = 0))
				names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")
				source(file_path_as_absolute(file))
				logar("DS1-Q1", "GloVe", "LSTM", epoca, 1, metrica, enriquecimento, resultados, model_to_json(model), redeDesc, file)
			}
		}
	}
}

epocas <- c(3,5,10,20)
enriquecimentos <- c(0, 1)
metricas <- c("acc", "val_loss")

files <- c("experimentos/ds1/q2/lstm/lstm_glove_sem_dense.R")

for (file in files) {
	redeDesc <- "TTVYS0458Y-DS1Q2"
	for (epoca in epocas) {
		for (metrica in metricas) {
			for (enriquecimento in enriquecimentos) {
				resultados <- data.frame(matrix(ncol = 4, nrow = 0))
				names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")
				source(file_path_as_absolute(file))
				logar("DS1-Q2", "GloVe", "LSTM", epoca, 1, metrica, enriquecimento, resultados, model_to_json(model), redeDesc, file)
			}
		}
	}
}

epocas <- c(3,5,10,20)
enriquecimentos <- c(0, 1)
metricas <- c("acc", "val_loss")

files <- c("experimentos/ds1/q3/lstm/lstm_glove_sem_dense.R")

for (file in files) {
	redeDesc <- "TTVYS0458Y-DS1Q3"
	for (epoca in epocas) {
		for (metrica in metricas) {
			for (enriquecimento in enriquecimentos) {
				resultados <- data.frame(matrix(ncol = 4, nrow = 0))
				names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")
				source(file_path_as_absolute(file))
				logar("DS1-Q3", "GloVe", "LSTM", epoca, 1, metrica, enriquecimento, resultados, model_to_json(model), redeDesc, file)
			}
		}
	}
}

system("init 0")
