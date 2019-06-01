library(tools)

DESC <- "Exp1 GloVe- CNN + Semantic Enrichment + Word embeddings"
source(file_path_as_absolute("pca/loader.R"))

#PCA
library("factoextra")
library("FactoMineR")


# res.dist <- get_dist(df, stand = TRUE, method = "pearson")
# fviz_dist(res.dist, 
#           gradient = list(low = "#00AFBB", mid = "white", high = "#FC4E07"))

a <- prcomp(train_sequences, scale = FALSE)
a$x

b <- princomp(train_sequences, cor = FALSE, scores = TRUE)
b
b$x

#http://www.sthda.com/english/articles/31-principal-component-methods-in-r-practical-guide/118-principal-component-analysis-in-r-prcomp-vs-princomp/
#https://www.r-bloggers.com/principal-component-analysis-in-r/

library(factoextra)
# Eigenvalues
eig.val <- get_eigenvalue(a)
eig.val

# Results for Variables
res.var <- get_pca_var(pca)
res.var$coord          # Coordinates
res.var$contrib        # Contributions to the PCs
res.var$cos2           # Quality of representation 

res.var$cos2


# Results for individuals
res.ind <- get_pca_ind(pca)
res.ind$coord          # Coordinates
res.ind$contrib        # Contributions to the PCs
res.ind$cos2           # Quality of representation 




View(as.data.frame(res.ind$coord))

res.ind$cos2

#ACESSAR O RESULTADO

# Perform SVD
#https://www.r-bloggers.com/principal-component-analysis-in-r/
mySVD <- svd(train_sequences)
mySVD # the diagonal of Sigma mySVD$d is given as a vector
sigma <- matrix(0,13,13) # we have 4 PCs, no need for a 5th column
diag(sigma) <- mySVD$d # sigma is now our true sigma matrix
sigma

