library(cloudml)
gcloud_install()

cloudml_train("modelos/dadosok/cnn_drunk.R", config = "modelos/dadosok/tuning.yml")
cloudml_train("modelos/dadosok/cnn_drunk.R")
cloudml_train("modelos/dadosok/spukes/cnn_drunk_sem_flags.R")
