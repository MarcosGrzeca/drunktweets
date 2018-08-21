library(cloudml)
gcloud_install()

cloudml_train("modelos/dadosok/cnn_drunk.R", config = "modelos/dadosok/tuning.yml")
cloudml_train("modelos/dadosok/cnn_drunk.R")
