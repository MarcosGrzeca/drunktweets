library(tools)
library(keras)
library(caret)
library(dplyr)
source(file_path_as_absolute("utils/functions.R"))

#Configuracoes
DATABASE <- "icwsm"

getDadosBaseline <- function() {
      dados <- query("SELECT id,
                      q1 AS resposta,
                      textoParserRisadaEmoticom,
                      textEmbedding,
                      hashtags
                      FROM tweets t
                      WHERE LENGTH(textoParserRisadaEmoticom) > 5
                      AND q1 IS NOT NULL
                      ")
  dados$resposta[is.na(dados$resposta)] <- 0    
  dados$resposta <- as.numeric(dados$resposta)
  dados$textEmbedding <- enc2utf8(dados$textEmbedding)
  dados$textEmbedding <- iconv(dados$textEmbedding, to='ASCII//TRANSLIT')
  return (dados)
}