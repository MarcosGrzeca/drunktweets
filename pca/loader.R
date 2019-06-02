library(tools)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/getDadosAmazon.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
# source(file_path_as_absolute("ipm/glove/load.R"))

#Section: Dados classificar
dados <- getDadosAmazon()

maxlen <- 38
max_words <- 9052

tokenizer <-  text_tokenizer(num_words = max_words) %>%
              fit_text_tokenizer(dados$textEmbedding)

sequences <- texts_to_sequences(tokenizer, dados$textEmbedding)
word_index = tokenizer$word_index

vocab_size <- length(word_index)
vocab_size <- vocab_size + 1
vocab_size

cat("Found", length(word_index), "unique tokens.\n")
data <- pad_sequences(sequences, maxlen = maxlen)

tokenizer_entities <- 	text_tokenizer(num_words = 15) %>%
						fit_text_tokenizer(dados$entidades)
vocabEntitiesLenght <- length(tokenizer_entities$word_index)
dados$sequences <- texts_to_sequences(tokenizer_entities, dados$entidades)

tokenizer_types <- 	text_tokenizer(num_words = 300) %>%
					fit_text_tokenizer(dados$types)
vocabTypesLenght <- length(tokenizer_types$word_index)
dados$sequences_types <- texts_to_sequences(tokenizer_types, dados$types)

max_sequence <- max(sapply(dados$sequences[lengths(dados$sequences) > 0], max))
max_sequence_types <- max(sapply(dados$sequences_types[lengths(dados$sequences_types) > 0], max))

new_entities <- vectorize_sequences(dados$sequences, dimension = max_sequence)
new_types <- vectorize_sequences(dados$sequences_types, dimension = max_sequence_types)

pca_entities <- prcomp(new_entities, scale = FALSE)
#pca_entities$x
pca_types <- prcomp(new_types, scale = FALSE)
#pca_entities$x

library(caret)
library(tools)
library(keras)

##SEPARANDO DADOS
trainIndex <- createDataPartition(dados$resposta, p=0.8, list=FALSE)

# dados_train <- dados[ trainIndex,]
# dados_test <- dados[-trainIndex,]

# train_sequences <- pca_entities$x[ trainIndex,]
# train_sequences_types <- pca_types$x[ trainIndex,]

# test_sequences <- pca_entities$x[-trainIndex,]
# test_sequences_types <- pca_types$x[-trainIndex,]