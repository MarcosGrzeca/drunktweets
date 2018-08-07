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

#Entidades Dimension
max_length_dimension <- 5000
sequences <- processarSequence(dados_train$entidades, max_length_dimension)
sequences <- vectorize_sequences(sequences, dimension = max_length_dimension)

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

history <- model %>%
  fit(
    x = list(train_vec$new_textParser, sequences),
    y = array(dados_train$resposta),
    batch_size = batch_size,
    epochs = epochs,
    validation_split = 0.2
  )

#Generate Test
test_vec <- vectorize_stories(dadosTransformadoTest, vocab, maxlen)
max_length_dimension <- 5000
sequences_test <- processarSequence(dados_test$entidades, max_length_dimension)
sequences_test <- vectorize_sequences(sequences_test, dimension = max_length_dimension)

evaluation <- model %>% evaluate(
  list(test_vec$new_textParser, sequences_test),
  array(dados_test$resposta),
  batch_size = batch_size
)
evaluation

#predictions <- model %>% predict(test_vec$new_textParser, type="class")
#predictions <- model %>% predict(test_vec$new_textParser)

predictions <- model %>% predict_classes(test_vec$new_textParser)
results <- model %>% evaluate(x_test, y_test)
print(results)

matriz <- confusionMatrix(data = as.factor(predictions), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))