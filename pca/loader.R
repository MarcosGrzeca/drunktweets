library(tools)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/getDadosAmazon.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
# source(file_path_as_absolute("ipm/glove/load.R"))

#Section: Dados classificar
dados <- getDadosAmazon()

save <- 1
maxlen <- 38
max_words <- 9052

tokenizer_entities <- 	text_tokenizer(num_words = 1002) %>%
						fit_text_tokenizer(dados$entidades)
vocabEntitiesLenght <- length(tokenizer_entities$word_index)
dados$sequences <- texts_to_sequences(tokenizer_entities, dados$entidades)

tokenizer_types <- 	text_tokenizer(num_words = 200) %>%
					fit_text_tokenizer(dados$types)
vocabTypesLenght <- length(tokenizer_types$word_index)
dados$sequences_types <- texts_to_sequences(tokenizer_types, dados$types)

library(caret)
library(tools)
library(keras)

trainIndex <- createDataPartition(dados$resposta, p=0.8, list=FALSE)

dados_train <- dados[ trainIndex,]
dados_test <- dados[-trainIndex,]

max_sequence <- max(sapply(dados_train$sequences[lengths(dados_train$sequences) > 0], max))
max_sequence_types <- max(sapply(dados_train$sequences_types[lengths(dados_train$sequences_types) > 0], max))

train_sequences <- vectorize_sequences(dados_train$sequences, dimension = max_sequence)
train_sequences_types <- vectorize_sequences(dados_train$sequences_types, dimension = max_sequence_types)

test_sequences <- vectorize_sequences(dados_test$sequences, dimension = max_sequence)
test_sequences_types <- vectorize_sequences(dados_test$sequences_types, dimension = max_sequence_types)

tokenizerBow <- text_tokenizer(num_words = max_words) %>%
		fit_text_tokenizer(dados$textParser)

dataframebow_train <- texts_to_matrix(tokenizerBow, dados_train$textParser, mode = "binary")
dataframebow_test  <- texts_to_matrix(tokenizerBow, dados_test$textParser,  mode = "binary")