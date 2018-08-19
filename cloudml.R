#https://tensorflow.rstudio.com/tools/tfruns/articles/overview.html

library(cloudml)
install_gcloud()
cloudml_train("modelos/cnn_drunk_com_enriquecimento_semantico_infogain_treinamento_tri.R")

# Train on a GPU instance
#cloudml_train("mnist_mlp.R", master_type = "standard_gpu")
# Train on an NVIDIA Tesla P100 GPU
#cloudml_train("mnist_mlp.R", master_type = "standard_p100")