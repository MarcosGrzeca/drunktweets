options(java.parameters = "-Xmx32g")
#options(java.parameters = "-Xmx16g")
options(max.print = 99999999)

library(tools)
source(file_path_as_absolute("utils/functions.R"))

#Configuracoes
DATABASE <- "icwsm"
clearConsole();

dados <- query("SELECT t.id, drunk AS resposta,
                  (SELECT GROUP_CONCAT(DISTINCT(tn.palavra))
                   FROM semantic_tweets_nlp tn
                   WHERE tn.idTweet = t.id
                   AND tn.tipo NOT IN ('language', 'socialTag')
                   GROUP BY t.id) AS entidades
              FROM semantic_tweets_alcolic t
              WHERE situacao = 1")

dados$resposta[is.na(dados$resposta)] <- 0
dados$resposta[dados$resposta == "X"] <- 1
dados$resposta[dados$resposta == "N"] <- 0
dados$resposta[dados$resposta == "S"] <- 1

dados$resposta <- as.factor(dados$resposta)
dados$entidades <- enc2utf8(dados$entidades)
dados$entidades = gsub(" ", "_", dados$entidades)
dados$entidades = gsub("/", "__", dados$entidades)

clearConsole()

if (!require("text2vec")) {
  install.packages("text2vec")
}
library(text2vec)
library(data.table)
library(SnowballC)

setDT(dados)
setkey(dados, id)

it_train = itoken(strsplit(dados$entidades, ","), 
                  preprocessor = tolower,
                  tokenizer = word_tokenizer,
                  ids = dados$id, 
                  progressbar = TRUE)

vocab = create_vocabulary(it_train, stopwords = tm::stopwords("en"))
vocab = prune_vocabulary(vocab, term_count_min = 3)
vectorizer = vocab_vectorizer(vocab)
dataFrameResource = create_dtm(it_train, vectorizer)
dataFrameResource <- as.data.frame(as.matrix(dataFrameResource))

library(rowr)
library(RWeka)

maFinal <- cbind.fill(subset(dados, select = c(resposta)), dataFrameResource)

if (!require("FSelector")) {
  install.packages("FSelector")
}
library(FSelector)
weights <- information.gain(resposta~., maFinal)
print(weights)
subset <- cutoff.k(weights, 100)
f <- as.simple.formula(subset, "resposta")
print(f)

dump(weights, "feature_selection/planilhas/infogain_enriquecimento.csv")

save.image(file="rdas/infogain_enriquecimento.RData")