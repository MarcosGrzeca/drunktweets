library(tools)
source(file_path_as_absolute("utils/getDadosAmazon.R"))
source(file_path_as_absolute("utils/getDados.R"))

dados <- getDadosAmazon()
 
maxlen <- 40
max_words <- 9052

tokenizer <-  text_tokenizer(num_words = max_words) %>%
              fit_text_tokenizer(dados$textEmbedding)

sequences <- texts_to_sequences(tokenizer, dados$textEmbedding)
word_index = tokenizer$word_index

vocab_size <- length(word_index)
vocab_size <- vocab_size + 1

cat("Found", length(word_index), "unique tokens.\n")
data <- pad_sequences(sequences, maxlen = maxlen)

tokenizer_entities <- text_tokenizer(num_words = 100) %>%
  fit_text_tokenizer(dados$entidades)

vocabEntitiesLenght <- length(tokenizer_entities$word_index)
dados$sequences <- texts_to_sequences(tokenizer_entities, dados$entidades)

tokenizer_types <- text_tokenizer(num_words = 200) %>%
  fit_text_tokenizer(dados$types)
vocabTypesLenght <- length(tokenizer_types$word_index)
dados$sequences_types <- texts_to_sequences(tokenizer_types, dados$types)

library(caret)
trainIndex <- createDataPartition(as.factor(dados$resposta), p=0.8, list=FALSE)
dados_train <- dados[ trainIndex,]
dados_test <- dados[-trainIndex,]

dados_train_sequence <- data[ trainIndex,]
dados_test_sequence <- data[-trainIndex,]

max_sequence <- max(sapply(dados_train$sequences, max))
max_sequence_types <- max(sapply(dados_train$sequences_types, max))

sequences <- vectorize_sequences(dados_train$sequences, dimension = max_sequence)
sequences_types <- vectorize_sequences(dados_train$sequences_types, dimension = max_sequence_types)

sequences_test <- vectorize_sequences(dados_test$sequences, dimension = max_sequence)
sequences_test_types <- vectorize_sequences(dados_test$sequences_types, dimension = max_sequence_types)

#Text parser BoW
tokenizerBow <- text_tokenizer(num_words = max_words) %>%
  fit_text_tokenizer(dados$textParser)

dataframebow_train <- texts_to_matrix(tokenizerBow, dados_train$textParser, mode = "binary")
dataframebow_test  <- texts_to_matrix(tokenizerBow, dados_test$textParser,  mode = "binary")

max_words <- vocab_size
word_index <- tokenizer$word_index