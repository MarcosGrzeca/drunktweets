library(tools)
source(file_path_as_absolute("ipm/loads.R"))

epocas <- c(3,5,10,20)
enriquecimentos <- c(0, 1)
metricas <- c("acc", "val_loss")
early_stop <- 1

filesFeitos <- c("experimentos/early_stop_3_janelas_enriquecimento_droput_reduzido.R")

files <- c("experimentos/early_stop_3_janelas_enriquecimento_droput_reduzido.R", "experimentos/early_stop_3_janelas_enriquecimento_droput_reduzido_outra.R", "experimentos/early_stop_3_janelas_enriquecimentov_sem_denses.R")

for (file in files) {
	redeDesc <- generateHash()
	for (epoca in epocas) {
		for (metrica in metricas) {
			for (enriquecimento in enriquecimentos) {
				resultados <- data.frame(matrix(ncol = 4, nrow = 0))
				names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")
				source(file_path_as_absolute(file))
				logar("DS3", "Hidden", epoca, 1, metrica, enriquecimento, resultados, model_to_json(model), redeDesc)
			}
		}
	}
}
