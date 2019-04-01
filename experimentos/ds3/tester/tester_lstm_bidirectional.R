library(tools)
source(file_path_as_absolute("ipm/loads.R"))

epocas <- c(3,5,10,20)
enriquecimentos <- c(0, 1)
metricas <- c("acc", "val_loss")
early_stop <- 1

files <- c("experimentos/lstm/bidirectional/teste1.R")
# files <- c("experimentos/lstm/bidirectional/teste2.R")
# files <- c("experimentos/lstm/bidirectional/teste3.R")

for (file in files) {
	redeDesc <- "LSTM_BI_TESTE1"
	for (epoca in epocas) {
		for (metrica in metricas) {
			for (enriquecimento in enriquecimentos) {
				resultados <- data.frame(matrix(ncol = 4, nrow = 0))
				names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")
				source(file_path_as_absolute(file))
				logar("DS3", "Hidden", "LSTM", epoca, 1, metrica, enriquecimento, resultados, model_to_json(model), redeDesc, file)
			}
		}
	}
}

system("init 0")
