library(keras)
library(tools)
library(caret)

load("/var/www/html/drunktweets/spikes/doc2vec/ds3_doc2_sum.Rda")

set.seed(10)
split=0.80

enriquecimento <- 0

addRowAdpater <- function(resultados, baseline, matriz, ...) {
  newRes <- data.frame(baseline, matriz$byClass["F1"] * 100, matriz$byClass["Precision"] * 100, matriz$byClass["Recall"] * 100)
  rownames(newRes) <- baseline
  names(newRes) <- c("Baseline", "F1", "Precision", "Recall")
  newdf <- rbind(resultados, newRes)
  return (newdf)
}

resultados <- data.frame(matrix(ncol = 4, nrow = 0))
names(resultados) <- c("Baseline", "F1", "Precisão", "Revocação")

for (i in 1:10) {
  
  inTrain <- createDataPartition(y = X[, ncol(X)], p = split, list = FALSE)
  
  tam <- 100
  entidades <- ncol(X) - 1 - tam
  entidades
  # tam <- 103
  one_hot_train <- X[inTrain, 1:tam]
  entidades_train <- X[inTrain, (tam+1):(tam+entidades)]
  resposta <-  X[inTrain, ncol(X)]
  
  one_hot_test <- X[-inTrain, 1:tam]
  entidades_test <- X[-inTrain, (tam+1):(tam+entidades)]
  resposta_test <-  X[-inTrain, ncol(X)]
  
  #MODEL --------------------------------------------------------------
  
  main_input <- layer_input(shape = c(tam))
  modelPrincipal <- main_input %>%
    layer_dense(units = 128, activation = "relu", input_shape = c(tam)) %>%
    layer_dropout(0.2) %>%
    layer_dense(units = 64, activation = "relu")
  
  entidade_input <- layer_input(shape = c(entidades))
  modelEntidades <- entidade_input %>%
    layer_dense(units = 32, activation = "relu", input_shape = c(entidades)) %>%
    layer_dropout(0.2) %>%
    layer_dense(units = 16, activation = "relu")
  

  if (enriquecimento == 1) {
    main_output <- layer_concatenate(c(modelPrincipal,modelEntidades)) %>%  
      layer_dense(units = 32, activation = "relu") %>%
      layer_dense(units = 1, activation = 'sigmoid')
    
    model <- keras_model(
      inputs = c(main_input, entidade_input),
      outputs = main_output
    )
  } else {
    main_output <- modelPrincipal %>%  
      layer_dense(units = 32, activation = "relu") %>%
      layer_dense(units = 1, activation = 'sigmoid')
    
    model <- keras_model(
      inputs = main_input,
      outputs = main_output
    )
  }
  
  model %>% compile(
    loss = "binary_crossentropy",
    optimizer = "adam",
    metrics = "accuracy"
  )
  
  # Training ----------------------------------------------------------------
  if (enriquecimento == 1) {
    entrada <- list(one_hot_train,entidades_train)
  } else {
    entrada <- one_hot_train
  }
  history <- model %>%
    fit(
      x = entrada,
      y = array(resposta),
      batch_size = 64,
      epochs = 5,
      validation_split = 0.2
    )
  
  history
  

  if (enriquecimento == 1) {
    predictions <- model %>% predict(list(one_hot_test, entidades_test))
  } else {
    predictions <- model %>% predict(one_hot_test)
  }
  predictions <- round(predictions, 0)
  matriz <- confusionMatrix(data = as.factor(predictions), as.factor(resposta_test), positive="1")
  
  resultados <- addRowAdpater(resultados, "MARCOS", matriz)
  View(resultados)
}
resultados
mean(resultados$F1)
mean(resultados$Precision)
mean(resultados$Recall)