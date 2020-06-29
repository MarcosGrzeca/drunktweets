library(ggplot2)
data <- read.csv(file="boxplot/resultadoexp2v3.csv", header=TRUE, sep=";")

#data$classifier <- as.factor(data$classifier)
#data$classifier <-factor(data$classifier,levels=levels(data$classifier)[c(1,2,3,4,5,6,7)])
data$classifier <-factor(data$classifier,levels=levels(data$classifier)[c(2,3,1,4,7,5,6)])

ggplot(data, aes(fill=classifier, y=f1_measure, x=dataset)) + 
  geom_bar(position="dodge", stat="identity") + theme_classic() + theme(panel.border = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank(), axis.line = element_line(colour = "black")) + scale_fill_brewer(palette="OrRd")

ggplot(data, aes(fill=classifier, y=f1_measure, x=dataset)) + 
  geom_bar(position="dodge", stat="identity") + theme_classic() + theme(panel.border = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank(), axis.line = element_line(colour = "black")) + scale_fill_grey(start = 0.9, end = 0.1) 

ggplot(data, aes(fill=classifier, y=f1_measure, x=dataset)) + 
  geom_bar(position="dodge", stat="identity") + theme_classic() + theme(panel.border = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank(), axis.line = element_line(colour = "black")) + scale_fill_brewer(palette="Blues")

ggplot(data, aes(fill=classifier, y=f1_measure, x=dataset)) + 
  geom_bar(position="dodge", stat="identity") + theme_classic() + theme(panel.border = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank(), axis.line = element_line(colour = "black")) + scale_fill_grey(start = 0.9, end = 0.1) 

ggplot(data, aes(fill=classifier, y=f1_measure, x=dataset)) + 
  geom_bar(position="dodge", stat="identity") + theme_classic() + theme(panel.border = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank(), axis.line = element_line(colour = "black")) + scale_fill_brewer(palette="BuPu")

ggplot(data, aes(fill=classifier, y=f1_measure, x=dataset)) + 
  geom_bar(position="dodge", stat="identity") + theme_classic() + theme(panel.border = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank(), axis.line = element_line(colour = "black")) + scale_fill_brewer(palette="PuBu")

ggplot(data, aes(fill=classifier, y=f1_measure, x=dataset)) + 
  geom_bar(position="dodge", stat="identity") + theme_classic() + theme(panel.border = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank(), axis.line = element_line(colour = "black")) + scale_fill_brewer(palette="Greys")

ggplot(data, aes(fill=classifier, y=f1_measure, x=dataset)) + 
  geom_bar(position="dodge", stat="identity") + theme_classic() + theme(panel.border = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank(), axis.line = element_line(colour = "black")) + scale_fill_brewer(palette="YlGn")

ggplot(data, aes(fill=classifier, y=f1_measure, x=dataset)) + 
  geom_bar(position="dodge", stat="identity") + theme_classic() + theme(panel.border = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank(), axis.line = element_line(colour = "black")) + scale_fill_brewer(palette="Purples")

ggplot(data, aes(fill=classifier, y=f1_measure, x=dataset)) + 
  geom_bar(position="dodge", stat="identity") + theme_classic() + theme(panel.border = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank(), axis.line = element_line(colour = "black")) + scale_fill_brewer(palette="Reds")

#http://rstudio-pubs-static.s3.amazonaws.com/5312_98fc1aba2d5740dd849a5ab797cc2c8d.html

#devtools::install_github("clauswilke/ggtextures")
