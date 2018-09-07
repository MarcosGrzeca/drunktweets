FILE_NAME_RESULTS <- "modelos/layers/results.rds"

library(tfruns)
training_run("modelos/layers/models/cnn_concatenate.R", context = "Concatenate", "run_dir" = "modelos/layers/runs")
training_run("modelos/layers/models/cnn_average.R", context = "Average", "run_dir" = "modelos/layers/runs")
training_run("modelos/layers/models/cnn_multiply.R", context = "Multiply", "run_dir" = "modelos/layers/runs")
training_run("modelos/layers/models/cnn_maximum.R", context = "Maximum", "run_dir" = "modelos/layers/runs")
training_run("modelos/layers/models/cnn_minimum.R", context = "Minimum", "run_dir" = "modelos/layers/runs")
training_run("modelos/layers/models/cnn_subtract.R", context = "Subtract", "run_dir" = "modelos/layers/runs")
