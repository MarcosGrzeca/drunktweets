library(keras)
library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
dados <- getDados()

#Separação teste e treinamento
set.seed(10)
split=0.80
trainIndex <- createDataPartition(dados$resposta, p=split, list=FALSE)
trainIndex

dados_train <- dados[ trainIndex,]
dados_test <- dados[-trainIndex,]

x_train <- dados_train
x_test <- dados_test
#x_train <- subset(dados_train, select = c(textOriginal))
#y_train <- dados_train$resposta
#labels_train <- as.array(y_train)
#y_test <- dados_test$resposta
#labels_test <- as.array(as.numeric(y_test))

# Transformação para integer
dadosTransformado <- x_train %>%
  mutate(
    textOriginal = map(textOriginal, ~tokenize_words(.x))
  ) %>%
  select(textOriginal)

dadosTransformadoTest <- x_test %>%
  mutate(
    textOriginal = map(textOriginal, ~tokenize_words(.x))
  ) %>%
  select(textOriginal)

all_data <- bind_rows(dadosTransformado, dadosTransformadoTest)
vocab <- c(unlist(dadosTransformado$textOriginal), unlist(dadosTransformadoTest$textOriginal)) %>%
  unique() %>%
  sort()

vocab_size <- length(vocab) + 1
maxlen <- map_int(all_data$textOriginal, ~length(.x)) %>% max()

train_vec <- vectorize_stories(dadosTransformado, vocab, maxlen)

# Data Preparation --------------------------------------------------------s
max_features <- 10000
#maxlen <- 50

# Parameters --------------------------------------------------------------
batch_size <- 32
epochs <- 3
embedding_dims <- 100
filters <- 250
kernel_size <- 3
hidden_dims <- 250

## PRÉ-PROCESSAMENTO
#dadosProcessados <- processarDados(dados_train$textOriginal, maxlen, max_features)

model <- keras_model_sequential()
model %>% 
  # Start off with an efficient embedding layer which maps
  # the vocab indices into embedding_dims dimensions
  #layer_embedding(max_features, embedding_dims, input_length = maxlen) %>%
  layer_embedding(vocab_size, embedding_dims, input_length = maxlen) %>%
  layer_dropout(0.2) %>%
  
  # Add a Convolution1D, which will learn filters
  # Word group filters of size filter_length:
  layer_conv_1d(
    filters, kernel_size, 
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  # Apply max pooling:
  layer_global_max_pooling_1d() %>%
  
  # Add a vanilla hidden layer:
  layer_dense(hidden_dims) %>%
  
  # Apply 20% layer dropout
  layer_dropout(0.2) %>%
  layer_activation("relu") %>%
  
  # Project onto a single unit output layer, and squash it with a sigmoid
  
  layer_dense(1) %>%
  layer_activation("sigmoid")

# Compile model
model %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = "accuracy"
)

# Training ----------------------------------------------------------------
history <- model %>%
  fit(
    dadosProcessados, array(dados_train$resposta),
    batch_size = batch_size,
    epochs = epochs,
    validation_split = 0.2
  )

history