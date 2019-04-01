df <- read.csv("adhoc/nyc-east-river-bicycle-crossings/nyc-east-river-bicycle-counts.csv")
 
df$date <- as.Date(df$Date)
df$weekday <- lubridate::wday(df$date)
df$users <- df$Brooklyn.Bridge
 
df <- df[df$users>0,]
df <- df[!is.na(df$users),]
df <- df[!is.na(df$weekday),]
 
df$ScaledUsers <- scale(df$users)

View(df)

require(keras)
embedding_size <- 3

model <- keras_model_sequential()

model %>% layer_embedding(input_dim = 7+1, output_dim = embedding_size, input_length = 1, name="embedding") %>%
  layer_flatten()  %>%  
  layer_dense(units=40, activation = "relu") %>%  
  layer_dense(units=10, activation = "relu") %>%  
  layer_dense(units=1)

model %>% compile(loss = "mse", optimizer = "sgd", metric="accuracy")

hist <- model %>% fit(x = as.matrix(df$weekday), y= as.matrix(df$ScaledUsers), epochs = 50, batch_size = 2)

layer <- get_layer(model, "embedding")
 
embeddings <- data.frame(layer$get_weights()[[1]])
embeddings$name <- c("none", levels(wday(df$date, label = T)) )
 
ggplot(embeddings, aes(X1, X2, color=name))+ geom_point() +geom_text(aes(label=name),hjust=0, vjust=0) + theme_bw() + xlab("Embedding Dimension 1") +ylab("Embedding Dimension 2")
