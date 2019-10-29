library(tools)
library(tm)

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

dados <- getDadosBaselineByQ("q1")
dados$textEmbedding <- removePunctuation(dados$textEmbedding)

trainIndex <- createDataPartition(dados$resposta, p=0.8, list=FALSE)
dados_train <- dados[ trainIndex,]

maxlen <- 38
max_words <- 7860

tokenizer <-  text_tokenizer(num_words = max_words) %>%
              fit_text_tokenizer(trainIndex)

sequences <- texts_to_sequences(tokenizer, trainIndex)
word_index = tokenizer$word_index

set.seed(10)
vocab_size <- length(word_index)
vocab_size <- vocab_size + 1
vocab_size

cat("Found", length(word_index), "unique tokens.\n")
data <- pad_sequences(sequences, maxlen = maxlen)

library(caret)
trainIndex <- createDataPartition(dados$resposta, p=0.8, list=FALSE)
dados_train <- dados[ trainIndex,]
dados_test <- dados[-trainIndex,]

dados_train_sequence <- data[ trainIndex,]
dados_test_sequence <- data[-trainIndex,]

max_words <- vocab_size
word_index <- tokenizer$word_index

# Data Preparation --------------------------------------------------------
# Parameters --------------------------------------------------------------
embedding_dims <- 100

# Parameters --------------------------------------------------------------
filters <- 164

main_input <- layer_input(shape = c(maxlen), dtype = "int32")

embedding_input <- 	main_input %>% 
                    layer_embedding(input_dim = vocab_size, output_dim = embedding_dims, input_length = maxlen, name = "embedding")

ccn_out_3 <- embedding_input %>% 
  layer_conv_1d(
    filters, 3,
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  layer_global_max_pooling_1d()

ccn_out_4 <- embedding_input %>% 
  layer_conv_1d(
    filters, 4, 
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  layer_global_max_pooling_1d()

ccn_out_5 <- embedding_input %>% 
  layer_conv_1d(
    filters, 5, 
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  layer_global_max_pooling_1d()

main_output <- layer_concatenate(c(ccn_out_3, ccn_out_4, ccn_out_5)) %>% 
  layer_dropout(0.2) %>%
  layer_dense(units = 8, activation = "relu") %>%
  layer_dense(units = 1, activation = 'sigmoid')


model <- keras_model(
  inputs = c(main_input),
  outputs = main_output
)

model %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = "accuracy"
)

library(keras)
# Training ----------------------------------------------------------------        
history <- model %>%
  fit(
    x = list(dados_train_sequence),
    y = array(dados_train$resposta),
    batch_size = 64,
    epochs = 10,
    #callbacks = callbacks_list,
    validation_split = 0.2
  )

# predictions <- model %>% predict(list(dados_test_sequence))
# predictions2 <- round(predictions, 0
# matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
# resultados <- addRowAdpater(resultados, DESC, matriz)

##
library(dplyr)

embedding_matrixTwo <- get_weights(model)[[1]]
words <- data_frame(
  word = names(tokenizer$word_index), 
  id = as.integer(unlist(tokenizer$word_index))
)

words <- words %>%
  filter(id <= tokenizer$num_words) %>%
  arrange(id)

row.names(embedding_matrixTwo) <- c("UNK", words$word)

embedding_file <- "testecompleto/q1/cnn_10_epocas.txt"
write.table(embedding_matrixTwo, embedding_file, sep=" ",row.names=TRUE)
system(paste0("sed -i 's/\"//g' ", embedding_file))

#Configuracoes
DATABASE <- "icwsm"
dados <- getDadosBaselineByQ("q1")

fbcorpus <- corpus(dados$textEmbedding)
fbdfm <- dfm(fbcorpus, remove=stopwords("english"), verbose=TRUE, remove_punct = TRUE)
#fbdfm <- dfm_trim(fbdfm, min_docfreq = 2, verbose=TRUE)

dados$entidades = gsub(",", " ", dados$entidades)
entidades <- corpus(dados$entidades)
entidadesdfm <- dfm(entidades, verbose=TRUE)

dados$types = gsub(",", " ", dados$types)
types <- corpus(dados$types)
typesdfm <- dfm(types, verbose=TRUE)

#dfm(x, verbose = TRUE, toLower = TRUE,
#    removeNumbers = TRUE, removePunct = TRUE, removeSeparators = TRUE,
#    removeTwitter = FALSE, stem = FALSE, ignoredFeatures = NULL,
#    keptFeatures = NULL, language = "english", thesaurus = NULL,
#    dictionary = NULL, valuetype = c("glob", "regex", "fixed"), ..


#w2v <- readr::read_delim("adhoc/exportembedding/ds1/q2/cnn_10_epocas.txt", 
# w2v <- readr::read_delim("adhoc/exportembedding/ds3/cnn_10_epocas.txt", 
w2v <- readr::read_delim(embedding_file, 
                  skip=1, delim=" ", quote="",
                  col_names=c("word", paste0("V", 1:100)))

w2v <- w2v[w2v$word %in% featnames(fbdfm),]

# creating new feature matrix for embeddings
embed <- matrix(NA, nrow=ndoc(fbdfm), ncol=100)
for (i in 1:ndoc(fbdfm)){
  if (i %% 100 == 0) message(i, '/', ndoc(fbdfm))
  # extract word counts
  vec <- as.numeric(fbdfm[i,])
  # keep words with counts of 1 or more
  doc_words <- featnames(fbdfm)[vec>0]
  # extract embeddings for those words
  embed_vec <- w2v[w2v$word %in% doc_words, 2:101]
  # aggregate from word- to document-level embeddings by taking AVG
  embed[i,] <- colMeans(embed_vec, na.rm=TRUE)
  # if no words in embeddings, simply set to 0
  if (nrow(embed_vec)==0) embed[i,] <- 0
}

set.seed(10)
library(xgboost)

#Com enriquecimento

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Name", "Precision", "Recall")

addRowSimple <- function(resultados, rowName, precision, recall) {
  newRes <- data.frame(rowName, precision, recall)
  rownames(newRes) <- rowName
  names(newRes) <- c("Name", "Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

for (iteracao in 1:1) {
  training <- sample(1:nrow(dados), floor(.80 * nrow(dados)))
  test <- (1:nrow(dados))[1:nrow(dados) %in% training == FALSE]
  
  # converting matrix object
  # X <- as(cbind(embed,typesdfm,entidadesdfm), "dgCMatrix")
  X <- as(embed, "dgCMatrix")
  
  # parameters to explore
  tryEta <- c(1,2,3)
  tryDepths <- c(1,2,4,6)
  # placeholders for now
  bestEta=NA
  bestDepth=NA
  bestAcc=0
  
  for(eta in tryEta){
    for(dp in tryDepths){ 
      bst <- xgb.cv(data = X[training,], 
                    label =  dados$resposta[training], 
                    max.depth = dp,
                    eta = eta, 
                    nthread = Cores,
                    nround = 500,
                    nfold=5,
                    print_every_n = 500L,
                    objective = "binary:logistic")
      # cross-validated accuracy
      acc <- 1-mean(tail(bst$evaluation_log$test_error_mean))
      if(acc>bestAcc){
        bestEta=eta
        bestAcc=acc
        bestDepth=dp
      }
    }
  }
  
  # running best model
  rf <- xgboost(data = X[training,], 
                label = dados$resposta[training], 
                max.depth = bestDepth,
                eta = bestEta, 
                nthread = Cores,
                nround = 500,
                print_every_n=500L,
                objective = "binary:logistic")
  
  # out-of-sample accuracy
  preds <- predict(rf, X[test,])
  resultados <- addRowSimple(resultados, "Sem", round(precision(preds>.50, dados$resposta[test]) * 100,6), round(recall(preds>.50, dados$resposta[test]) * 100,6))
  
  X <- as(cbind(embed, typesdfm, entidadesdfm), "dgCMatrix")
  
  # parameters to explore
  tryEta <- c(1,2,3)
  tryDepths <- c(1,2,4,6)
  # placeholders for now
  bestEta=NA
  bestDepth=NA
  bestAcc=0
  
  for(eta in tryEta){
    for(dp in tryDepths){ 
      bst <- xgb.cv(data = X[training,], 
                    label =  dados$resposta[training], 
                    max.depth = dp,
                    eta = eta, 
                    nthread = Cores,
                    nround = 500,
                    nfold=5,
                    print_every_n = 500L,
                    objective = "binary:logistic")
      # cross-validated accuracy
      acc <- 1-mean(tail(bst$evaluation_log$test_error_mean))
      if(acc>bestAcc){
        bestEta=eta
        bestAcc=acc
        bestDepth=dp
      }
    }
  }
  
  # running best model
  rf <- xgboost(data = X[training,], 
                label = dados$resposta[training], 
                max.depth = bestDepth,
                eta = bestEta, 
                nthread = Cores,
                nround = 500,
                print_every_n=500L,
                objective = "binary:logistic")
  
  # out-of-sample accuracy
  preds <- predict(rf, X[test,])
  resultados <- addRowSimple(resultados, "Com", round(precision(preds>.50, dados$resposta[test]) * 100,6), round(recall(preds>.50, dados$resposta[test]) * 100,6))
  cat("Iteracao = ",iteracao, "\n",sep="")
  View(resultados)
}