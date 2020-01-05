
# library

#https://www.r-graph-gallery.com/boxplot.html

library(ggplot2)
data <- read.csv(file="boxplot/nossosexpsv6.csv", header=TRUE, sep=",")

# grouped boxplot
#ggplot(data, aes(x=algorithm, y=f1_measure, fill=embedding)) +     scale_fill_grey() + theme_classic() +   geom_boxplot() + theme(panel.border = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank(), axis.line = element_line(colour = "black"))


ggplot(data, aes(x=algorithm, y=f1_measure, fill=embedding)) + theme_classic() +   geom_boxplot() + theme(panel.border = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank(), axis.line = element_line(colour = "black")) +scale_fill_brewer(palette="OrRd")


data$embedding

