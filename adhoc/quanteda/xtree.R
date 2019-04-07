library(tools)
library(rword2vec)
library(lsa)
library(readr)
library(quanteda)

source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("utils/resultadoshelper.R"))
source(file_path_as_absolute("utils/getDadosAmazon.R"))

#Configuracoes
DATABASE <- "icwsm"
dados <- getDadosAmazon()