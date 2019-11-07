data <- read.csv(file="boxplot/nossosexpsv4.csv", header=TRUE, sep=",")
 
# Reorder varieties (group) (mixing low and high embeddings for the calculations)
new_order <- with(data, reorder(algorithm , f1_measure, mean , na.rm=T))
 
# Then I make the boxplot, asking to use the 2 factors : algorithm (in the good order) AND embedding :
par(mar=c(3,4,3,1))
myplot <- boxplot(f1_measure ~ embedding*new_order , data=data  , 
        boxwex=0.4 , ylab="sickness",
        main="sickness of several wheat lines" , 
        col=c("slateblue1" , "tomato") ,  
        xaxt="n")
 
# To add the label of x axis
my_names <- sapply(strsplit(myplot$names , '\\.') , function(x) x[[2]] )
my_names <- my_names[seq(1 , length(my_names) , 6)]
axis(1, 
     at = seq(1.5 , 14 , 2), 
     labels = my_names , 
     tick=FALSE , cex=0.3)

my_names

# Add the grey vertical lines
for(i in seq(0.5 , 20 , 2)){ 
  abline(v=i,lty=1, col="grey")
  }
 
Add a legend
legend("bottomright", legend = c("High embedding", "Low embedding"), 
        col=c("slateblue1" , "tomato"),
        pch = 15, bty = "n", pt.cex = 3, cex = 1.2,  horiz = F, inset = c(0.1, 0.1))
