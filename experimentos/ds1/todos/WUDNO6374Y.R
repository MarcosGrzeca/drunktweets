library(tools)
source(file_path_as_absolute("ipm/loads.R"))
early_stop <- 1

epocas <- c(3,5,10,20)
enriquecimentos <- c(0, 1)
metricas <- c("acc", "val_loss")

files <- c("experimentos/ds1/q1/cnn/WUDNO6374Y.R")

for (file in files) {
	redeDesc <- "WUDNO6374Y-DS1Q1"
	for (epoca in epocas) {
		for (metrica in metricas) {
			for (enriquecimento in enriquecimentos) {
				resultados <- data.frame(matrix(ncol = 4, nrow = 0))
				names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")
				source(file_path_as_absolute(file))
				logar("DS1-Q1", "Hidden", "CNN", epoca, 1, metrica, enriquecimento, resultados, model_to_json(model), redeDesc, file)
			}
		}
	}
}

epocas <- c(3,5,10,20)
enriquecimentos <- c(0, 1)
metricas <- c("acc", "val_loss")

files <- c("experimentos/ds1/q2/cnn/WUDNO6374Y.R")

for (file in files) {
	redeDesc <- "WUDNO6374Y-DS1Q2"
	for (epoca in epocas) {
		for (metrica in metricas) {
			for (enriquecimento in enriquecimentos) {
				resultados <- data.frame(matrix(ncol = 4, nrow = 0))
				names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")
				source(file_path_as_absolute(file))
				logar("DS1-Q2", "Hidden", "CNN", epoca, 1, metrica, enriquecimento, resultados, model_to_json(model), redeDesc, file)
			}
		}
	}
}

epocas <- c(3,5,10,20)
enriquecimentos <- c(0, 1)
metricas <- c("acc", "val_loss")

files <- c("experimentos/ds1/q3/cnn/WUDNO6374Y.R")

for (file in files) {
	redeDesc <- "WUDNO6374Y-DS1Q3"
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
