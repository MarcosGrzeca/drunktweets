# library

#https://www.r-graph-gallery.com/boxplot.html

library(ggplot2)
data <- read.csv(file="boxplot/nossosexpsv4.csv", header=TRUE, sep=",")
 
# grouped boxplot
ggplot(data, aes(x=algorithm, y=f1_measure, fill=embedding)) + 
    geom_boxplot()



