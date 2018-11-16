library(randomForest)
library(mlbench)
library(caret)
library(e1071)
 
# Load Dataset
data(Sonar)
dataset <- Sonar
x <- dataset[,1:60]
y <- dataset[,61]

#10 folds repeat 3 times
control <- trainControl(method='repeatedcv', 
                        number=10, 
                        repeats=3)
#Metric compare model is Accuracy
metric <- "Accuracy"
set.seed(123)
#Number randomely variable selected is mtry
mtry <- sqrt(ncol(x))
mtry

tunegrid <- expand.grid(.mtry=mtry)
rf_default <- train(Class~., 
                      data=dataset, 
                      method='rf', 
                      metric='Accuracy', 
                      tuneGrid=tunegrid, 
                      trControl=control)
print(rf_default)

mtry <- sqrt(ncol(x))
#ntree: Number of trees to grow.
ntree <- 3

#Random generate 15 mtry values with tuneLength = 15
set.seed(1)
rf_random <- train(Class ~ .,
                   data = dataset,
                   method = 'rf',
                   metric = 'Accuracy',
                   tuneLength  = 15, 
                   trControl = control)
print(rf_random)