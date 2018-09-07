FILE_NAME_RESULTS <- "modelos/layers/results.rds"

library(tfruns)
training_run("modelos/layers/models/cnn_concatenate.R", context = "Concatenate", "run_dir" = "modelos/layers/runs")
