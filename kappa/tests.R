theta = 0.5
N = 20
flips1 <- rbinom(n = N, size = 1, prob = theta)
flips2 <- rbinom(n = N, size = 1, prob = theta)
flips3 <- rbinom(n = N, size = 1, prob = theta)
coins<-cbind(flips1, flips2)



#install.packages("irr")
library(irr)
agree(coins, tolerance=0)

kappa2(coins)


Kappa(coins)

