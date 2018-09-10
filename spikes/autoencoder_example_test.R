#info https://ckbjimmy.github.io/2017_cebu/cebu_workshop2.html

#Adaptar para IMBD https://keras.rstudio.com/articles/examples/imdb_bidirectional_lstm.html

#IMDB to adapter
imdb <- dataset_imdb(num_words = max_features)

# Define training and test sets
x_train <- imdb$train$x
y_train <- imdb$train$y
x_test <- imdb$test$x
y_test <- imdb$test$y



# read the iDASH data
idash <- read.table("idash.txt", sep = "\t", header = FALSE, comment.char="", stringsAsFactors = FALSE)
# store texts to "data"
data <- idash$V1
# store labels to "label"
label <- as.factor(idash$V2)

library(keras)
maxlen <- 200
encoding_dim <- 32
batch_size <- 10
epochs <- 20

tok <- text_tokenizer(2000, lower = TRUE, split = " ", char_level = FALSE)
fit_text_tokenizer(tok, data)
data_idx <- texts_to_sequences(tok, data)

data_idx <- data_idx %>%
  pad_sequences(maxlen = maxlen)

head(data_idx)

inTraining <- 1:floor(nrow(data_idx) * 0.7)
x_train <- data_idx[inTraining, ]
x_test <- data_idx[-inTraining, ]

# initialize the model
model <- keras_model_sequential()

model %>%
  layer_dense(name = 'e1', units = encoding_dim, activation = 'relu', input_shape = maxlen) %>%
  layer_dense(name = 'd1', units = maxlen, activation = 'sigmoid')

model %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam"
)

summary(model)

history <- model %>% fit(
  x_train, x_train,
  batch_size = batch_size,
  epochs = epochs,
  shuffle = TRUE, 
  validation_data = list(x_test, x_test)
)

plot(history)

layer_name <- 'e1'

intermediate_layer_model <- keras_model(inputs = model$input,
                                        outputs = get_layer(model, layer_name)$output)
intermediate_output <- predict(intermediate_layer_model, x_train)
dim(intermediate_output)

colors <- rainbow(length(unique(as.factor(label))))

pca <- princomp(intermediate_output)$scores[, 1:2]
plot(pca, t='n', main="pca")
text(pca, labels=label, col=colors[label])

library(Rtsne)

tsne <- Rtsne(as.matrix(intermediate_output), dims = 2, perplexity = 30, 
              verbose = TRUE, max_iter = 500)

plot(tsne$Y, t='n', main="tsne")
text(tsne$Y, labels=label, col=colors[label])