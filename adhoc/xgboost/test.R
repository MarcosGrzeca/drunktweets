#https://cran.rstudio.com/web/packages/xgboost/vignettes/discoverYourData.html

require(xgboost)
require(Matrix)
require(data.table)
if (!require('vcd')) install.packages('vcd')

data(Arthritis)
df <- data.table(Arthritis, keep.rownames = F)

head(df[,AgeDiscret := as.factor(round(Age/10,0))])

df[,ID:=NULL]

View(df)


sparse_matrix <- sparse.model.matrix(Improved ~ ., data = df)[,-1]
head(sparse_matrix)

sparse_matrix

View(sparse_matrix)

output_vector = df[,Improved] == "Marked"

output_vector


bst <- xgboost(data = sparse_matrix, label = output_vector, max_depth = 4,
               eta = 1, nthread = 2, nrounds = 10,objective = "binary:logistic")

importance <- xgb.importance(feature_names = colnames(sparse_matrix), model = bst)
head(importance)

importanceRaw <- xgb.importance(feature_names = colnames(sparse_matrix), model = bst, data = sparse_matrix, label = output_vector)

importanceClean <- importanceRaw[,`:=`(Cover=NULL, Frequency=NULL)]

head(importanceClean)

xgb.plot.importance(importance_matrix = importance)
