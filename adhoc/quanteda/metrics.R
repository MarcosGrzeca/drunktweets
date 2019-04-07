## function to compute accuracy
accuracy <- function(ypred, y){
    tab <- table(ypred, y)
    return(sum(diag(tab))/sum(tab))
}
# function to compute precision
precision <- function(ypred, y){
    tab <- table(ypred, y)
    return((tab[2,2])/(tab[2,1]+tab[2,2]))
}
# function to compute recall
recall <- function(ypred, y){
    tab <- table(ypred, y)
    return(tab[2,2]/(tab[1,2]+tab[2,2]))
}