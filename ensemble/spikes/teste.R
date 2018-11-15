library(tools)
library(caret)

data_test <- read.csv(file="ensemble/planilhas/resposta.csv", header=TRUE, sep=",")

svm <- read.csv(file="ensemble/planilhas/svm.csv", header=TRUE, sep=",")
network <- read.csv(file="ensemble/planilhas/network.csv", header=TRUE, sep=",")
rf <- read.csv(file="ensemble/planilhas/rf.csv", header=TRUE, sep=",")

library(dplyr)

bigDataFrame <- bind_cols(list(svm, network, rf)) 
bigDataFrameSum <- rowSums(bigDataFrame)

result <- bigDataFrameSum / 3
pred <- round(result,0)
pred

matriz <- confusionMatrix(data = as.factor(pred), as.factor(data_test$resposta), positive="1")
matriz

# add rownames as a column in each data.frame and bind rows
# result <- bind_rows(svm %>% add_rownames(), 
#           network %>% add_rownames(),
#           rf %>% add_rownames()) %>% 
#     # evaluate following calls for each value in the rowname column
#     group_by(rowname) %>% 
#     # add all non-grouping variables
#     summarise_all(sum)