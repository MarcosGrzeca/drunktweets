library(keras)
library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
dados <- getDadosInfoGain()

tokenizer <- text_tokenizer(num_words = 1000) %>%
             fit_text_tokenizer(dados$entidades)
vocabEntitiesLenght <- length(tokenizer$word_index)
# Turns strings into lists of integer indices
dados$sequences <- texts_to_sequences(tokenizer, dados$entidades)

#nrow(dados[dados$resposta == 0,])
#nrow(dados[dados$resposta == 1,])

library(doMC)
library(mlbench)

CORES <- 4
registerDoMC(CORES)

#Separação teste e treinamento
set.seed(10)
split=0.80

trainIndex <- createDataPartition(dados$resposta, p=split, list=FALSE)

dados_train <- dados[ trainIndex,]
dados_test <- dados[-trainIndex,]

max_sequence <- max(sapply(dados_train$sequences, max))
sequences <- vectorize_sequences(dados_train$sequences, dimension = max_sequence)

# Data Preparation --------------------------------------------------------
# Parameters --------------------------------------------------------------
batch_size <- 128
epochs <- 3
embedding_dims <- 100
filters <- 250
kernel_size <- 3
hidden_dims <- 250


# auxiliary_input <- layer_input(shape = c(maxlen_entidades))
auxiliary_input <- layer_input(shape = c(max_sequence))
entities_out <- auxiliary_input %>%
                layer_activation("relu")

main_output <- entities_out %>%  
  layer_dense(units = 32, activation = 'relu') %>% 
  layer_dense(units = 1, activation = 'sigmoid')

model <- keras_model(
  inputs = auxiliary_input,
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
    x = sequences,
    y = array(dados_train$resposta),
    batch_size = batch_size,
    epochs = epochs,
    validation_split = 0.2
  )

history

#Generate Test
sequences_test <- vectorize_sequences(dados_test$sequences, dimension = max_sequence)

evaluation <- model %>% evaluate(
  sequences_test,
  array(dados_test$resposta),
  batch_size = batch_size
)
evaluation

predictions <- model %>% predict(sequences_test)
predictions

predictions2 <- round(predictions, 0)

matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))

#[1] "F1  68.3210784313726 Precisao  65.2810304449649 Recall  71.6580976863753 Acuracia  80.3085126642544"