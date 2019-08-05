library(tools)

imageFile <- "ensemble/resultados/exp5/imageFileBaseline.RData"

datasetFile <-"chat/rdas/3gram-25-new.Rda"

baseResultsFiles <- "ensemble/resultados/exp5/"
baseResampleFiles <- "ensemble/resample/exp5/"

fileResults <- "ensemble/resultados/exp5/"

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
