logar <- function(dataset, embedding, tipoRede, epocas, earlyStop, metricaEarly, enriquecimento, resultados, model, redeDesc) {
  conexao <- connect()
  sql <- paste("INSERT INTO `resultado` (`dataset`, `embedding`, `tipoRede`, `epocas`, `earlyStop`, `metricaEarly`, `enriquecimento`, `f1`, `precision`, `recall`, `model`, `f1Text`, `precisionText`, `recallText`, `redeId`) VALUES ('", dbEscapeStrings(conexao, dataset), "', '", dbEscapeStrings(conexao, embedding), "', '", dbEscapeStrings(conexao, tipoRede), "', ", epocas, ", ", earlyStop, ", '", dbEscapeStrings(conexao, metricaEarly), "', ", enriquecimento, ", ", mean(resultados$F1), ", ", mean(resultados$Precision), ",", mean(resultados$Recall), ", '", dbEscapeStrings(conexao, model), "', '", toString(resultados$F1), "', '", toString(resultados$Precision), "', '", toString(resultados$Recall), "', '", dbEscapeStrings(conexao, redeDesc), "')", sep="");
  dbDisconnect(conexao)
  query(sql)
}