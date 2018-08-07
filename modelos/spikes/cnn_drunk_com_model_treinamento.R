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

library(doMC)
library(mlbench)

CORES <- 4
registerDoMC(CORES)

#Separação teste e treinamento
set.seed(10)
split=0.80
trainIndex <- createDataPartition(dados$resposta, p=split, list=FALSE)
trainIndex

dados_train <- dados[ trainIndex,]
dados_test <- dados[-trainIndex,]

# Transformação para integer
dadosTransformado <- dados_train %>%
  mutate(
    textOriginal = map(textOriginal, ~tokenize_words(.x))
  ) %>%
  select(textOriginal)

dadosTransformadoTest <- dados_test %>%
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

# Data Preparation --------------------------------------------------------
# Parameters --------------------------------------------------------------
batch_size <- 32
epochs <- 3
embedding_dims <- 100
filters <- 250
kernel_size <- 3
hidden_dims <- 250

main_input <- layer_input(shape = c(maxlen), dtype = "int32")
ccn_out <- main_input %>% 
  layer_embedding(vocab_size, embedding_dims, input_length = maxlen) %>%
  layer_dropout(0.2) %>%
  layer_conv_1d(
    filters, kernel_size, 
    padding = "valid", activation = "relu", strides = 1
  ) %>%
  layer_global_max_pooling_1d() %>%
  layer_dense(hidden_dims) %>%
  layer_dropout(0.2) %>%
  layer_activation("relu")

main_output <- ccn_out %>%  
  layer_dense(units = 64, activation = 'relu') %>% 
  layer_dense(units = 1, activation = 'sigmoid')

model <- keras_model(
  inputs = main_input,
  outputs = main_output
)

model %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = "accuracy"
)

history <- model %>%
  fit(
    x = train_vec$new_textParser,
    y = array(dados_train$resposta),
    batch_size = batch_size,
    epochs = epochs,
    validation_split = 0.2
  )

old <- function() {

  # OLD 
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
      train_vec$new_textParser, array(dados_train$resposta),
      batch_size = batch_size,
      epochs = epochs,
      validation_split = 0.2
    )
}