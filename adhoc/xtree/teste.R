#https://www.kaggle.com/nagsdata/simple-r-xgboost-caret-kernel

library(tidyverse)
library(caret)
library(rpart)
library(xgboost)

# loading data
train <- read_csv("adhoc/xtree/planilhas/train.csv")
test <- read_csv("adhoc/xtree/planilhas/test.csv")

# only with numerical data
numvar <- names(train)[which(sapply(train, is.numeric))]
train <- train[,numvar]
numvar_test<-numvar[-length(numvar)]
test <- test[,numvar_test]

# Imputing NA's with median 
train %>% 
  mutate_all(~ifelse(is.na(.), median(., na.rm = TRUE), .)) -> train

test %>% 
  mutate_all(~ifelse(is.na(.), median(., na.rm = TRUE), .)) -> test

## Feature engineering, these columns increases the score
train %>% mutate(year_old = YrSold - YearBuilt, 
                 year_old_reno = YrSold - YearRemodAdd,
                 year_gar = YrSold - GarageYrBlt) -> train

test %>% mutate(year_old = YrSold - YearBuilt, 
                year_old_reno = YrSold - YearRemodAdd,
                year_gar = YrSold - GarageYrBlt) -> test

#Training with xgboost - gives better scores than 'rf'
trctrl <- trainControl(method = "cv", number = 5)

# Takes a long to time to run in kaggle
#tune_grid <- expand.grid(nrounds=c(100,200,300,400), 
#                         max_depth = c(3:7),
#                         eta = c(0.05, 1),
#                         gamma = c(0.01),
#                         colsample_bytree = c(0.75),
#                         subsample = c(0.50),
#                         min_child_weight = c(0))

library(doMC)
registerDoMC(4)

# Tested the above setting in local machine
tune_grid <- expand.grid(nrounds = 200,
                        max_depth = 5,
                        eta = 0.05,
                        gamma = 0.01,
                        colsample_bytree = 0.75,
                        min_child_weight = 0,
                        subsample = 0.5)

rf_fit <- train(SalePrice ~., data = train, method = "xgbTree",
                trControl=trctrl,
                tuneGrid = tune_grid,
                tuneLength = 10)

# have a look at the model 
rf_fit

# Testing
test_predict <- predict(rf_fit, test)

# Preparing to submit
kaggle.submit <- cbind(test$Id,test_predict)
# write.table(kaggle.submit,file="submission1.csv",sep=",",
#             quote=FALSE,col.names=c("Id","SalePrice"),row.names=FALSE)