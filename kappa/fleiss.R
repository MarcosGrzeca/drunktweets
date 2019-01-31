theta = 0.5
N = 20
flips1 <- rbinom(n = N, size = 1, prob = theta)
flips2 <- rbinom(n = N, size = 1, prob = theta)
flips3 <- rbinom(n = N, size = 1, prob = theta)
coins<-cbind(flips1, flips2, flips3)

mydata = read.csv("kappa/kappa_q2_usa.csv")
mydata = read.csv("kappa/kappa_amazon.csv")

library(irr)
kappam.fleiss(mydata, exact = FALSE, detail = FALSE)

agree(mydata)
