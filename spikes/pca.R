data(iris)
head(iris, 3)

# log transform 
log.ir <- log(iris[, 1:4])
ir.species <- iris[, 5]
 
# apply PCA - scale. = TRUE is highly 
# advisable, but default is FALSE. 
ir.pca <- prcomp(log.ir,
                 center = TRUE,
                 scale. = TRUE) 


print(ir.pca)
plot(ir.pca, type = "l")
summary(ir.pca)

predict(ir.pca, 
        newdata=tail(log.ir, 2))


require(caret)
trans = preProcess(iris[,1:4], 
                   method=c("BoxCox", "center", 
                            "scale", "pca"))
PC = predict(trans, iris[,1:4])
head(PC, 3)

trans$rotation

