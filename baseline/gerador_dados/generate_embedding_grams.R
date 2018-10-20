library(readr)
library(stringr)
library(purrr)
library(tibble)
library(dplyr)
library(tools)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
vectorize_local <- function(data, vocab, textParser_maxlen){
  
  textEmbedding <- map(data$textEmbedding, function(x){
    map_int(x, ~which(.x == vocab))
  })
  
  list(
    textEmbedding = pad_sequences(textEmbedding, maxlen = textParser_maxlen)
  )
}
dados <- getDadosBaseline()

tokenizer <- text_tokenizer(num_words = 1000) %>%
             fit_text_tokenizer(dados$entidades)
vocabEntitiesLenght <- length(tokenizer$word_index)
dados$sequences <- texts_to_sequences(tokenizer, dados$entidades)

tokenizer_types <- text_tokenizer(num_words = 1000) %>%
             fit_text_tokenizer(dados$types)
vocabTypesLenght <- length(tokenizer_types$word_index)
dados$sequences_types <- texts_to_sequences(tokenizer_types, dados$types)

#Separação teste e treinamento
set.seed(10)
split=0.80

trainIndex <- createDataPartition(dados$resposta, p=split, list=FALSE)

dados_train <- dados[ trainIndex,]
dados_test <- dados[-trainIndex,]

# Texto
dadosTransformado <- dados_train %>%
  mutate(
    textEmbedding = map(textEmbedding, ~tokenize_words(.x))
  ) %>%
  select(textEmbedding)

dadosTransformadoTest <- dados_test %>%
  mutate(
    textEmbedding = map(textEmbedding, ~tokenize_words(.x))
  ) %>%
  select(textEmbedding)

all_data <- bind_rows(dadosTransformado, dadosTransformadoTest)

#Vocabulario texto
vocab <- c(unlist(dadosTransformado$textEmbedding), unlist(dadosTransformadoTest$textEmbedding)) %>%
  unique() %>%
  sort()

vocab_size <- length(vocab) + 1
maxlen <- map_int(all_data$textEmbedding, ~length(.x)) %>% max()

train_vec <- vectorize_local(dadosTransformado, vocab, maxlen)
test_vec <- vectorize_local(dadosTransformadoTest, vocab, maxlen)

max_sequence <- max(sapply(dados_train$sequences, max))
max_sequence_types <- max(sapply(dados_train$sequences_types, max))

train_sequences <- vectorize_sequences(dados_train$sequences, dimension = max_sequence)
train_sequences_types <- vectorize_sequences(dados_train$sequences_types, dimension = max_sequence_types)

test_sequences <- vectorize_sequences(dados_test$sequences, dimension = max_sequence)
test_sequences_types <- vectorize_sequences(dados_test$sequences_types, dimension = max_sequence_types)

#Gerar Grams
# library(text2vec)
# library(data.table)
# library(SnowballC)

# setDT(dados)
# setkey(dados, id)

# dados$textParser = gsub("'", "", dados$textParser)
# it_train = itoken(dados$textParser, 
#                   preprocessor = tolower,
#                   tokenizer = word_tokenizer,
#                   ids = dados$id, 
#                   progressbar = TRUE)

# vocab = create_vocabulary(it_train, stopwords = tm::stopwords("en"), ngram = c(1L, 2L)) %>% prune_vocabulary(term_count_min = 2)
# vectorizer = vocab_vectorizer(vocab)
# dtm_train_texto = create_dtm(it_train, vectorizer)
# dataframebow <- as.data.frame(as.matrix(dtm_train_texto))

# text_one_hot(dataframebow)


# dataframebow_train <- dataframebow[ trainIndex,]
# dataframebow_test <- dataframebow[-trainIndex,]

#Gerar 
tokenizerBow <- text_tokenizer(num_words = 4000) %>%
  fit_text_tokenizer(dados$textParser)

word_index <- tokenizerBow$word_index
cat("Found", length(word_index), "unique tokens.\n")

dataframebow_train <- texts_to_matrix(tokenizerBow, dados_train$textParser, mode = "binary")
dataframebow_test  <- texts_to_matrix(tokenizerBow, dados_test$textParser,  mode = "binary")
save.image(file="rdas/baseline_embeddings_bow_q2.RData")