library(RMySQL)

#Functions
clearConsole <- function(){
  cat("\014")
}

initFileLog <- function(nome){
  zz <- file(nome, open = "wt")
  sink(zz)
  sink(zz, type = "message")
}

finishFileLog <- function(nome){
  sink(type = "message")
  sink()
  file.show(nome)
}


query <- function(sql) {
  dbDataType(RMySQL::MySQL(), "a")
  mydb = dbConnect(MySQL(), user='root', password='senharoot123', dbname=DATABASE, host='marcosrds.ce948apvv9n9.sa-east-1.rds.amazonaws.com')
  rs = dbSendQuery(mydb, sql);
  dataBD <- fetch(rs, n=-1)
  huh <- dbHasCompleted(rs)
  dbClearResult(rs)
  dbDisconnect(mydb)
  return (dataBD)
}

connect <- function() {
  dbDataType(RMySQL::MySQL(), "a")
  return (dbConnect(MySQL(), user='root', password='senharoot123', dbname=DATABASE, host='marcosrds.ce948apvv9n9.sa-east-1.rds.amazonaws.com'))
}

queryConnection <- function(mydb, sql) {
  dbDataType(RMySQL::MySQL(), "a")
  rs = dbSendQuery(mydb, sql);
  dataBD <- fetch(rs, n=-1)
  huh <- dbHasCompleted(rs)
  dbClearResult(rs)
  dbDisconnect(mydb)
  return (dataBD)
}


#Exportar para ARFF
library("rio")

dump <- function(dadosExport, arquivo) {
  #Exportar para CSV
  write.table(dadosExport, file = arquivo, append = FALSE, quote = TRUE, sep = ",", eol = "\n", na = "?", dec = ".", row.names = FALSE, col.names = TRUE, qmethod = c("escape", "double"), fileEncoding = "")
  #export(dados, "dump_enem_total.arff")
}


convert_count <- function(x) {
  y <- ifelse(x > 0, 1,0)
  y
}

bofPresence <- function(vetor) {
  vetor <- apply(vetor, 2, convert_count)
  vetor <- as.data.frame(as.matrix(vetor))
  return (vetor)
}

magica <- function(dados) {
  dados$resposta[is.na(dados$resposta)] <- 0
  dados$resposta <- as.factor(dados$resposta)
  dados$textParser <- enc2utf8(dados$textParser)
  dados$textParser <- iconv(dados$textParser, to='ASCII//TRANSLIT')
  dados$textParser = gsub("'", "", dados$textParser)

  dados$entidades <- enc2utf8(dados$entidades)
  dados$entidades <- iconv(dados$entidades, to='ASCII//TRANSLIT')
  dados$entidades = gsub(" ", "_", dados$entidades)

  dados$entidadesDBPedia <- enc2utf8(dados$entidadesDBPedia)
  dados$entidadesDBPedia <- iconv(dados$entidadesDBPedia, to='ASCII//TRANSLIT')
  dados$entidadesDBPedia = gsub(" ", "_", dados$entidadesDBPedia)

  dados$hashtags = gsub("#", "#tag_", dados$hashtags)
  return (dados)
}