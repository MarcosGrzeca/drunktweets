library(cloudml)
gcloud_install()

cloudml_train("modelos/dadosok/cnn_drunk.R", config = "tuning.yml")
