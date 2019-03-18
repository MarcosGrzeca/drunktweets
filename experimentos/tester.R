library(tools)
source(file_path_as_absolute("ipm/loads.R"))

epocas <- c(3,5,10,20)
enriquecimentos <- c(0, 1)
metricas <- c("acc", "val_loss")
early_stop <- 1

for (epoca in epocas) {
	for (enriquecimento in enriquecimentos) {
		for (metrica in metricas) {
			resultados <- data.frame(matrix(ncol = 4, nrow = 0))
			names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")
			source(file_path_as_absolute("experimentos/early_stop_3_janelas_enriquecimento_droput_reduzido.R")
			logar("DS3", "Hidden", epoca, 1, metrica, enriquecimento, resultados, model_to_json(model))
		}
	}
}