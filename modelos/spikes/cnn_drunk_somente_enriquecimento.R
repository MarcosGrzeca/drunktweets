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

# Texto
dadosTransformado <- dados_train %>%
  mutate(
    textOriginal = map(textOriginal, ~tokenize_words(.x)),
    entidades = map(entidades, ~tokenize_entities(.x))
  ) %>%
  select(textOriginal, entidades)

dadosTransformadoTest <- dados_test %>%
  mutate(
    textOriginal = map(textOriginal, ~tokenize_words(.x)),
    entidades = map(entidades, ~tokenize_entities(.x))
  ) %>%
  select(textOriginal, entidades)

all_data <- bind_rows(dadosTransformado, dadosTransformadoTest)

#Vocabulario enttidades
vocabEntidades <- c(unlist(dadosTransformado$entidades), unlist(dadosTransformadoTest$entidades)) %>%
  unique() %>%
  sort()

maxlen_entidades <- map_int(all_data$entidades, ~length(.x)) %>% max()
sequences <- vectorize_entities(dadosTransformado, vocabEntidades, maxlen_entidades)

# Data Preparation --------------------------------------------------------
# Parameters --------------------------------------------------------------
batch_size <- 128
epochs <- 3
embedding_dims <- 100
filters <- 250
kernel_size <- 3
hidden_dims <- 250


auxiliary_input <- layer_input(shape = c(maxlen_entidades))
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
    x = sequences$entidades,
    y = array(dados_train$resposta),
    batch_size = batch_size,
    epochs = epochs,
    validation_split = 0.2
  )

history

#Generate Test
sequences_test <- vectorize_entities(dadosTransformadoTest, vocabEntidades, maxlen_entidades)

evaluation <- model %>% evaluate(
  sequences_test$entidades,
  array(dados_test$resposta),
  batch_size = batch_size
)
evaluation

predictions <- model %>% predict(sequences_test$entidades)
predictions

predictions2 <- round(predictions, 0)

matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))

#load(file="rdas/treinamento_teste.RData")

#[1] "F1  9.80735551663748 Precisao  53.5031847133758 Recall  5.39845758354756 Acuracia  70.5770329461055"