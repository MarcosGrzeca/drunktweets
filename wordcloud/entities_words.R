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

library(plotrix) 
common.words <- subset( tdm, tdm[, 1] > 0 & tdm[, 2] > 0)
tail(common.words)

difference <- abs( common.words[, 1] - common.words[, 2])

#combine the differences with the common words 
common.words <- cbind( common.words, difference) 
#sort by the difference column in decreasing order
common.words <- common.words[ order( common.words[, 3], decreasing = TRUE), ]

#select the top 25 words and create a data frame
top25.df <- data.frame( x = common.words[ 1: 25, 1], 
                        y = common.words[ 1: 25, 2], 
                        labels = rownames(common.words[ 1: 25, ]))

library(ggplot2) 
library(plotrix)

pyramid.plot(top25.df$x, top25.df$y, 
             labels = top25.df$labels, 
             #change gap to show longer words
             gap = 550, 
             top.labels = c("Sober", "Words", "Drunk"), 
             main = "Words in Common", 
             laxlab = NULL, raxlab = NULL, unit = NULL)
