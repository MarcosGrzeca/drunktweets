logar <- function(dataset, embedding, epocas, earlyStop, metricaEarly, enriquecimento, resultados, model) {
  conexao <- connect()
  sql <- paste("INSERT INTO `resultado` (`dataset`, `embedding`, `epocas`, `earlyStop`, `metricaEarly`, `enriquecimento`, `f1`, `precision`, `recall`, `model`, `f1Text`, `precisionText`, `recallText`) VALUES ('", dbEscapeStrings(conexao, dataset), "', '", dbEscapeStrings(conexao, embedding), "', ", epocas, ", ", earlyStop, ", '", dbEscapeStrings(conexao, metricaEarly), "', ", enriquecimento, ", ", mean(resultados$F1), ", ", mean(resultados$Precision), ",", mean(resultados$Recall), ", '", dbEscapeStrings(conexao, model), "', '", toString(resultados$F1), "', '", toString(resultados$Precision), "', '", toString(resultados$Recall), "')", sep="");
  dbDisconnect(conexao)
  query(sql)
}