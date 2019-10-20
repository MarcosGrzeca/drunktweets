#https://blogs.rstudio.com/tensorflow/posts/2019-09-30-bert-r/

Sys.setenv(TF_KERAS=1) 

#python3 -m pip install keras-bert

# pip install keras-bert
# tensorflow::install_tensorflow(version = "1.15")

reticulate::py_module_available('keras_bert')


pretrained_path = '/Users/turgutabdullayev/Downloads/uncased_L-12_H-768_A-12'
config_path = file.path(pretrained_path, 'bert_config.json')
checkpoint_path = file.path(pretrained_path, 'bert_model.ckpt')
vocab_path = file.path(pretrained_path, 'vocab.txt')

library(reticulate)
k_bert = import('keras_bert')
token_dict = k_bert$load_vocabulary(vocab_path)
tokenizer = k_bert$Tokenizer(token_dict)


seq_length = 50L
bch_size = 70
epochs = 1
learning_rate = 1e-4

DATA_COLUMN = 'comment_text'
LABEL_COLUMN = 'target'

model = k_bert$load_trained_model_from_checkpoint(
  config_path,
  checkpoint_path,
  training=T,
  trainable=T,
  seq_len=seq_length)

# tokenize text
tokenize_fun = function(dataset) {
  c(indices, target, segments) %<-% list(list(),list(),list())
  for ( i in 1:nrow(dataset)) {
    c(indices_tok, segments_tok) %<-% tokenizer$encode(dataset[[DATA_COLUMN]][i], 
                                                       max_len=seq_length)
    indices = indices %>% append(list(as.matrix(indices_tok)))
    target = target %>% append(dataset[[LABEL_COLUMN]][i])
    segments = segments %>% append(list(as.matrix(segments_tok)))
  }
  return(list(indices,segments, target))
}
# read data
dt_data = function(dir, rows_to_read){
  data = data.table::fread(dir, nrows=rows_to_read)
  c(x_train, x_segment, y_train) %<-% tokenize_fun(data)
  return(list(x_train, x_segment, y_train))
}

c(x_train,x_segment, y_train) %<-% dt_data('~/Downloads/jigsaw-unintended-bias-in-toxicity-classification/train.csv',2000)

train = do.call(cbind,x_train) %>% t()
segments = do.call(cbind,x_segment) %>% t()
targets = do.call(cbind,y_train) %>% t()

concat = c(list(train ),list(segments))

c(decay_steps, warmup_steps) %<-% k_bert$calc_train_steps(
  targets %>% length(),
  batch_size=bch_size,
  epochs=epochs
)

library(keras)

input_1 = get_layer(model,name = 'Input-Token')$input
input_2 = get_layer(model,name = 'Input-Segment')$input
inputs = list(input_1,input_2)

dense = get_layer(model,name = 'NSP-Dense')$output

outputs = dense %>% layer_dense(units=1L, activation='sigmoid',
                         kernel_initializer=initializer_truncated_normal(stddev = 0.02),
                         name = 'output')

model = keras_model(inputs = inputs,outputs = outputs)

model %>% compile(
  k_bert$AdamWarmup(decay_steps=decay_steps, 
                    warmup_steps=warmup_steps, lr=learning_rate),
  loss = 'binary_crossentropy',
  metrics = 'accuracy'
)

model %>% fit(
  concat,
  targets,
  epochs=epochs,
  batch_size=bch_size, validation_split=0.2)