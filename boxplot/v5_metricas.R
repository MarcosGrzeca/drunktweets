# library

#https://www.r-graph-gallery.com/boxplot.html

library(dplyr)
data <- read.csv(file="boxplot/nossosexpsv6a.csv", header=TRUE, sep=",")

algoritmo <- "XGBoost"
summary(data %>% filter(algorithm == algoritmo) %>% filter(embedding == "F Drunk2Vec"))
summary(data %>% filter(algorithm == algoritmo) %>% filter(embedding == "E LSTM"))
summary(data %>% filter(algorithm == algoritmo) %>% filter(embedding == "D Skipgram-non-static"))
summary(data %>% filter(algorithm == algoritmo) %>% filter(embedding == "C GloVe-non-static"))
summary(data %>% filter(algorithm == algoritmo) %>% filter(embedding == "B GloVe-static"))
summary(data %>% filter(algorithm == algoritmo) %>% filter(embedding == "A Skipgram-static"))
