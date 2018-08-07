library(keras)
library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)

source(file_path_as_absolute("redesneurais/getDados.R"))

# Data Preparation --------------------------------------------------------s
max_features <- 5000

dados <- getDados()

labelsTmp <- as.numeric(dados$resposta)
labels <- as.array(labelsTmp)

training_samples <- 3195
validation_samples <- 799

indices <- sample(1:nrow(dados))
training_indices <- indices[1:training_samples]
validation_indices <- indices[(training_samples + 1):
                                (training_samples + validation_samples)]

x_train <- dados[training_indices,]
y_train <- labels[training_indices]
x_test <- dados[validation_indices,]
y_test <- labels[validation_indices]

maxlen <- 39

dados <- processarDados(x_train$textParser, maxlen, max_features)

sequences <- processarSequence(x_train$entidades, entidades_maxlen, max_features)
sequences <- vectorize_sequences(sequences, dimension = 5000)

# Parameters --------------------------------------------------------------
batch_size <- 16
epochs <- 3
embedding_dims <- 50
filters <- 250
kernel_size <- 3
hidden_dims <- 250

main_input <- layer_input(shape = c(39), dtype = "int32")

ccn_out <- main_input %>% 
  # Start off with an efficient embedding layer which maps
  # the vocab indices into embedding_dims dimensions
  layer_embedding(max_features, embedding_dims, input_length = maxlen) %>%
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
  layer_activation("relu")
  
  # Project onto a single unit output layer, and squash it with a sigmoid
  
  # %>%layer_dense(1) %>%
  # layer_activation("sigmoid")

auxiliary_input <- layer_input(shape = c(5000))

main_output <- layer_concatenate(c(ccn_out, auxiliary_input)) %>%  
  layer_dense(units = 64, activation = 'relu') %>% 
  layer_dense(units = 1, activation = 'sigmoid')

model <- keras_model(
  inputs = c(main_input, auxiliary_input),
  outputs = main_output
)

# Compile model
model %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = "accuracy"
)

# Training ----------------------------------------------------------------

history <- model %>%
  fit(
    x = list(dados, sequences),
    y = y_train,
    batch_size = batch_size,
    epochs = epochs,
    validation_split = 0.2
  )
