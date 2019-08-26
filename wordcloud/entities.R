library(wordcloud)
library(tidyverse)
library(tidytext)
library(text2vec)
library(dplyr)
library(tidytext)
library(janeaustenr)

library(tools)
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))

#Configuracoes
DATABASE <- "icwsm"
clearConsole();

dados <- getDadosChatForCloud()

dados$entidades <- enc2utf8(dados$entidades)
dados$entidades <- iconv(dados$entidades, to='ASCII//TRANSLIT')
dados$entidades = gsub(" ", "_", dados$entidades)
dados$entidades = gsub("---", " ", dados$entidades)
dados$entidades = gsub("/", " ", dados$entidades)

dados$types <- enc2utf8(dados$types)
dados$types <- iconv(dados$types, to='ASCII//TRANSLIT')
dados$types = gsub(" ", "_", dados$types)
dados$types = gsub("---", " ", dados$types)
dados$types = gsub("/", " ", dados$types)

stop_words = tm::stopwords("en")

library(tm)
library(dplyr)
library(xtable)

docs <- Corpus(VectorSource(dados$entidades)) %>%
  tm_map(removePunctuation) %>%
  # tm_map(removeNumbers) %>%
  tm_map(tolower)  %>%
  tm_map(removeWords, stopwords("english")) %>%
  tm_map(stripWhitespace) %>%
  tm_map(PlainTextDocument)

tdm <- TermDocumentMatrix(docs) %>%
  as.matrix()
colnames(tdm) <- c("Sober","Drunk")

par(mfrow=c(1,1))
a <- comparison.cloud(tdm, random.order=FALSE, colors = c("indianred3","blue3"),
                 title.size=2, max.words=200)

warnings()
#tdmMatrix <- as.matrix(tfNeg)
#dados$entidades
#paste(unlist(dados$entidades), collapse =". ")