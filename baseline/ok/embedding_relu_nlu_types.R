library(keras)
library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)

#tensorboard("tensorruns")

load("rdas/baseline_embeddings.RData")

# Data Preparation --------------------------------------------------------
# Parameters --------------------------------------------------------------
embedding_dims <- 75
max_features <- 10000

main_input <- layer_input(shape = c(maxlen), dtype = "int32", name="Tweets")
relu <- main_input %>%
  layer_embedding(max_features, embedding_dims, input_length = maxlen, name="WordEmbeddings") %>%
  layer_flatten()


auxiliary_input <- layer_input(shape = c(max_sequence), name="ConceptualFeatures")
entities_out <- auxiliary_input

auxiliary_input_types <- layer_input(shape = c(max_sequence_types), name="SemanticFeatures")
types_out <- auxiliary_input_types

main_output <- layer_concatenate(c(relu, entities_out, types_out)) %>%  
  layer_dense(units = 64, activation = 'relu') %>% 
  #layer_dropout(0.2) %>%
  #layer_dense(units = 32, activation = "relu") %>%
  layer_dense(units = 1, activation = 'sigmoid', name="DrunkTexting")

model <- keras_model(
  inputs = c(main_input, auxiliary_input, auxiliary_input_types),
  outputs = main_output
)

model %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = "accuracy"
)

#, callbacks = callbacks

callbacks = list(
  callback_tensorboard(
    log_dir = "tensorruns/novo3",
    histogram_freq = 1,
    embeddings_freq = 1
  )
)

# Training ----------------------------------------------------------------
history <- model %>%
  fit(
    x = list(train_vec$textEmbedding, train_sequences, train_sequences_types),
    y = array(dados_train$resposta),
    batch_size = 64,
    epochs = 3,
    validation_split = 0.2
  )
#,callbacks = callbacks

# history
predictions <- model %>% predict(list(test_vec$textEmbedding, test_sequences, test_sequences_types))
predictions2 <- round(predictions, 0)

library(caret)
matriz <- confusionMatrix(data = as.factor(predictions2), as.factor(dados_test$resposta), positive="1")
matriz
print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))


model %>% save_model_hdf5("my_model.h5")
