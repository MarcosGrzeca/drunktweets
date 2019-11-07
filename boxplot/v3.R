# library

#https://www.r-graph-gallery.com/boxplot.html

library(ggplot2)
data <- read.csv(file="boxplot/nossosexpsv2.csv", header=TRUE, sep=",")
 
# grouped boxplot
ggplot(data, aes(x=algorithm, y=note, fill=treatment)) + 
    geom_boxplot()


