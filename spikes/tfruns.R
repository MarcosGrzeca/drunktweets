#https://tensorflow.rstudio.com/tools/tfruns/articles/overview.html

library(tfruns)
training_run("modelos/dadosok/spukes/cnn_drunk_sem_flags.R", context = "CNN DRUNK 2")

#Documentação
#https://cran.r-project.org/web/packages/tfruns/tfruns.pdf

# runs <- tuning_run("mnist_mlp.R", flags = list(
#   batch_size = c(64, 128),
#   dropout1 = c(0.2, 0.3, 0.4),
#   dropout2 = c(0.2, 0.3, 0.4)
# ))

#latest_run()

#resultsGeral <- readRDS("results/resultados.rds")