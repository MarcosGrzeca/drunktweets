# library

#https://www.r-graph-gallery.com/boxplot.html

library(ggplot2)
data <- read.csv(file="boxplot/nossosexps.csv", header=TRUE, sep=",")
 
# grouped boxplot
ggplot(data, aes(x=dataset, y=note, fill=treatment)) + 
    geom_boxplot()


