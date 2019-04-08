library(tools)

#https://www.r-bloggers.com/word-vectors-with-tidy-data-principles/

DESC <- "Exp1 GloVe- CNN + Semantic Enrichment + Word embeddings"
source(file_path_as_absolute("ipm/loads.R"))
#Section: Dados classificar
dados <- getDadosBaseline()

#Preparação dos dados
maxlen <- 38
max_words <- 7574

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
embedding_dims <- 100

# Parameters --------------------------------------------------------------
filters <- 200
kernel_size <- 10
hidden_dims <- 200

main_input <- layer_input(shape = c(maxlen), dtype = "int32")
relu <- main_input %>% 
  layer_embedding(vocab_size, embedding_dims, input_length = maxlen, name = "embedding") %>%
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
View(embedding_matrixTwo)

nrow(embedding_matrixTwo)

words <- data_frame(
  word = names(tokenizer$word_index), 
  id = as.integer(unlist(tokenizer$word_index))
)

words <- words %>%
  filter(id <= tokenizer$num_words) %>%
  arrange(id)

row.names(embedding_matrixTwo) <- c("UNK", words$word)

dump(embedding_matrixTwo, "teste.txt")
write.table(embedding_matrixTwo,"teste.txt",sep=" ",row.names=TRUE)


library(text2vec)

find_similar_words <- function(word, embedding_matrix, n = 5) {
  similarities <- embedding_matrix[word, , drop = FALSE] %>%
    sim2(embedding_matrix, y = ., method = "cosine")
  
  similarities[,1] %>% sort(decreasing = TRUE) %>% head(n)
}
find_similar_words("alcohol", embedding_matrixTwo, n = 10)

conj <- c("beer", "alcohol", "vodka", "sober", "drunk", "wine", "food", "men", "women", "eat", "water", "shot", "drink")

conj <- c("drunk", "beer", "wine", "pub", "drink", "photo", "alcohol", "vodka", "getting", "good", "get", "liquor", "last", "tequila", "need", "ipa", "irish", "brew", "whiskey", "dinner", "ciroc", "alcoholic", "turn", "party", "club", "shot", "fucked", "life", "bad", "music", "video", "new", "know", "root", "hope", "hangover", "beverage", "sober", "today", "night", "men", "women", "run")

conj <- c("drunk", "beer", "wine", "pub", "drink", "photo", "alcohol", "vodka", "getting", "good", "get", "liquor", "last", "tequila", "need", "ipa", "irish", "brew", "whiskey", "dinner", "ciroc", "alcoholic", "turn", "party", "club", "shot", "fucked", "bad", "music", "video", "new", "know", "root", "hope", "hangover", "beverage", "sober", "today", "night", "men", "women", "run")

conjunto <- c()
for (word in conj) {
  print(word)
  try({
    if (is.null(embedding_matrixTwo[word, ])) {
      
    }
  })
}

library(cluster) 
#Kmeans(x, centers, iter.max = 10, nstart = 1, method = "euclidean")
df <- embedding_matrixTwo[conj,]
fit <- kmeans(df, 3, iter.max = 1500000)
fviz_cluster(fit, data = df, main="KMeans Glove 3k", geom = "text", ggtheme = theme_minimal())

# Compute PAM
library("cluster")
pam.res <- pam(df, 3)
# Visualize
fviz_cluster(pam.res, main="PAM Glove")

#PCA
library("factoextra")
library("FactoMineR")

res.pca <- PCA(embedding_matrixTwo,  graph = FALSE)
res.pca <- PCA(df,  graph = FALSE)
fviz_pca_ind(res.pca, col.ind = "cos2",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE # Avoid text overlapping (slow if many points)
)


res.dist <- get_dist(df, stand = TRUE, method = "pearson")
fviz_dist(res.dist, 
          gradient = list(low = "#00AFBB", mid = "white", high = "#FC4E07"))
