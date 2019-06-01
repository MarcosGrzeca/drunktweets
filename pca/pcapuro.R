library(tools)

DESC <- "Exp1 GloVe- CNN + Semantic Enrichment + Word embeddings"
source(file_path_as_absolute("pca/loader.R"))

#PCA
library("factoextra")
library("FactoMineR")

res.pca <- PCA(embedding_matrixTwo,  graph = FALSE)
res.pca <- PCA(df,  graph = FALSE)
fviz_pca_ind(res.pca, col.ind = "cos2",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE # Avoid text overlapping (slow if many points)
)


res.dist <- get_dist(df, stand = TRUE, method = "pearson")
fviz_dist(res.dist, 
          gradient = list(low = "#00AFBB", mid = "white", high = "#FC4E07"))