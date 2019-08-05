library(tools)

imageFile <- "ensemble/resultados/exp2/imageFileBaseline.RData"

datasetFile <-"ensemble/datasets/exp2/3gram-25-q2-v2-not-null.Rda"

baseResultsFiles <- "ensemble/resultados/exp2/"
baseResampleFiles <- "ensemble/resample/exp2/"

fileResults <- "ensemble/resultados/exp2/"

source(file_path_as_absolute("ensemble/run/svmbaseline/core.R"))

TN <- matriz3Gram25NotNull$table[1]
FP <- matriz3Gram25NotNull$table[2]
FN <- matriz3Gram25NotNull$table[3]
TP <- matriz3Gram25NotNull$table[4]

print(paste0("Precision rCaret: ", matriz3Gram25NotNull$byClass["Precision"]))
print(paste0("Precision: ", TP / (TP + FP)))
print(paste0("Recall rCaret: ", matriz3Gram25NotNull$byClass["Recall"]))
print(paste0("Recall: ", TP / (TP + FN)))

resultados
