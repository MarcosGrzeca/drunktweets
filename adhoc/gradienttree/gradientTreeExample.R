library(readxl)
library(tidyverse)
library(xgboost)
library(caret)

treinarTree <- function(X_train, y_train) {
	xgbGrid <- expand.grid(nrounds = c(100,200),  # this is n_estimators in the python code above
                       max_depth = c(10, 15, 20, 25),
                       colsample_bytree = seq(0.5, 0.9, length.out = 5),
                       ## The values below are default values in the sklearn-api. 
                       eta = 0.1,
                       gamma=0,
                       min_child_weight = 1,
                       subsample = 1
                      )

	fit <- train(X_train, y_train, 
			method = "xgbTree", 
			tuneGrid = xgbGrid,
			trControl = trainControl(
						method = "cv",
						number = 5,
						savePred = T,
						allowParallel = TRUE,
	  					returnData = FALSE
  					)
			)
	return (fit)
}

getMatriz <- function(fit, data_test) {
  pred <- predict(fit, subset(data_test, select = -c(PE)))
  matriz <- confusionMatrix(data = pred, data_test$PE, positive="1")
  return (matriz)
}

addRow <- function(resultados, baseline, matriz, ...) {
  print(baseline)
  newRes <- data.frame(baseline, matriz$byClass["F1"], matriz$byClass["Precision"], matriz$byClass["Recall"])
  rownames(newRes) <- baseline
  names(newRes) <- c("Baseline", "F1", "Precisão", "Revocação")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")

library(tools)
library(caret)
library(doMC)
library(mlbench)
library(magrittr)

CORES <- 4
registerDoMC(CORES)

set.seed(10)
split=0.80

power_plant = as.data.frame(read_excel("adhoc/gradienttree/Folds5x2_pp.xlsx"))
inTrain <- createDataPartition(y = power_plant$PE, p = split, list = FALSE)
training <- power_plant[inTrain,]
testing <- power_plant[-inTrain,]

X_train = xgb.DMatrix(as.matrix(training %>% select(-PE)))
y_train = training$PE
X_test = xgb.DMatrix(as.matrix(testing %>% select(-PE)))
y_test = testing$PE

treeModel <- treinarTree(X_train, y_train)
treeModel$bestTune
treeModel

pred <- predict(treeModel, X_test)
  matrizTree <- confusionMatrix(data = pred, y_test, positive="1")
resultados <- addRow(resultados, "2 GRAM - Entidades - Erro", matrizTree)

options(repr.plot.width=8, repr.plot.height=4)
my_data = as.data.frame(cbind(predicted = predicted,
                        observed = y_test))
# Plot predictions vs test data
ggplot(my_data,aes(predicted, observed)) + geom_point(color = "darkred", alpha = 0.5) + 
 geom_smooth(method=lm)+ ggtitle('Linear Regression ') + ggtitle("Extreme Gradient Boosting: Prediction vs Test Data") +
  xlab("Predecited Power Output ") + ylab("Observed Power Output") + 
    theme(plot.title = element_text(color="darkgreen",size=16,hjust = 0.5),
     axis.text.y = element_text(size=12), axis.text.x = element_text(size=12,hjust=.5),
         axis.title.x = element_text(size=14), axis.title.y = element_text(size=14))