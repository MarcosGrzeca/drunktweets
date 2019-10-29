#https://www.r-bloggers.com/twitter-sentiment-analysis-with-machine-learning-in-r-using-doc2vec-approach/

library(tools)
library(text2vec)
library(caret)
library(glmnet)
library(ggrepel)

source(file_path_as_absolute("utils/getDadosAmazon.R"))
dados <- getDadosAmazon()

set.seed(10)
trainIndex <- createDataPartition(dados$resposta, p = 0.8, list=FALSE)
tweets_train <- dados[trainIndex, ]
tweets_test <- dados[-trainIndex, ]
 
##### Vectorization #####
# define preprocessing function and tokenization function
prep_fun <- tolower
tok_fun <- word_tokenizer
 
it_train <- itoken(tweets_train$textEmbedding, 
					 preprocessor = prep_fun, 
					 tokenizer = tok_fun,
					 ids = tweets_train$id,
					 progressbar = TRUE)
it_test <- itoken(tweets_test$textEmbedding, 
					 preprocessor = prep_fun, 
					 tokenizer = tok_fun,
					 ids = tweets_test$id,
					 progressbar = TRUE)
 
# creating vocabulary and document-term matrix
vocab <- create_vocabulary(it_train)
vectorizer <- vocab_vectorizer(vocab)
dtm_train <- create_dtm(it_train, vectorizer)
# define tf-idf model
tfidf <- TfIdf$new()
# fit the model to the train data and transform it with the fitted model
dtm_train_tfidf <- fit_transform(dtm_train, tfidf)
# apply pre-trained tf-idf transformation to test data
dtm_test_tfidf  <- create_dtm(it_test, vectorizer) %>% 
      			  transform(tfidf)
 

addRowAdpater <- function(resultados, baseline, matriz, ...) {
  newRes <- data.frame(baseline, matriz$byClass["F1"] * 100, matriz$byClass["Precision"] * 100, matriz$byClass["Recall"] * 100)
  rownames(newRes) <- baseline
  names(newRes) <- c("Baseline", "F1", "Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")

# train the model
t1 <- Sys.time()
glmnet_classifier <- cv.glmnet(x = dtm_train_tfidf,
 y = tweets_train[['resposta']], 
 family = 'binomial', 
 # L1 penalty
 alpha = 1,
 # interested in the area under ROC curve
 type.measure = "auc",
 # 5-fold cross-validation
 nfolds = 5,
 # high value is less accurate, but has faster training
 thresh = 1e-3,
 # again lower number of iterations for faster training
 maxit = 1e3)
print(difftime(Sys.time(), t1, units = 'mins'))
 
plot(glmnet_classifier)
print(paste("max AUC =", round(max(glmnet_classifier$cvm), 4)))
 
preds <- predict(glmnet_classifier, dtm_test_tfidf, type = 'response')[ ,1]
auc(as.numeric(tweets_test$resposta), preds)
 
matriz <- confusionMatrix(data = as.factor(round(preds, 0)), as.factor(tweets_test$resposta), positive="1")
# resultados <- addRowAdpater(resultados, DESC, matriz)
