# Create dummy data
variety <- rep( c("soldur", "silur", "lloyd", "pescadou", "X4582", "Dudur", "Classic"), each=40)
treatment <- rep(c(rep("high" , 20) , rep("low" , 20)) , 7)
note <- c( rep(c(sample(0:4, 20 , replace=T) , sample(1:6, 20 , replace=T)),2), 
          rep(c(sample(5:7, 20 , replace=T), sample(5:9, 20 , replace=T)),2), 
          c(sample(0:4, 20 , replace=T) , sample(2:5, 20 , replace=T), 
          rep(c(sample(6:8, 20 , replace=T) , sample(7:10, 20 , replace=T)),2) ))
data=data.frame(variety, treatment ,  note)

View(data)
 
# Reorder varieties (group) (mixing low and high treatments for the calculations)
new_order <- with(data, reorder(variety , note, mean , na.rm=T))

new_order
 
# Then I make the boxplot, asking to use the 2 factors : variety (in the good order) AND treatment :
par(mar=c(3,4,3,1))
myplot <- boxplot(note ~ treatment*new_order , data=data  , 
        boxwex=0.4 , ylab="sickness",
        main="sickness of several wheat lines" , 
        col=c("slateblue1" , "tomato") ,  
        xaxt="n")
 
# To add the label of x axis
my_names <- sapply(strsplit(myplot$names , '\\.') , function(x) x[[2]] )
my_names <- my_names[seq(1 , length(my_names) , 2)]
axis(1, 
     at = seq(1.5 , 14 , 2), 
     labels = my_names , 
     tick=FALSE , cex=0.3)

# Add the grey vertical lines
for(i in seq(0.5 , 20 , 2)){ 
  abline(v=i,lty=1, col="grey")
  }
 
# Add a legend
legend("bottomright", legend = c("High treatment", "Low treatment"), 
       col=c("slateblue1" , "tomato"),
       pch = 15, bty = "n", pt.cex = 3, cex = 1.2,  horiz = F, inset = c(0.1, 0.1))