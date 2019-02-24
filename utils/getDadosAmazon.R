library(tools)
library(keras)
library(caret)
library(dplyr)
source(file_path_as_absolute("utils/functions.R"))
#source(file_path_as_absolute("processadores/discretizar.R"))

#Configuracoes
DATABASE <- "icwsm"

getDadosAmazon <- function() {
  dados <- query('SELECT id,
                      q2 AS resposta,
                      textParser,
                      hashtags,
                      emoticonPos,
                      emoticonNeg,
                      hora,
                      erros as numeroErros,
                      textEmbedding as "textOriginal",
                      textEmbedding,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(REPLACE(ty.type, "http://dbpedia.org/class/", "")))
                        FROM tweets_amazon_nlp tn
                        JOIN tweets_amazon_conceito c ON c.palavra = tn.palavra
                        JOIN resource_type ty ON ty.resource = c.resource
                        WHERE tn.idTweet = t.id
                        AND ty.type IN ("http://dbpedia.org/class/yago/Abstraction100002137", "http://dbpedia.org/class/yago/Agent114778436", "http://dbpedia.org/class/yago/Alcohol107884567", "http://dbpedia.org/class/yago/Attribute100024264", "http://dbpedia.org/class/yago/Beverage107881800", "http://dbpedia.org/class/yago/Carcinogen114793812", "http://dbpedia.org/class/yago/Community108223802", "http://dbpedia.org/class/yago/District108552138", "http://dbpedia.org/class/yago/Drug103247620", "http://dbpedia.org/class/yago/DrugOfAbuse103248958", "http://dbpedia.org/class/yago/Fluid114939900", "http://dbpedia.org/class/yago/Food100021265", "http://dbpedia.org/class/yago/Gathering107975026", "http://dbpedia.org/class/yago/Group100031264", "http://dbpedia.org/class/yago/Liquid114940386", "http://dbpedia.org/class/yago/Manner104928903", "http://dbpedia.org/class/yago/Matter100020827", "http://dbpedia.org/class/yago/Object100002684", "http://dbpedia.org/class/yago/PhysicalEntity100001930", "http://dbpedia.org/class/yago/Property104916342", "http://dbpedia.org/class/yago/SocialGroup107950920", "http://dbpedia.org/class/yago/SparklingWine107893528", "http://dbpedia.org/class/yago/Substance100019613", "http://dbpedia.org/class/yago/Substance100020090", "http://dbpedia.org/class/yago/WikicatAmericanRecordProducers", "http://dbpedia.org/class/yago/WikicatBeerStyles", "http://dbpedia.org/class/yago/WikicatDistilledBeverages", "http://dbpedia.org/class/yago/WikicatDrugs", "http://dbpedia.org/class/yago/WikicatDrugsActingOnTheNervousSystem", "http://dbpedia.org/class/yago/WikicatIARCGroup1Carcinogens", "http://dbpedia.org/class/yago/WikicatSparklingWines", "http://dbpedia.org/class/yago/WikicatVirtualCommunities", "http://dbpedia.org/class/yago/WikicatWineStyles", "http://dbpedia.org/class/yago/Wine107891726", "http://dbpedia.org/class/yago/YagoLegalActorGeo", "http://dbpedia.org/ontology/Beverage", "http://dbpedia.org/ontology/Food", "http://dbpedia.org/ontology/RecordLabel", "http://www.ontologydesignpatterns.org/ont/dul/DUL.owl#FunctionalSubstance", "http://www.wikidata.org/entity/Q12136", "http://www.wikidata.org/entity/Q2095", "http://www.wikidata.org/entity/Q41710", "http://www.w3.org/2002/07/owl#Thing")
                        GROUP BY t.id
                      ) AS types,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(tn.palavra))
                        FROM tweets_amazon_nlp tn
                        WHERE tn.idTweet = t.id
                        AND palavra IN ("/food and drink", "/food and drink/beverages/alcoholic beverages", "/food and drink/beverages/alcoholic beverages/cocktails and beer", "/food and drink/beverages/alcoholic beverages/wine", "/law, govt and politics/politics/elections/local elections", "/law, govt and politics/politics/political parties", "/religion and spirituality/buddhism", "/religion and spirituality/hinduism", "Hashtag", "mention", "Person", "#url")
                        GROUP BY tn.idTweet
                      ) AS entidades
                      FROM tweets_amazon t
                      WHERE q2 IN ("0", "1")
                      UNION 
                  SELECT id,
                      q2 as resposta,
                      textParser,
                      hashtags,
                      emoticonPos,
                      emoticonNeg,
                      hora,
                      erroParseado as numeroErros,
                      textEmbedding as "textOriginal",
                      textEmbedding,
                      (
                      SELECT GROUP_CONCAT(DISTINCT(REPLACE(type, "http://dbpedia.org/class/", "")))
                      FROM
                        ( SELECT c.resource AS resource,
                            tn.idTweetInterno
                        FROM tweets_nlp tn
                        JOIN conceito c ON c.palavra = tn.palavra
                        WHERE c.sucesso = 1
                        UNION ALL SELECT c.resource AS resource,
                                 tn.idTweetInterno
                        FROM tweets_gram tn
                        JOIN conceito c ON c.palavra = tn.palavra
                        WHERE c.sucesso = 1
                        GROUP BY 1,
                             2 ) AS louco
                       JOIN resource_type ty ON ty.resource = louco.resource
                       WHERE louco.idTweetInterno = t.idInterno
                       AND ty.type IN ("http://dbpedia.org/class/yago/Abstraction100002137", "http://dbpedia.org/class/yago/Agent114778436", "http://dbpedia.org/class/yago/Alcohol107884567", "http://dbpedia.org/class/yago/Attribute100024264", "http://dbpedia.org/class/yago/Beverage107881800", "http://dbpedia.org/class/yago/Carcinogen114793812", "http://dbpedia.org/class/yago/Community108223802", "http://dbpedia.org/class/yago/District108552138", "http://dbpedia.org/class/yago/Drug103247620", "http://dbpedia.org/class/yago/DrugOfAbuse103248958", "http://dbpedia.org/class/yago/Fluid114939900", "http://dbpedia.org/class/yago/Food100021265", "http://dbpedia.org/class/yago/Gathering107975026", "http://dbpedia.org/class/yago/Group100031264", "http://dbpedia.org/class/yago/Liquid114940386", "http://dbpedia.org/class/yago/Manner104928903", "http://dbpedia.org/class/yago/Matter100020827", "http://dbpedia.org/class/yago/Object100002684", "http://dbpedia.org/class/yago/PhysicalEntity100001930", "http://dbpedia.org/class/yago/Property104916342", "http://dbpedia.org/class/yago/SocialGroup107950920", "http://dbpedia.org/class/yago/SparklingWine107893528", "http://dbpedia.org/class/yago/Substance100019613", "http://dbpedia.org/class/yago/Substance100020090", "http://dbpedia.org/class/yago/WikicatAmericanRecordProducers", "http://dbpedia.org/class/yago/WikicatBeerStyles", "http://dbpedia.org/class/yago/WikicatDistilledBeverages", "http://dbpedia.org/class/yago/WikicatDrugs", "http://dbpedia.org/class/yago/WikicatDrugsActingOnTheNervousSystem", "http://dbpedia.org/class/yago/WikicatIARCGroup1Carcinogens", "http://dbpedia.org/class/yago/WikicatSparklingWines", "http://dbpedia.org/class/yago/WikicatVirtualCommunities", "http://dbpedia.org/class/yago/WikicatWineStyles", "http://dbpedia.org/class/yago/Wine107891726", "http://dbpedia.org/class/yago/YagoLegalActorGeo", "http://dbpedia.org/ontology/Beverage", "http://dbpedia.org/ontology/Food", "http://dbpedia.org/ontology/RecordLabel", "http://www.ontologydesignpatterns.org/ont/dul/DUL.owl#FunctionalSubstance", "http://www.wikidata.org/entity/Q12136", "http://www.wikidata.org/entity/Q2095", "http://www.wikidata.org/entity/Q41710", "http://www.w3.org/2002/07/owl#Thing")
                       ) AS types,
                      (
                      SELECT GROUP_CONCAT(tn.palavra)
                      FROM tweets_nlp tn
                      WHERE tn.idTweetInterno = t.idInterno
                      AND palavra IN ("/food and drink", "/food and drink/beverages/alcoholic beverages", "/food and drink/beverages/alcoholic beverages/cocktails and beer", "/food and drink/beverages/alcoholic beverages/wine", "/law, govt and politics/politics/elections/local elections", "/law, govt and politics/politics/political parties", "/religion and spirituality/buddhism", "/religion and spirituality/hinduism", "Hashtag", "mention", "Person", "#url")
                      GROUP BY tn.idTweetInterno) AS entidades
                      FROM tweets t
                      WHERE textparser <> ""
                      AND id <> 462478714693890048
                      AND q2 IS NOT NULL
                      ')
  dados$resposta[dados$resposta == "0"] <- 0
  dados$resposta[dados$resposta == "1"] <- 1

  dados$resposta <- as.numeric(dados$resposta)
  dados$textParser <- enc2utf8(dados$textParser)
  dados$textParser <- iconv(dados$textParser, to='ASCII//TRANSLIT')
  dados$textParser <- stringi::stri_enc_toutf8(dados$textParser)
  dados$textParser = gsub("'", "", dados$textParser)

  dados$hashtags = gsub("#", "#tag_", dados$hashtags)
  dados$numeroErros[dados$numeroErros > 1] <- 1
  return (dados)
}