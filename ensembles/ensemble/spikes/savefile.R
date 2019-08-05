set.seed(10)
split=0.80
load(file = "rdas/3gram-25-baseline.Rda")
maFinal$resposta <- as.factor(maFinal$resposta)

for (year in 1:10){
  trainIndex <- createDataPartition(maFinal$resposta, p=split, list=FALSE)
  path <- paste0("split/resuts", year, ".csv")
  write.csv(trainIndex, file = path,row.names=FALSE)
}
