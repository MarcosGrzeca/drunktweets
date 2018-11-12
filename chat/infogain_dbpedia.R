#options(java.parameters = "-Xmx32g")
options(java.parameters = "-Xmx90000m")
options(max.print = 99999999)

library(tools)
source(file_path_as_absolute("utils/functions.R"))

#Configuracoes
DATABASE <- "icwsm"
clearConsole();

dados <- query("SELECT t.id, drunk AS resposta,
               (
                 SELECT GROUP_CONCAT(DISTINCT(REPLACE(type, 'http://dbpedia.org/class/', '')))
                 FROM
                 (
                    SELECT c.resource AS resource,
                    tn.idTweet
                    FROM chat_tweets_nlp tn
                    JOIN chat_tweets_conceito c ON c.palavra = tn.palavra
                    WHERE c.sucesso = 1
                    GROUP BY 1,2
                  ) AS louco
               JOIN resource_type ty ON ty.resource = louco.resource
               WHERE louco.idTweet = t.id
               ) AS resources
               FROM chat_tweets t")

save(dados, file = "chat/rdas/cfs.Rda")

dados$resposta[is.na(dados$resposta)] <- 0
dados$resposta[dados$resposta == "Y"] <- 1
dados$resposta[dados$resposta == "N"] <- 0
dados$resposta[dados$resposta == "S"] <- 1

dados$resposta <- as.factor(dados$resposta)
dados$resources <- enc2utf8(dados$resources)
dados$resources = gsub("/", "_", dados$resources)

clearConsole()

if (!require("text2vec")) {
  install.packages("text2vec")
}
library(text2vec)
library(data.table)
library(SnowballC)

setDT(dados)
setkey(dados, id)

it_train = itoken(strsplit(dados$resources, ","), 
                  preprocessor = tolower,
                  tokenizer = word_tokenizer,
                  ids = dados$id, 
                  progressbar = TRUE)

vocab = create_vocabulary(it_train, stopwords = tm::stopwords("en"))
vocab = prune_vocabulary(vocab, term_count_min = 3)
vectorizer = vocab_vectorizer(vocab)
dataFrameResource = create_dtm(it_train, vectorizer)
dataFrameResource <- as.data.frame(as.matrix(dataFrameResource))

#dump(colnames(dataFrameResource), "teste.csv")

library(rowr)
library(RWeka)

maFinal <- cbind.fill(subset(dados, select = c(resposta)), dataFrameResource)

if (!require("FSelector")) {
  install.packages("FSelector")
}

library(FSelector)
weights <- information.gain(resposta~., maFinal)
print(weights)
subset <- cutoff.k(weights, 200)
f <- as.simple.formula(subset, "resposta")
print(f)

subset

dump(weights, "chat/infogain_dbpedia.csv")
save.image(file="chat/rdas/infogain_dbpedia.RData")


load("chat/rdas/infogain_dbpedia.RData")
View(weights)

View(weights[order(-weights$attr_importance),])
