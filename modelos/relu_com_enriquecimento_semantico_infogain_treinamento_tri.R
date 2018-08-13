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

tokenizertTexto <- text_tokenizer(num_words = 5000) %>%
             fit_text_tokenizer(dados$textOriginal)
vocab_size <- length(tokenizertTexto$word_index)
dados$text_sequence <- texts_to_sequences(tokenizertTexto, dados$textOriginal)

tokenizer <- text_tokenizer(num_words = 1000) %>%
             fit_text_tokenizer(dados$entidades)
vocabEntitiesLenght <- length(tokenizer$word_index)
dados$sequences <- texts_to_sequences(tokenizer, dados$entidades)

tokenizer_types <- text_tokenizer(num_words = 1000) %>%
             fit_text_tokenizer(dados$types)
vocabTypesLenght <- length(tokenizer_types$word_index)
dados$sequences_types <- texts_to_sequences(tokenizer_types, dados$types)

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

text <- vectorize_sequences(dados_train$text_sequence, dimension = vocab_size)

#Vocabulario enttidades
max_sequence <- max(sapply(dados_train$sequences, max))
sequences <- vectorize_sequences(dados_train$sequences, dimension = max_sequence)

max_sequence_types <- max(sapply(dados_train$sequences_types, max))
sequences_types <- vectorize_sequences(dados_train$sequences_types, dimension = max_sequence_types)

main_input <- layer_input(shape = c(vocab_size))
ccn_out <- main_input %>% 
  layer_dense(units = 64, activation = "relu") %>%
  layer_dense(units = 32, activation = "relu") %>%
  layer_activation("relu")

auxiliary_input <- layer_input(shape = c(max_sequence))
entities_out <- auxiliary_input %>%  
                layer_dense(units = 32, activation = 'relu') %>%
                layer_activation("relu")

auxiliary_input_types <- layer_input(shape = c(max_sequence_types))
types_out <- auxiliary_input_types %>%  
                layer_dense(units = 32, activation = 'relu') %>%
                layer_activation("relu")

main_output <- layer_concatenate(c(ccn_out, entities_out, types_out)) %>%  
  layer_dense(units = 64, activation = 'relu') %>% 
  layer_dense(units = 1, activation = 'sigmoid')

model <- keras_model(
  inputs = c(main_input, auxiliary_input, auxiliary_input_types),
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
    x = list(text, sequences, sequences_types),
    y = array(dados_train$resposta),
    batch_size = batch_size,
    epochs = epochs,
    validation_split = 0.2
  )

history

#Generate Test
sequences_text <- vectorize_sequences(dados_test$text_sequence, dimension = vocab_size)
sequences_test <- vectorize_sequences(dados_test$sequences, dimension = max_sequence)
sequences_test_types <- vectorize_sequences(dados_test$sequences_types, dimension = max_sequence_types)

evaluation <- model %>% evaluate(
  list(sequences_text, sequences_test, sequences_test_types),
  array(dados_test$resposta),
  batch_size = batch_size
)
evaluation

predictions <- model %>% predict(list(sequences_text, sequences_test, sequences_test_types))
predictions

predictions2 <- round(predictions, 0)

matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))