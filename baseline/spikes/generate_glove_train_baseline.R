library(tools)
library(text2vec)
library(data.table)
library(SnowballC)
library(keras)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

#Section: Dados classificar
dados <- getDadosBaseline()

#Preparação dos dados
maxlen <- 38
max_words <- 10000
tokenizer <-  text_tokenizer(num_words = max_words) %>%
              fit_text_tokenizer(dados$textEmbedding)

sequences <- texts_to_sequences(tokenizer, dados$textEmbedding)
word_index = tokenizer$word_index

#max_words <- length(word_index)

cat("Found", length(word_index), "unique tokens.\n")
data <- pad_sequences(sequences, maxlen = maxlen)

trainIndex <- createDataPartition(dados$resposta, p=0.8, list=FALSE)
dados_train <- dados[ trainIndex,]
dados_test <- dados[-trainIndex,]

dados_train_sequence <- data[ trainIndex,]
dados_test_sequence <- data[-trainIndex,]

#Section: Gerar embeddings
dadosTreinarEmbeddings <- getDadosWordEmbeddings()

tokens <- dadosTreinarEmbeddings$textEmbedding %>% tolower %>% word_tokenizer

# create vocabulary
it = itoken(tokens)
#v <- create_vocabulary(it, stopwords = tm::stopwords("en")) %>% prune_vocabulary(term_count_min = 2)
v <- create_vocabulary(it)

vectorizer <- vocab_vectorizer(v)
#vectorizer = vocab_vectorizer(v, grow_dtm = F, skip_grams_window = 5)

tcm <- create_tcm(it, vectorizer, skip_grams_window = 5L)

embedding_dim <- 100
glove = GlobalVectors$new(word_vectors_size = embedding_dim, vocabulary = v, x_max = 20)
word_vectors_main <- glove$fit_transform(tcm, n_iter = 10)

word_vectors_context = glove$components
word_vectorsSkip = word_vectors_main + t(word_vectors_context)

#Section: Merge
embedding_matrix <- array(0, c(max_words, embedding_dim))
for (word in names(word_index)) {
  index <- word_index[[word]]
  if (index < max_words) {
    #embedding_vector <- word_vectorsSkip[[word]]
    #print(word)
    try({
      #embedding_vector <- word_vectorsSkip[word, , drop = FALSE]
      tryCatch(embedding_vector <- word_vectorsSkip[word, , drop = FALSE], error=function(e) print(word))
      
      if (!is.null(embedding_vector))
        embedding_matrix[index+1,] <- embedding_vector
    })
  }
}

#Section: Classificador
model <- keras_model_sequential() %>%
  layer_embedding(input_dim = max_words, output_dim = embedding_dim, input_length = maxlen) %>%
  layer_flatten() %>%
  layer_dense(units = 64, activation = "relu") %>%
  layer_dropout(rate = 0.2) %>%
  layer_dense(units = 32, activation = "relu") %>%
  layer_dense(units = 1, activation = "sigmoid")

get_layer(model, index = 1) %>%
  set_weights(list(embedding_matrix)) %>%
  freeze_weights()

model %>% compile(
  optimizer = "rmsprop",
  loss = "binary_crossentropy",
  metrics = c("acc")
)

history <- model %>% fit(
  x = dados_train_sequence,
  y = array(dados_train$resposta),
  epochs = 4,
  batch_size = 32,
  validation_split = 0.2
)

# history
predictions <- model %>% predict_classes(list(dados_test_sequence))

matriz <- confusionMatrix(data = as.factor(predictions), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))
