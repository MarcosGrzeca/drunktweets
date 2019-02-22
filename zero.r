#https://www.r-bloggers.com/near-zero-variance-predictors-should-we-remove-them/

require(caret)
data(GermanCredit)

require(MASS)
xNear = nearZeroVar(GermanCredit, saveMetrics = TRUE)

zeroVariancia <- xNear[xNear[,"zeroVar"] > 0, ]
zeroVariancia

keep <- setdiff(names(GermanCredit), rownames(zeroVariancia))

ncol(GermanCredit)
ncol(GermanCredit[keep])
