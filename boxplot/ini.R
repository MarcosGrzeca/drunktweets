# library
library(ggplot2)
 
# create a data frame
variety=rep(LETTERS[1:7], each=40)
treatment=rep(c("high","low"),each=20)
note=seq(1:280)+sample(1:150, 280, replace=T)
data=data.frame(variety, treatment ,  note)
 
# grouped boxplot
ggplot(data, aes(x=variety, y=note, fill=treatment)) + 
    geom_boxplot()