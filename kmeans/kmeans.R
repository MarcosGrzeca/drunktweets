library(tools)

#https://www.r-bloggers.com/word-vectors-with-tidy-data-principles/

DESC <- "Exp1 GloVe- CNN + Semantic Enrichment + Word embeddings"
source(file_path_as_absolute("ipm/loads.R"))
#Section: Dados classificar
dados <- getDadosBaseline()

#Preparação dos dados
maxlen <- 38
max_words <- 7500

tokenizer <-  text_tokenizer(num_words = max_words) %>%
              fit_text_tokenizer(dados$textEmbedding)

sequences <- texts_to_sequences(tokenizer, dados$textEmbedding)
word_index = tokenizer$word_index

vocab_size <- length(word_index)
vocab_size <- vocab_size + 1

cat("Found", length(word_index), "unique tokens.\n")
data <- pad_sequences(sequences, maxlen = maxlen)

tokenizer_entities <- text_tokenizer(num_words = 1000) %>%
  fit_text_tokenizer(dados$entidades)

vocabEntitiesLenght <- length(tokenizer_entities$word_index)
dados$sequences <- texts_to_sequences(tokenizer_entities, dados$entidades)

tokenizer_types <- text_tokenizer(num_words = 1000) %>%
  fit_text_tokenizer(dados$types)
vocabTypesLenght <- length(tokenizer_types$word_index)
dados$sequences_types <- texts_to_sequences(tokenizer_types, dados$types)

library(caret)
trainIndex <- createDataPartition(dados$resposta, p=0.8, list=FALSE)
dados_train <- dados[ trainIndex,]
dados_test <- dados[-trainIndex,]

dados_train_sequence <- data[ trainIndex,]
dados_test_sequence <- data[-trainIndex,]

max_sequence <- max(sapply(dados_train$sequences, max))
max_sequence_types <- max(sapply(dados_train$sequences_types, max))

train_sequences <- vectorize_sequences(dados_train$sequences, dimension = max_sequence)
train_sequences_types <- vectorize_sequences(dados_train$sequences_types, dimension = max_sequence_types)

test_sequences <- vectorize_sequences(dados_test$sequences, dimension = max_sequence)
test_sequences_types <- vectorize_sequences(dados_test$sequences_types, dimension = max_sequence_types)

max_words <- vocab_size
word_index <- tokenizer$word_index

# Data Preparation --------------------------------------------------------
# Parameters --------------------------------------------------------------
embedding_dims <- 75

# Parameters --------------------------------------------------------------
filters <- 200
kernel_size <- 10
hidden_dims <- 200

main_input <- layer_input(shape = c(maxlen), dtype = "int32")
relu <- main_input %>% 
  layer_embedding(vocab_size, embedding_dims, input_length = maxlen) %>%
  layer_dropout(0.1) %>%
  layer_conv_1d(
    filters, kernel_size,
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  layer_global_max_pooling_1d() %>%
  layer_dense(hidden_dims)

auxiliary_input <- layer_input(shape = c(max_sequence))
entities_out <- auxiliary_input

auxiliary_input_types <- layer_input(shape = c(max_sequence_types))
types_out <- auxiliary_input_types

main_output <- layer_concatenate(c(relu, entities_out, types_out)) %>%  
  layer_dense(units = 64, activation = 'relu') %>% 
  layer_dropout(0.2) %>%
  layer_dense(units = 32, activation = "relu") %>%
  layer_dense(units = 1, activation = 'sigmoid')

model <- keras_model(
  inputs = c(main_input, auxiliary_input, auxiliary_input_types),
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
    x = list(dados_train_sequence, train_sequences, train_sequences_types),
    y = array(dados_train$resposta),
    batch_size = 64,
    epochs = 3,
    validation_split = 0.2
  )

# history
predictions <- model %>% predict(list(dados_test_sequence, test_sequences, test_sequences_types))
predictions2 <- round(predictions, 0)

matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
resultados <- addRowAdpater(resultados, DESC, matriz)

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

library(text2vec)

find_similar_words <- function(word, embedding_matrix, n = 5) {
  similarities <- embedding_matrix[word, , drop = FALSE] %>%
    sim2(embedding_matrix, y = ., method = "cosine")
  
  similarities[,1] %>% sort(decreasing = TRUE) %>% head(n)
}
find_similar_words("alcohol", embedding_matrixTwo, n = 10)

conj <- c("beer", "alcohol", "vodka", "sober", "drunk", "wine", "food", "men", "women", "eat", "water", "shot", "drink")

# library(Rtsne) 
# tsne <- Rtsne(embedding_matrixTwo[conj,], perplexity = 2, pca = TRUE)

# tsne_plot <- tsne$Y %>%
#   as.data.frame() %>%
#   mutate(word = row.names(embedding_matrixTwo[conj,])) %>%
#   ggplot(aes(x = V1, y = V2, label = word)) + 
#   geom_text(size = 3)
# tsne_plot

# yum install libxml2-devel
# yum install gcc
if (!require("tidyverse")) {
  install.packages("tidyverse")
}

if (!require("factoextra")) {
  install.packages("factoextra")
}


library(cluster) 
#Kmeans(x, centers, iter.max = 10, nstart = 1, method = "euclidean")
df <- embedding_matrixTwo[conj,]
fit <- kmeans(df, 3)
library(tidyverse)  # data manipulation
library(cluster)    # clustering algorithms
library(factoextra) # clustering algorithms & visualization
distance <- get_dist(df)
fviz_dist(distance, gradient = list(low = "#00AFBB", mid = "white", high = "#FC4E07"))
fviz_pca(fit, data = df)

#png(filename="teste.png")
#fviz_cluster(fit, data = df)
#dev.off()

#dev.print(pdf, 'filename.pdf')



#http://www.sthda.com/english/wiki/factoextra-r-package-easy-multivariate-data-analyses-and-elegant-visualization


library(cluster) 
df <- embedding_matrixTwo[conjunto, ]
fit <- kmeans(df, 4, iter.max = 100)
fviz_cluster(fit, data = df, main = "TD IDF 1000 words Hidden Layers")

library(text2vec)
library(data.table)
library(SnowballC)

setDT(dados)
setkey(dados, id)

it_train = itoken(dados$textEmbedding, 
                  preprocessor = tolower,
                  tokenizer = word_tokenizer,
                  ids = dados$id, 
                  progressbar = TRUE)

vocab_test = create_vocabulary(it_train, stopwords = tm::stopwords("en"))
vocab_test = prune_vocabulary(vocab_test, term_count_min = 10)
vectorizer = vocab_vectorizer(vocab_test)

vectorizer

conjunto <- c()
for (word in mais_importantes$word) {
  try({
    if (!is.null(embedding_matrixTwo[word, ])) {
      if (!(word %in% conjunto)) {
            conjunto <- c(conjunto, word)  
      }
    }
  })
}