library(tools)
library(keras)
library(caret)
library(dplyr)
source(file_path_as_absolute("utils/functions.R"))
#source(file_path_as_absolute("processadores/discretizar.R"))

#Configuracoes
DATABASE <- "icwsm"

getDados <- function() {
      dados <- query("SELECT id,
                      drunk AS resposta,
                      textOriginal,
                      hashtags,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(tn.palavra))
                        FROM semantic_tweets_nlp tn
                        WHERE tn.idTweet = t.id
                        -- AND tn.tipo NOT IN ('language', 'socialTag')
                        GROUP BY tn.idTweet
                      ) AS entidades,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(tn.type))
                        FROM semantic_tweets_nlp tn
                        WHERE tn.idTweet = t.id
                        AND type IS NOT NULL
                        AND type <> ''
                        GROUP BY tn.idTweet
                      ) AS enriquecimentoTypes,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(REPLACE(ty.type, 'http://dbpedia.org/class/', '')))
                        FROM semantic_tweets_nlp tn
                        JOIN semantic_conceito c ON c.palavra = tn.palavra
                        JOIN resource_type ty ON ty.resource = c.resource
                        WHERE tn.idTweet = t.id
                        GROUP BY t.id
                      ) AS types
                      FROM semantic_tweets_alcolic t
                      WHERE situacao = 1
                      AND possuiURL = 0
                      AND LENGTH(textOriginal) > 5
                      -- ORDER by data DESC
                      -- LIMIT 15000
                      ")
      # AND id = 1021368493743255552

  dados$resposta[dados$resposta == "X"] <- 1
  dados$resposta[dados$resposta == "N"] <- 0
  dados$resposta[dados$resposta == "S"] <- 1

  #dados$resposta <- as.factor(dados$resposta)
  dados$resposta <- as.numeric(dados$resposta)
  dados$textOriginal <- enc2utf8(dados$textOriginal)
  dados$textOriginal <- iconv(dados$textOriginal, to='ASCII//TRANSLIT')
  
  dados$textOriginal = gsub("#drunk |#drunk$", "", dados$textOriginal,ignore.case=T)
  dados$textOriginal = gsub("#drank |#drank$", "", dados$textOriginal,ignore.case=T)
  dados$textOriginal = gsub("#imdrunk |#imdrunk$", "", dados$textOriginal,ignore.case=T)

  dados$entidades <- enc2utf8(dados$entidades)
  dados$entidades <- iconv(dados$entidades, to='ASCII//TRANSLIT')
  dados$entidades = gsub(" ", "eee", dados$entidades, ignore.case=T)
  dados$entidades = gsub("[^A-Za-z0-9,_ ]","",dados$entidades, ignore.case=T)
  dados$entidades[is.na(dados$entidades)] <- "SEMENTIDADES"

  dados$types <- enc2utf8(dados$types)
  dados$types <- iconv(dados$types, to='ASCII//TRANSLIT')
  dados$types = gsub(" ", "eee", dados$types, ignore.case=T)
  dados$types = gsub("[^A-Za-z0-9,_ ]","",dados$types, ignore.case=T)
  dados$types[is.na(dados$types)] <- "SEMENTIDADES"

  dados$enriquecimentoTypes <- enc2utf8(dados$enriquecimentoTypes)
  dados$enriquecimentoTypes <- iconv(dados$enriquecimentoTypes, to='ASCII//TRANSLIT')
  dados$enriquecimentoTypes = gsub(" ", "eee", dados$enriquecimentoTypes, ignore.case=T)
  dados$enriquecimentoTypes = gsub("[^A-Za-z0-9,_ ]","",dados$enriquecimentoTypes, ignore.case=T)
  dados$enriquecimentoTypes[is.na(dados$enriquecimentoTypes)] <- "SEMENTIDADES"

  return (dados)
}

getDadosInfoGain <- function() {
      # con <- dbEscapeStrings(connect(), "new year's")
      dados <- query("SELECT id,
                      drunk AS resposta,
                      textOriginal as textEmbedding,
                      hashtags,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(tn.palavra))
                        FROM semantic_tweets_nlp tn
                        WHERE tn.idTweet = t.id
                        AND palavra IN ('/art and entertainment', '/art and entertainment/dance', '/art and entertainment/movies and tv/comedies', '/art and entertainment/movies and tv/movies', '/art and entertainment/movies and tv/reality', '/art and entertainment/music', '/art and entertainment/music/recording industry/music awards', '/automotive and vehicles/vehicle brands/acura', '/business and industrial', '/business and industrial/business news', '/family and parenting/children', '/food and drink', '/food and drink/barbecues and grilling', '/food and drink/beverages', '/food and drink/beverages/alcoholic beverages/cocktails and beer', '/food and drink/beverages/alcoholic beverages/wine', '/food and drink/beverages/non alcoholic beverages/bottled water', '/food and drink/beverages/non alcoholic beverages/coffee and tea', '/food and drink/beverages/non alcoholic beverages/soft drinks', '/health and fitness/addiction', '/health and fitness/addiction/alcoholism', '/health and fitness/disease/cold and flu', '/science/chemistry', '/shopping/gifts/party supplies', '/society', '/society/crime/property crime/fraud', '/society/sex', '/society/unrest and war', 'Alcohol intoxication', 'alcohol', 'Alcohol', 'Alcoholic beverage', 'Alcoholism', 'Alternative wine closures', 'America', 'Aquarius Night Club', 'Bar association', 'bar', 'Bar', 'bartender', 'Beauty Bar', 'beer', 'Beer', 'Bill Clinton', 'booze', 'bottle', 'bottles', 'Card game', 'Carter Page', 'champagne', 'Christmas', 'Club Pandora', 'club', 'Club', 'Communist state', 'Conservative Party', 'crown', 'Dean Martin', 'decency', 'Disc jockey', 'Distilled beverage', 'Dm', 'Donald Trump', 'drink', 'Drinking culture', 'drinking game', 'drinking', 'driver', 'drunk', 'Ethanol', 'Federal Bureau of Investigation', 'Fermentation', 'floor', 'glass', 'hangover', 'Hashtag', 'Ideology', 'International Democrat Union', 'Jimmy Carter', 'JobTitle', 'liquor', 'Location', 'Maria Butina', 'mention', 'Mueller', 'NA.', 'New New Year\\'s Day', 'night', 'Nightclub', 'Ohmz', 'party', 'Party', 'Person', 'Political party', 'President of the United States', 'President', 'pub', 'Public house', 'Putin', 'Rd', 'Republicans', 'Reuters', 'RT', 'rum', 'Russia', 'Russians', 'safe way home', 'Saturday', 'Shadow Lounge', 'shot', 'shots', 'Striptease', 'tequila', 'Tequila', 'The Next Episode', 'Thermodynamics', 'Trigraph', 'Trump', 'United States', 'vodka', 'Vodka', 'whiskey', 'White House', 'Wine bottle', 'wine', 'Wine', '/law, govt and politics', '/law, govt and politics/espionage and intelligence/secret service', '/law, govt and politics/espionage and intelligence/surveillance', '/law, govt and politics/espionage and intelligence/terrorism', '/law, govt and politics/government', '/law, govt and politics/government/courts and judiciary', '/law, govt and politics/government/embassies and consulates', '/law, govt and politics/government/executive branch', '/law, govt and politics/immigration', '/law, govt and politics/legal issues/human rights', '/law, govt and politics/politics/elections', '/law, govt and politics/politics/elections/presidential elections', '/law, govt and politics/politics/foreign policy', 'Zone Night Club')
                        GROUP BY tn.idTweet
                      ) AS entidades,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(tn.type))
                        FROM semantic_tweets_nlp tn
                        WHERE tn.idTweet = t.id
                        AND type IS NOT NULL
                        AND type <> ''
                        GROUP BY tn.idTweet
                      ) AS enriquecimentoTypes,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(REPLACE(ty.type, 'http://dbpedia.org/class/', '')))
                        FROM semantic_tweets_nlp tn
                        JOIN semantic_conceito c ON c.palavra = tn.palavra
                        JOIN resource_type ty ON ty.resource = c.resource
                        WHERE tn.idTweet = t.id
                        AND ty.type IN ('http://dbpedia.org/ontology/Beverage', 'http://dbpedia.org/class/yago/WikicatIARCGroup1Carcinogens', 'http://dbpedia.org/class/yago/WikicatDrugsActingOnTheNervousSystem', 'http://dbpedia.org/class/yago/Agent114778436', 'http://dbpedia.org/class/yago/WikicatDrugs', 'http://dbpedia.org/class/yago/Drug103247620', 'http://dbpedia.org/class/yago/Carcinogen114793812', 'http://dbpedia.org/class/yago/Substance100020090', 'http://dbpedia.org/class/yago/Matter100020827', 'http://dbpedia.org/class/yago/WikicatBeerStyles', 'http://dbpedia.org/class/yago/WikicatVirtualCommunities', 'http://dbpedia.org/ontology/RecordLabel', 'http://dbpedia.org/class/yago/Community108223802', 'http://dbpedia.org/class/yago/Gathering107975026', 'http://dbpedia.org/class/yago/Property104916342', 'http://dbpedia.org/class/yago/Manner104928903', 'http://dbpedia.org/class/yago/SocialGroup107950920', 'http://dbpedia.org/class/yago/Attribute100024264', 'http://dbpedia.org/class/yago/Group100031264', 'http://dbpedia.org/class/yago/CausalAgent100007347', 'http://dbpedia.org/ontology/Agent', 'http://dbpedia.org/class/yago/Abstraction100002137', 'http://dbpedia.org/class/yago/PhysicalEntity100001930', 'http://www.ontologydesignpatterns.org/ont/dul/DUL.owl#FunctionalSubstance', 'http://www.wikidata.org/entity/Q2095', 'NA.', 'http://dbpedia.org/class/yago/BroadcastingStation102903405', 'http://dbpedia.org/class/yago/Channel103006398', 'http://dbpedia.org/ontology/Food', 'http://dbpedia.org/class/yago/TelevisionStation104406350', 'http://dbpedia.org/class/yago/WikicatEnglish-languageTelevisionStations', 'http://dbpedia.org/class/yago/WikicatLanguagesOfGhana', 'http://dbpedia.org/class/yago/WikicatLanguagesOfFiji', 'http://dbpedia.org/class/yago/WikicatLanguagesOfGuyana', 'http://dbpedia.org/class/yago/Facility103315023', 'http://dbpedia.org/class/yago/Station104306080', 'http://dbpedia.org/class/yago/WikicatLanguagesOfGuam', 'http://dbpedia.org/class/yago/WikicatLanguagesOfEurope', 'http://dbpedia.org/class/yago/WikicatLanguagesOfGrenada', 'http://dbpedia.org/class/yago/WikicatLanguagesOfJamaica', 'http://dbpedia.org/class/yago/WikicatLanguagesOfDominica', 'http://dbpedia.org/class/yago/WikicatForeignTelevisionChannelsBroadcastingInTheUnitedKingdom', 'http://dbpedia.org/class/yago/WikicatLanguagesOfEritrea', 'http://dbpedia.org/class/yago/WikicatLanguagesOfIreland', 'http://dbpedia.org/class/yago/WikicatLanguagesOfKenya', 'http://dbpedia.org/class/yago/WikicatLanguagesOfHongKong', 'http://dbpedia.org/class/yago/WikicatLanguagesOfIndia', 'http://dbpedia.org/class/yago/WikicatRussian-languageTelevisionStations', 'http://dbpedia.org/class/yago/WikicatInternetTelevisionChannels', 'http://dbpedia.org/class/yago/Employee110053808', 'http://dbpedia.org/class/yago/Adviser109774266', 'http://dbpedia.org/class/yago/Blogger109860415', 'http://dbpedia.org/class/yago/WikicatSpanish-languageTelevisionStations', 'http://dbpedia.org/class/yago/Authority109824361', 'http://dbpedia.org/class/yago/Educator110045713', 'http://dbpedia.org/class/yago/Applicant109607280', 'http://dbpedia.org/class/yago/WikicatLanguagesOfKiribati', 'http://dbpedia.org/class/yago/Capitalist109609232', 'http://dbpedia.org/class/yago/Disputant109615465', 'http://dbpedia.org/class/yago/Billionaire110529684', 'http://dbpedia.org/class/yago/Businessman109882007', 'http://dbpedia.org/class/yago/WikicatTelevisionChannelsAndStationsEstablishedIn2005', 'http://dbpedia.org/class/yago/Executive110069645', 'http://dbpedia.org/class/yago/WikicatTelevisionChannelsInBelgium', 'http://dbpedia.org/class/yago/WikicatTelevisionChannelsInFlanders', 'http://dbpedia.org/class/yago/Associate109816771', 'http://dbpedia.org/class/yago/Businessperson109882716', 'http://dbpedia.org/class/yago/Director110014939', 'http://dbpedia.org/class/yago/WikicatLanguagesOfCyprus', 'http://dbpedia.org/class/yago/WikicatLanguagesOfBrunei', 'http://dbpedia.org/class/yago/WikicatLanguagesOfBermuda', 'http://dbpedia.org/class/yago/Expert109617867', 'http://dbpedia.org/class/yago/WikicatLanguagesOfBelize', 'http://dbpedia.org/class/yago/WikicatLanguagesOfCameroon', 'http://dbpedia.org/class/yago/Beverage107881800', 'http://dbpedia.org/class/yago/Fluid114939900', 'http://dbpedia.org/class/yago/Liquid114940386', 'http://dbpedia.org/class/yago/WikicatLanguagesOfBotswana', 'http://dbpedia.org/class/yago/Alumnus109786338', 'http://dbpedia.org/class/yago/WikicatLanguagesOfBahrain', 'http://dbpedia.org/class/yago/Dancer109989502', 'http://dbpedia.org/class/yago/WikicatLanguagesOfCanada', 'http://dbpedia.org/class/yago/Administrator109770949', 'http://dbpedia.org/class/yago/WikicatLanguagesOfAntiguaAndBarbuda', 'http://dbpedia.org/class/yago/WikicatLanguagesOfAustralia', 'http://dbpedia.org/class/yago/WikicatBarAssociations', 'http://dbpedia.org/class/yago/Association108049401', 'http://dbpedia.org/class/yago/WikicatLegalOrganizations', 'http://dbpedia.org/class/yago/Substance100019613', 'http://dbpedia.org/class/yago/WikicatTelevisionChannelsInTheNetherlands', 'http://dbpedia.org/class/yago/WikicatLanguagesOfAmericanSamoa', 'http://dbpedia.org/class/yago/WikicatLanguagesOfLesotho', 'http://dbpedia.org/class/yago/WikicatLanguagesOfLebanon', 'http://dbpedia.org/class/yago/Entertainer109616922', 'http://dbpedia.org/class/yago/Food100021265', 'http://dbpedia.org/class/yago/WikicatTelevisionStations', 'http://dbpedia.org/class/yago/WikicatMaleDancers', 'http://dbpedia.org/class/yago/Fundraiser110116478', 'http://dbpedia.org/class/yago/Financier110090020', 'http://dbpedia.org/class/yago/WikicatProfessionalAssociations', 'http://dbpedia.org/class/yago/WikicatTelevisionStationsInRussia', 'http://dbpedia.org/class/yago/Hotelier110187990', 'http://dbpedia.org/class/yago/ProfessionalAssociation108242675', 'http://dbpedia.org/class/yago/WikicatLanguages', 'http://dbpedia.org/class/yago/WikicatLanguagesOf', 'http://dbpedia.org/class/yago/WikicatGermanicLanguages', 'http://dbpedia.org/class/yago/Host110187130', 'http://dbpedia.org/class/yago/WikicatFusionalLanguages', 'http://dbpedia.org/class/yago/Performer110415638', 'http://dbpedia.org/class/yago/InvestmentAdviser110215815', 'http://dbpedia.org/class/yago/WikicatNon-alcoholicBeverages', 'http://dbpedia.org/class/yago/Investor110216106', 'http://dbpedia.org/class/yago/Difficulty114408086', 'http://dbpedia.org/class/yago/Part113809207', 'http://dbpedia.org/class/yago/ImportantPerson110200781', 'http://umbel.org/umbel/rc/Drink', 'http://dbpedia.org/class/yago/Problem114410605', 'http://dbpedia.org/class/yago/Merchant110309896', 'http://dbpedia.org/class/yago/Observer110369528', 'http://dbpedia.org/class/yago/Communicator109610660', 'http://dbpedia.org/class/yago/WikicatEnglishLanguages', 'http://dbpedia.org/class/yago/Language106282651', 'http://dbpedia.org/class/yago/Peer109626238', 'http://dbpedi', 'http://dbpedia.org/class/yago/WikicatSocialProblems', 'http://www.wikidata.org/entity/Q12136', 'http://dbpedia.org/class/yago/WikicatRoadsInWales', 'http://dbpedia.org/class/yago/Look100877127', 'http://dbpedia.org/class/yago/Observation100879759', 'http://dbpedia.org/class/yago/Militant110315837', 'http://dbpedia.org/class/yago/LegalHoliday115199592', 'http://dbpedia.org/class/yago/Leisure115137676', 'http://dbpedia.org/class/yago/Holiday115183428', 'http://dbpedia.org/class/yago/Communication100033020', 'http://dbpedia.org/class/yago/DepositoryFinancialInstitution108420278', 'http://dbpedia.org/class/yago/Institute108407330', 'http://dbpedia.org/class/yago/Agreement106770275', 'http://dbpedia.org/class/yago/SensoryActivity100876737', 'http://dbpedia.org/class/yago/Sensing100876874', 'http://dbpedia.org/class/yago/Owner110388924', 'http://dbpedia.org/class/yago/WikicatIntergovernmentalOrganizationsEstablishedByTreaty', 'http://dbpedia.org/class/yago/WikicatBankingInstitutes', 'http://dbpedia.org/class/yago/Treaty106773434', 'http://dbpedia.org/class/yago/WikicatInternationalOrganizationsOfAfrica', 'http://dbpedia.org/class/yago/WikicatBanks', 'http://dbpedia.org/class/yago/WikicatOrganizationsBasedInAfrica', 'http://dbpedia.org/class/yago/WikicatBanksEstablishedIn1964', 'http://dbpedia.org/class/yago/WikicatMultilateralDevelopmentBanks', 'http://dbpedia.org/class/yago/WikicatPrivateCurrencies', 'http://dbpedia.org/class/yago/WikicatOrganizationsBasedInIvoryCoast', 'http://dbpedia.org/class/yago/WikicatInternationalDevelopmentTreaties', 'http://dbpedia.org/class/yago/Adult109605289', 'http://umbel.org/umbel/rc/AilmentCondition', 'http://dbpedia.org/ontology/Disease', 'http://dbpedia.org/class/yago/TimeOff115118453', 'http://dbpedia.org/class/yago/Head110162991', 'http://dbpedia.org/class/yago/WikicatCompaniesEstablishedIn1964', 'http://dbpedia.org/class/yago/Vacation115137890', 'http://dbpedia.org/class/yago/FinancialInstitution108054721', 'http://dbpedia.org/class/yago/Participant110401829', 'http://dbpedia.org/class/yago/InteriorDesigner110210648', 'http://dbpedia.org/class/yago/Intellectual109621545', 'http://dbpedia.org/class/yago/WikicatDistilledBeverages', 'http://dbpedia.org/ontology/Election', 'http://dbpedia.org/class/yago/Festival115162388', 'http://dbpedia.org/class/yago/CalendarDay115157041', 'http://dbpedia.org/class/yago/Day115157225', 'http://dbpedia.org/class/yago/Artifact100021939', 'http://dbpedia.org/class/yago/FundamentalQuantity113575869', 'http://dbpedia.org/class/yago/WikicatMediaCompaniesOfTheUnitedKingdom', 'http://dbpedia.org/class/yago/WikicatNewsAgencies', 'http://dbpedia.org/class/yago/Agency108057206', 'http://dbpedia.org/class/yago/Disease114070360', 'http://dbpedia.org/class/yago/WikicatDecemberObservances', 'http://dbpedia.org/class/yago/NewsAgency108355075', 'http://dbpedia.org/class/yago/WikicatBritishMedia', 'http://dbpedia.org/class/yago/WikicatChristianFestivalsAndHolyDays', 'http://dbpedia.org/class/yago/IllHealth114052046', 'http://dbpedia.org/class/yago/WikicatNewsAgenciesBasedInTheUnitedKingdom', 'http://dbpedia.org/class/yago/LegalDocument106479665', 'http://dbpedia.org/class/yago/WikicatCompaniesEstablishedIn1851', 'http://dbpedia.org/class/yago/Illness114061805', 'http://dbpedia.org/class/yago/WikicatCompaniesOfTheUnitedKingdom', 'http://dbpedia.org/class/yago/PathologicalState114051917', 'http://dbpedia.org/class/yago/PhysicalCondition114034177', 'http://dbpedia.org/class/yago/YagoGeoEntity', 'http://dbpedia.org/class/yago/WikicatMediaCompaniesBasedInLondon', 'http://dbpedia.org/class/yago/WikicatFinancialNewsAgencies', 'http://dbpedia.org/class/yago/Alliance108293982', 'http://dbpedia.org/class/yago/WikicatCentralAsianCountries', 'http://dbpedia.org/class/yago/State100024720', 'http://dbpedia.org/class/yago/Condition113920835', 'http://dbpedia.org/class/yago/TimePeriod115113229', 'http://dbpedia.org/class/yago/Relation100031921', 'http://dbpedia.org/class/yago/Artist109812338', 'http://dbpedia.org/class/yago/Leader109623038', 'http://dbpedia.org/class/yago/Alcohol107884567', 'http://dbpedia.org/class/yago/Diplomat110013927', 'http://dbpedia.org/class/yago/WikicatDiplomatsByRole', 'http://dbpedia.org/class/yago/WikicatEastAsianCountries', 'http://dbpedia.org/class/yago/Composer109947232', 'http://dbpedia.org/class/yago/WikicatHolidays', 'http://dbpedia.org/class/yago/Official110372373', 'http://dbpedia.org/class/yago/Black-footedFerret102443484', 'http://dbpedia.org/class/yago/Carnivore102075296', 'http://dbpedia.org/class/yago/Mamma', 'http://dbpedia.org/class/yago/Musician110339966', 'http://dbpedia.org/class/yago/WikicatComplexityClasses', 'http://dbpedia.org/class/yago/Aesthetic105968971', 'http://dbpedia.org/class/yago/WikicatPublicHolidaysInUkraine', 'http://dbpedia.org/class/yago/WikicatMemberStatesOfTheCommonwealthOfIndependentStates', 'http://dbpedia.org/class/yago/Doctrine105943300', 'http://dbpedia.org/class/yago/WikicatNortheastAsianCountries', 'http://dbpedia.org/class/yago/WikicatNorthAsianCountries', 'http://dbpedia.org/class/yago/Generalization105913275', 'http://dbpedia.org/class/yago/PhilosophicalDoctrine106167328', 'http://dbpedia.org/class/yago/Technique105665146', 'http://dbpedia.org/class/yago/Method105660268', 'http://dbpedia.org/class/yago/Know-how105616786', 'http://dbpedia.org/class/yago/Calendar115173479', 'http://dbpedia.org/class/yago/WikicatAesthetics', 'http://dbpedia.org/class/yago/Principle105913538', 'http://dbpedia.org/class/yago/WikicatSparklingWines', 'http://dbpedia.org/class/yago/SparklingWine107893528', 'http://dbpedia.org/class/yago/WikicatWineStyles', 'http://dbpedia.org/class/yago/WikicatSongwritersFromNewYork', 'http://dbpedia.org/class/yago/WikicatPrinciples', 'http://dbpedia.org/class/yago/WikicatPaintingTechniques', 'http://dbpedia.org/class/yago/WikicatArtisticTechniques', 'http://dbpedia.org/class/yago/Ability105616246', 'http://dbpedia.org/ontology/PopulatedPlace', 'http://dbpedia.org/class/yago/YagoPermanentlyLocatedEntity', 'http://dbpedia.org/class/yago/WikicatPublicHolidaysInRussia', 'http://dbpedia.org/class/yago/WikicatMotorVehicleManufacturersOfJapan', 'http://dbpedia.org/class/yago/Emperor110053004', 'http://dbpedia.org/class/yago/Wine107891726', 'http://dbpedia.org/class/yago/WikicatRussian-speakingCountriesAndTerritories', 'http://dbpedia.org/class/yago/WikicatTelevisionChannelsInTheNether', 'http://dbpedia.org/class/yago/Measure100033615', 'http://dbpedia.org/class/yago/WikicatSlavicCountriesAndTerritories', 'http://dbpedia.org/class/yago/WikicatCompaniesEstablishedIn1986', 'http://dbpedia.org/class/yago/WikicatLanguages', 'http://dbpedia.org/class/yago/DrugOfAbuse103248958', 'http://dbpedia.org/class/yago/Object100002684', 'http://dbpedia.org/class/yago/WikicatAmericanHipHopRecordProducers', 'http://dbpedia.org/class/yago/WikicatStatesAndTerritoriesEstablishedIn1991', 'http://umbel.org/umbel/rc/Currency', 'http://dbpedia.org/class/yago/WikicatStatesAndTerritoriesEstablishedIn862', 'http://dbpedia.org/class/yago/WikicatProf')
                        GROUP BY t.id
                      ) AS types
                      FROM semantic_tweets_alcolic t
                      WHERE situacao = 1
                      AND possuiURL = 0
                      AND LENGTH(textOriginal) > 5
                      ")

  dados$resposta[dados$resposta == "X"] <- 1
  dados$resposta[dados$resposta == "N"] <- 0
  dados$resposta[dados$resposta == "S"] <- 1

  #dados$resposta <- as.factor(dados$resposta)
  dados$resposta <- as.numeric(dados$resposta)
  dados$textEmbedding <- enc2utf8(dados$textEmbedding)
  dados$textEmbedding <- iconv(dados$textEmbedding, to='ASCII//TRANSLIT')
  
  dados$textEmbedding = gsub("#drunk |#drunk$", "", dados$textEmbedding,ignore.case=T)
  dados$textEmbedding = gsub("#drank |#drank$", "", dados$textEmbedding,ignore.case=T)
  dados$textEmbedding = gsub("#imdrunk |#imdrunk$", "", dados$textEmbedding,ignore.case=T)

  dados$entidades <- enc2utf8(dados$entidades)
  dados$entidades <- iconv(dados$entidades, to='ASCII//TRANSLIT')
  dados$entidades = gsub(" ", "eee", dados$entidades, ignore.case=T)
  dados$entidades = gsub("[^A-Za-z0-9,_ ]","",dados$entidades, ignore.case=T)
  dados$entidades[is.na(dados$entidades)] <- "SEMENTIDADES"

  dados$types <- enc2utf8(dados$types)
  dados$types <- iconv(dados$types, to='ASCII//TRANSLIT')
  dados$types = gsub(" ", "eee", dados$types, ignore.case=T)
  dados$types = gsub("[^A-Za-z0-9,_ ]","",dados$types, ignore.case=T)
  dados$types[is.na(dados$types)] <- "SEMENTIDADES"

  dados$enriquecimentoTypes <- enc2utf8(dados$enriquecimentoTypes)
  dados$enriquecimentoTypes <- iconv(dados$enriquecimentoTypes, to='ASCII//TRANSLIT')
  dados$enriquecimentoTypes = gsub(" ", "eee", dados$enriquecimentoTypes, ignore.case=T)
  dados$enriquecimentoTypes = gsub("[^A-Za-z0-9,_ ]","",dados$enriquecimentoTypes, ignore.case=T)
  dados$enriquecimentoTypes[is.na(dados$enriquecimentoTypes)] <- "SEMENTIDADES"

  return (dados)
}

getDadosCFS <- function() {
      # con <- dbEscapeStrings(connect(), "new year's")
      dados <- query("SELECT id,
                      drunk AS resposta,
                      textOriginal,
                      hashtags,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(tn.palavra))
                        FROM semantic_tweets_nlp tn
                        WHERE tn.idTweet = t.id
                        AND palavra IN ('/food and drink/beverages/alcoholic beverages/cocktails and beer')
                        GROUP BY tn.idTweet
                      ) AS entidades,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(tn.type))
                        FROM semantic_tweets_nlp tn
                        WHERE tn.idTweet = t.id
                        AND type IS NOT NULL
                        AND type <> ''
                        GROUP BY tn.idTweet
                      ) AS enriquecimentoTypes,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(REPLACE(ty.type, 'http://dbpedia.org/class/', '')))
                        FROM semantic_tweets_nlp tn
                        JOIN semantic_conceito c ON c.palavra = tn.palavra
                        JOIN resource_type ty ON ty.resource = c.resource
                        WHERE tn.idTweet = t.id
                        AND ty.type IN ('http://dbpedia.org/class/yago/WikicatBeerStyles', 'http://dbpedia.org/ontology/Beverage', 'http://dbpedia.org/class/yago/WikicatVirtualCommunities')
                        GROUP BY t.id
                      ) AS types
                      FROM semantic_tweets_alcolic t
                      WHERE situacao = 1
                      AND possuiURL = 0
                      AND LENGTH(textOriginal) > 5
                      -- ORDER by data DESC
                      -- LIMIT 5000
                      ")
      # AND id = 1021368493743255552

  dados$resposta[dados$resposta == "X"] <- 1
  dados$resposta[dados$resposta == "N"] <- 0
  dados$resposta[dados$resposta == "S"] <- 1

  #dados$resposta <- as.factor(dados$resposta)
  dados$resposta <- as.numeric(dados$resposta)
  dados$textOriginal <- enc2utf8(dados$textOriginal)
  dados$textOriginal <- iconv(dados$textOriginal, to='ASCII//TRANSLIT')
  
  dados$textOriginal = gsub("#drunk |#drunk$", "", dados$textOriginal,ignore.case=T)
  dados$textOriginal = gsub("#drank |#drank$", "", dados$textOriginal,ignore.case=T)
  dados$textOriginal = gsub("#imdrunk |#imdrunk$", "", dados$textOriginal,ignore.case=T)

  dados$entidades <- enc2utf8(dados$entidades)
  dados$entidades <- iconv(dados$entidades, to='ASCII//TRANSLIT')
  dados$entidades = gsub(" ", "eee", dados$entidades, ignore.case=T)
  dados$entidades = gsub("[^A-Za-z0-9,_ ]","",dados$entidades, ignore.case=T)
  dados$entidades[is.na(dados$entidades)] <- "SEMENTIDADES"

  dados$types <- enc2utf8(dados$types)
  dados$types <- iconv(dados$types, to='ASCII//TRANSLIT')
  dados$types = gsub(" ", "eee", dados$types, ignore.case=T)
  dados$types = gsub("[^A-Za-z0-9,_ ]","",dados$types, ignore.case=T)
  dados$types[is.na(dados$types)] <- "SEMENTIDADES"

  dados$enriquecimentoTypes <- enc2utf8(dados$enriquecimentoTypes)
  dados$enriquecimentoTypes <- iconv(dados$enriquecimentoTypes, to='ASCII//TRANSLIT')
  dados$enriquecimentoTypes = gsub(" ", "eee", dados$enriquecimentoTypes, ignore.case=T)
  dados$enriquecimentoTypes = gsub("[^A-Za-z0-9,_ ]","",dados$enriquecimentoTypes, ignore.case=T)
  dados$enriquecimentoTypes[is.na(dados$enriquecimentoTypes)] <- "SEMENTIDADES"

  return (dados)
}

getDadosSVM <- function() {
      dados <- query("SELECT id,
                      drunk AS resposta,
                      textOriginal,
                      textSemHashtagsControle as textParser,
                      emoticonPos,
                      emoticonNeg,
                      hashtags,
                      hora,
                      erros as numeroErros,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(tn.palavra))
                        FROM semantic_tweets_nlp tn
                        WHERE tn.idTweet = t.id
                        AND palavra IN ('/art and entertainment', '/art and entertainment/dance', '/art and entertainment/movies and tv/comedies', '/art and entertainment/movies and tv/movies', '/art and entertainment/movies and tv/reality', '/art and entertainment/music', '/art and entertainment/music/recording industry/music awards', '/automotive and vehicles/vehicle brands/acura', '/business and industrial', '/business and industrial/business news', '/family and parenting/children', '/food and drink', '/food and drink/barbecues and grilling', '/food and drink/beverages', '/food and drink/beverages/alcoholic beverages/cocktails and beer', '/food and drink/beverages/alcoholic beverages/wine', '/food and drink/beverages/non alcoholic beverages/bottled water', '/food and drink/beverages/non alcoholic beverages/coffee and tea', '/food and drink/beverages/non alcoholic beverages/soft drinks', '/health and fitness/addiction', '/health and fitness/addiction/alcoholism', '/health and fitness/disease/cold and flu', '/science/chemistry', '/shopping/gifts/party supplies', '/society', '/society/crime/property crime/fraud', '/society/sex', '/society/unrest and war', 'Alcohol intoxication', 'alcohol', 'Alcohol', 'Alcoholic beverage', 'Alcoholism', 'Alternative wine closures', 'America', 'Aquarius Night Club', 'Bar association', 'bar', 'Bar', 'bartender', 'Beauty Bar', 'beer', 'Beer', 'Bill Clinton', 'booze', 'bottle', 'bottles', 'Card game', 'Carter Page', 'champagne', 'Christmas', 'Club Pandora', 'club', 'Club', 'Communist state', 'Conservative Party', 'crown', 'Dean Martin', 'decency', 'Disc jockey', 'Distilled beverage', 'Dm', 'Donald Trump', 'drink', 'Drinking culture', 'drinking game', 'drinking', 'driver', 'drunk', 'Ethanol', 'Federal Bureau of Investigation', 'Fermentation', 'floor', 'glass', 'hangover', 'Hashtag', 'Ideology', 'International Democrat Union', 'Jimmy Carter', 'JobTitle', 'liquor', 'Location', 'Maria Butina', 'mention', 'Mueller', 'NA.', 'New New Year\\'s Day', 'night', 'Nightclub', 'Ohmz', 'party', 'Party', 'Person', 'Political party', 'President of the United States', 'President', 'pub', 'Public house', 'Putin', 'Rd', 'Republicans', 'Reuters', 'RT', 'rum', 'Russia', 'Russians', 'safe way home', 'Saturday', 'Shadow Lounge', 'shot', 'shots', 'Striptease', 'tequila', 'Tequila', 'The Next Episode', 'Thermodynamics', 'Trigraph', 'Trump', 'United States', 'vodka', 'Vodka', 'whiskey', 'White House', 'Wine bottle', 'wine', 'Wine', '/law, govt and politics', '/law, govt and politics/espionage and intelligence/secret service', '/law, govt and politics/espionage and intelligence/surveillance', '/law, govt and politics/espionage and intelligence/terrorism', '/law, govt and politics/government', '/law, govt and politics/government/courts and judiciary', '/law, govt and politics/government/embassies and consulates', '/law, govt and politics/government/executive branch', '/law, govt and politics/immigration', '/law, govt and politics/legal issues/human rights', '/law, govt and politics/politics/elections', '/law, govt and politics/politics/elections/presidential elections', '/law, govt and politics/politics/foreign policy', 'Zone Night Club')
                        GROUP BY tn.idTweet
                      ) AS entidades,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(tn.type))
                        FROM semantic_tweets_nlp tn
                        WHERE tn.idTweet = t.id
                        AND type IS NOT NULL
                        AND type <> ''
                        GROUP BY tn.idTweet
                      ) AS enriquecimentoTypes,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(REPLACE(ty.type, 'http://dbpedia.org/class/', '')))
                        FROM semantic_tweets_nlp tn
                        JOIN semantic_conceito c ON c.palavra = tn.palavra
                        JOIN resource_type ty ON ty.resource = c.resource
                        WHERE tn.idTweet = t.id
                        AND ty.type IN ('http://dbpedia.org/ontology/Beverage', 'http://dbpedia.org/class/yago/WikicatIARCGroup1Carcinogens', 'http://dbpedia.org/class/yago/WikicatDrugsActingOnTheNervousSystem', 'http://dbpedia.org/class/yago/Agent114778436', 'http://dbpedia.org/class/yago/WikicatDrugs', 'http://dbpedia.org/class/yago/Drug103247620', 'http://dbpedia.org/class/yago/Carcinogen114793812', 'http://dbpedia.org/class/yago/Substance100020090', 'http://dbpedia.org/class/yago/Matter100020827', 'http://dbpedia.org/class/yago/WikicatBeerStyles', 'http://dbpedia.org/class/yago/WikicatVirtualCommunities', 'http://dbpedia.org/ontology/RecordLabel', 'http://dbpedia.org/class/yago/Community108223802', 'http://dbpedia.org/class/yago/Gathering107975026', 'http://dbpedia.org/class/yago/Property104916342', 'http://dbpedia.org/class/yago/Manner104928903', 'http://dbpedia.org/class/yago/SocialGroup107950920', 'http://dbpedia.org/class/yago/Attribute100024264', 'http://dbpedia.org/class/yago/Group100031264', 'http://dbpedia.org/class/yago/CausalAgent100007347', 'http://dbpedia.org/ontology/Agent', 'http://dbpedia.org/class/yago/Abstraction100002137', 'http://dbpedia.org/class/yago/PhysicalEntity100001930', 'http://www.ontologydesignpatterns.org/ont/dul/DUL.owl#FunctionalSubstance', 'http://www.wikidata.org/entity/Q2095', 'NA.', 'http://dbpedia.org/class/yago/BroadcastingStation102903405', 'http://dbpedia.org/class/yago/Channel103006398', 'http://dbpedia.org/ontology/Food', 'http://dbpedia.org/class/yago/TelevisionStation104406350', 'http://dbpedia.org/class/yago/WikicatEnglish-languageTelevisionStations', 'http://dbpedia.org/class/yago/WikicatLanguagesOfGhana', 'http://dbpedia.org/class/yago/WikicatLanguagesOfFiji', 'http://dbpedia.org/class/yago/WikicatLanguagesOfGuyana', 'http://dbpedia.org/class/yago/Facility103315023', 'http://dbpedia.org/class/yago/Station104306080', 'http://dbpedia.org/class/yago/WikicatLanguagesOfGuam', 'http://dbpedia.org/class/yago/WikicatLanguagesOfEurope', 'http://dbpedia.org/class/yago/WikicatLanguagesOfGrenada', 'http://dbpedia.org/class/yago/WikicatLanguagesOfJamaica', 'http://dbpedia.org/class/yago/WikicatLanguagesOfDominica', 'http://dbpedia.org/class/yago/WikicatForeignTelevisionChannelsBroadcastingInTheUnitedKingdom', 'http://dbpedia.org/class/yago/WikicatLanguagesOfEritrea', 'http://dbpedia.org/class/yago/WikicatLanguagesOfIreland', 'http://dbpedia.org/class/yago/WikicatLanguagesOfKenya', 'http://dbpedia.org/class/yago/WikicatLanguagesOfHongKong', 'http://dbpedia.org/class/yago/WikicatLanguagesOfIndia', 'http://dbpedia.org/class/yago/WikicatRussian-languageTelevisionStations', 'http://dbpedia.org/class/yago/WikicatInternetTelevisionChannels', 'http://dbpedia.org/class/yago/Employee110053808', 'http://dbpedia.org/class/yago/Adviser109774266', 'http://dbpedia.org/class/yago/Blogger109860415', 'http://dbpedia.org/class/yago/WikicatSpanish-languageTelevisionStations', 'http://dbpedia.org/class/yago/Authority109824361', 'http://dbpedia.org/class/yago/Educator110045713', 'http://dbpedia.org/class/yago/Applicant109607280', 'http://dbpedia.org/class/yago/WikicatLanguagesOfKiribati', 'http://dbpedia.org/class/yago/Capitalist109609232', 'http://dbpedia.org/class/yago/Disputant109615465', 'http://dbpedia.org/class/yago/Billionaire110529684', 'http://dbpedia.org/class/yago/Businessman109882007', 'http://dbpedia.org/class/yago/WikicatTelevisionChannelsAndStationsEstablishedIn2005', 'http://dbpedia.org/class/yago/Executive110069645', 'http://dbpedia.org/class/yago/WikicatTelevisionChannelsInBelgium', 'http://dbpedia.org/class/yago/WikicatTelevisionChannelsInFlanders', 'http://dbpedia.org/class/yago/Associate109816771', 'http://dbpedia.org/class/yago/Businessperson109882716', 'http://dbpedia.org/class/yago/Director110014939', 'http://dbpedia.org/class/yago/WikicatLanguagesOfCyprus', 'http://dbpedia.org/class/yago/WikicatLanguagesOfBrunei', 'http://dbpedia.org/class/yago/WikicatLanguagesOfBermuda', 'http://dbpedia.org/class/yago/Expert109617867', 'http://dbpedia.org/class/yago/WikicatLanguagesOfBelize', 'http://dbpedia.org/class/yago/WikicatLanguagesOfCameroon', 'http://dbpedia.org/class/yago/Beverage107881800', 'http://dbpedia.org/class/yago/Fluid114939900', 'http://dbpedia.org/class/yago/Liquid114940386', 'http://dbpedia.org/class/yago/WikicatLanguagesOfBotswana', 'http://dbpedia.org/class/yago/Alumnus109786338', 'http://dbpedia.org/class/yago/WikicatLanguagesOfBahrain', 'http://dbpedia.org/class/yago/Dancer109989502', 'http://dbpedia.org/class/yago/WikicatLanguagesOfCanada', 'http://dbpedia.org/class/yago/Administrator109770949', 'http://dbpedia.org/class/yago/WikicatLanguagesOfAntiguaAndBarbuda', 'http://dbpedia.org/class/yago/WikicatLanguagesOfAustralia', 'http://dbpedia.org/class/yago/WikicatBarAssociations', 'http://dbpedia.org/class/yago/Association108049401', 'http://dbpedia.org/class/yago/WikicatLegalOrganizations', 'http://dbpedia.org/class/yago/Substance100019613', 'http://dbpedia.org/class/yago/WikicatTelevisionChannelsInTheNetherlands', 'http://dbpedia.org/class/yago/WikicatLanguagesOfAmericanSamoa', 'http://dbpedia.org/class/yago/WikicatLanguagesOfLesotho', 'http://dbpedia.org/class/yago/WikicatLanguagesOfLebanon', 'http://dbpedia.org/class/yago/Entertainer109616922', 'http://dbpedia.org/class/yago/Food100021265', 'http://dbpedia.org/class/yago/WikicatTelevisionStations', 'http://dbpedia.org/class/yago/WikicatMaleDancers', 'http://dbpedia.org/class/yago/Fundraiser110116478', 'http://dbpedia.org/class/yago/Financier110090020', 'http://dbpedia.org/class/yago/WikicatProfessionalAssociations', 'http://dbpedia.org/class/yago/WikicatTelevisionStationsInRussia', 'http://dbpedia.org/class/yago/Hotelier110187990', 'http://dbpedia.org/class/yago/ProfessionalAssociation108242675', 'http://dbpedia.org/class/yago/WikicatLanguages', 'http://dbpedia.org/class/yago/WikicatLanguagesOf', 'http://dbpedia.org/class/yago/WikicatGermanicLanguages', 'http://dbpedia.org/class/yago/Host110187130', 'http://dbpedia.org/class/yago/WikicatFusionalLanguages', 'http://dbpedia.org/class/yago/Performer110415638', 'http://dbpedia.org/class/yago/InvestmentAdviser110215815', 'http://dbpedia.org/class/yago/WikicatNon-alcoholicBeverages', 'http://dbpedia.org/class/yago/Investor110216106', 'http://dbpedia.org/class/yago/Difficulty114408086', 'http://dbpedia.org/class/yago/Part113809207', 'http://dbpedia.org/class/yago/ImportantPerson110200781', 'http://umbel.org/umbel/rc/Drink', 'http://dbpedia.org/class/yago/Problem114410605', 'http://dbpedia.org/class/yago/Merchant110309896', 'http://dbpedia.org/class/yago/Observer110369528', 'http://dbpedia.org/class/yago/Communicator109610660', 'http://dbpedia.org/class/yago/WikicatEnglishLanguages', 'http://dbpedia.org/class/yago/Language106282651', 'http://dbpedia.org/class/yago/Peer109626238', 'http://dbpedi', 'http://dbpedia.org/class/yago/WikicatSocialProblems', 'http://www.wikidata.org/entity/Q12136', 'http://dbpedia.org/class/yago/WikicatRoadsInWales', 'http://dbpedia.org/class/yago/Look100877127', 'http://dbpedia.org/class/yago/Observation100879759', 'http://dbpedia.org/class/yago/Militant110315837', 'http://dbpedia.org/class/yago/LegalHoliday115199592', 'http://dbpedia.org/class/yago/Leisure115137676', 'http://dbpedia.org/class/yago/Holiday115183428', 'http://dbpedia.org/class/yago/Communication100033020', 'http://dbpedia.org/class/yago/DepositoryFinancialInstitution108420278', 'http://dbpedia.org/class/yago/Institute108407330', 'http://dbpedia.org/class/yago/Agreement106770275', 'http://dbpedia.org/class/yago/SensoryActivity100876737', 'http://dbpedia.org/class/yago/Sensing100876874', 'http://dbpedia.org/class/yago/Owner110388924', 'http://dbpedia.org/class/yago/WikicatIntergovernmentalOrganizationsEstablishedByTreaty', 'http://dbpedia.org/class/yago/WikicatBankingInstitutes', 'http://dbpedia.org/class/yago/Treaty106773434', 'http://dbpedia.org/class/yago/WikicatInternationalOrganizationsOfAfrica', 'http://dbpedia.org/class/yago/WikicatBanks', 'http://dbpedia.org/class/yago/WikicatOrganizationsBasedInAfrica', 'http://dbpedia.org/class/yago/WikicatBanksEstablishedIn1964', 'http://dbpedia.org/class/yago/WikicatMultilateralDevelopmentBanks', 'http://dbpedia.org/class/yago/WikicatPrivateCurrencies', 'http://dbpedia.org/class/yago/WikicatOrganizationsBasedInIvoryCoast', 'http://dbpedia.org/class/yago/WikicatInternationalDevelopmentTreaties', 'http://dbpedia.org/class/yago/Adult109605289', 'http://umbel.org/umbel/rc/AilmentCondition', 'http://dbpedia.org/ontology/Disease', 'http://dbpedia.org/class/yago/TimeOff115118453', 'http://dbpedia.org/class/yago/Head110162991', 'http://dbpedia.org/class/yago/WikicatCompaniesEstablishedIn1964', 'http://dbpedia.org/class/yago/Vacation115137890', 'http://dbpedia.org/class/yago/FinancialInstitution108054721', 'http://dbpedia.org/class/yago/Participant110401829', 'http://dbpedia.org/class/yago/InteriorDesigner110210648', 'http://dbpedia.org/class/yago/Intellectual109621545', 'http://dbpedia.org/class/yago/WikicatDistilledBeverages', 'http://dbpedia.org/ontology/Election', 'http://dbpedia.org/class/yago/Festival115162388', 'http://dbpedia.org/class/yago/CalendarDay115157041', 'http://dbpedia.org/class/yago/Day115157225', 'http://dbpedia.org/class/yago/Artifact100021939', 'http://dbpedia.org/class/yago/FundamentalQuantity113575869', 'http://dbpedia.org/class/yago/WikicatMediaCompaniesOfTheUnitedKingdom', 'http://dbpedia.org/class/yago/WikicatNewsAgencies', 'http://dbpedia.org/class/yago/Agency108057206', 'http://dbpedia.org/class/yago/Disease114070360', 'http://dbpedia.org/class/yago/WikicatDecemberObservances', 'http://dbpedia.org/class/yago/NewsAgency108355075', 'http://dbpedia.org/class/yago/WikicatBritishMedia', 'http://dbpedia.org/class/yago/WikicatChristianFestivalsAndHolyDays', 'http://dbpedia.org/class/yago/IllHealth114052046', 'http://dbpedia.org/class/yago/WikicatNewsAgenciesBasedInTheUnitedKingdom', 'http://dbpedia.org/class/yago/LegalDocument106479665', 'http://dbpedia.org/class/yago/WikicatCompaniesEstablishedIn1851', 'http://dbpedia.org/class/yago/Illness114061805', 'http://dbpedia.org/class/yago/WikicatCompaniesOfTheUnitedKingdom', 'http://dbpedia.org/class/yago/PathologicalState114051917', 'http://dbpedia.org/class/yago/PhysicalCondition114034177', 'http://dbpedia.org/class/yago/YagoGeoEntity', 'http://dbpedia.org/class/yago/WikicatMediaCompaniesBasedInLondon', 'http://dbpedia.org/class/yago/WikicatFinancialNewsAgencies', 'http://dbpedia.org/class/yago/Alliance108293982', 'http://dbpedia.org/class/yago/WikicatCentralAsianCountries', 'http://dbpedia.org/class/yago/State100024720', 'http://dbpedia.org/class/yago/Condition113920835', 'http://dbpedia.org/class/yago/TimePeriod115113229', 'http://dbpedia.org/class/yago/Relation100031921', 'http://dbpedia.org/class/yago/Artist109812338', 'http://dbpedia.org/class/yago/Leader109623038', 'http://dbpedia.org/class/yago/Alcohol107884567', 'http://dbpedia.org/class/yago/Diplomat110013927', 'http://dbpedia.org/class/yago/WikicatDiplomatsByRole', 'http://dbpedia.org/class/yago/WikicatEastAsianCountries', 'http://dbpedia.org/class/yago/Composer109947232', 'http://dbpedia.org/class/yago/WikicatHolidays', 'http://dbpedia.org/class/yago/Official110372373', 'http://dbpedia.org/class/yago/Black-footedFerret102443484', 'http://dbpedia.org/class/yago/Carnivore102075296', 'http://dbpedia.org/class/yago/Mamma', 'http://dbpedia.org/class/yago/Musician110339966', 'http://dbpedia.org/class/yago/WikicatComplexityClasses', 'http://dbpedia.org/class/yago/Aesthetic105968971', 'http://dbpedia.org/class/yago/WikicatPublicHolidaysInUkraine', 'http://dbpedia.org/class/yago/WikicatMemberStatesOfTheCommonwealthOfIndependentStates', 'http://dbpedia.org/class/yago/Doctrine105943300', 'http://dbpedia.org/class/yago/WikicatNortheastAsianCountries', 'http://dbpedia.org/class/yago/WikicatNorthAsianCountries', 'http://dbpedia.org/class/yago/Generalization105913275', 'http://dbpedia.org/class/yago/PhilosophicalDoctrine106167328', 'http://dbpedia.org/class/yago/Technique105665146', 'http://dbpedia.org/class/yago/Method105660268', 'http://dbpedia.org/class/yago/Know-how105616786', 'http://dbpedia.org/class/yago/Calendar115173479', 'http://dbpedia.org/class/yago/WikicatAesthetics', 'http://dbpedia.org/class/yago/Principle105913538', 'http://dbpedia.org/class/yago/WikicatSparklingWines', 'http://dbpedia.org/class/yago/SparklingWine107893528', 'http://dbpedia.org/class/yago/WikicatWineStyles', 'http://dbpedia.org/class/yago/WikicatSongwritersFromNewYork', 'http://dbpedia.org/class/yago/WikicatPrinciples', 'http://dbpedia.org/class/yago/WikicatPaintingTechniques', 'http://dbpedia.org/class/yago/WikicatArtisticTechniques', 'http://dbpedia.org/class/yago/Ability105616246', 'http://dbpedia.org/ontology/PopulatedPlace', 'http://dbpedia.org/class/yago/YagoPermanentlyLocatedEntity', 'http://dbpedia.org/class/yago/WikicatPublicHolidaysInRussia', 'http://dbpedia.org/class/yago/WikicatMotorVehicleManufacturersOfJapan', 'http://dbpedia.org/class/yago/Emperor110053004', 'http://dbpedia.org/class/yago/Wine107891726', 'http://dbpedia.org/class/yago/WikicatRussian-speakingCountriesAndTerritories', 'http://dbpedia.org/class/yago/WikicatTelevisionChannelsInTheNether', 'http://dbpedia.org/class/yago/Measure100033615', 'http://dbpedia.org/class/yago/WikicatSlavicCountriesAndTerritories', 'http://dbpedia.org/class/yago/WikicatCompaniesEstablishedIn1986', 'http://dbpedia.org/class/yago/WikicatLanguages', 'http://dbpedia.org/class/yago/DrugOfAbuse103248958', 'http://dbpedia.org/class/yago/Object100002684', 'http://dbpedia.org/class/yago/WikicatAmericanHipHopRecordProducers', 'http://dbpedia.org/class/yago/WikicatStatesAndTerritoriesEstablishedIn1991', 'http://umbel.org/umbel/rc/Currency', 'http://dbpedia.org/class/yago/WikicatStatesAndTerritoriesEstablishedIn862', 'http://dbpedia.org/class/yago/WikicatProf')
                        GROUP BY t.id
                      ) AS types
                      FROM semantic_tweets_alcolic t
                      WHERE situacao = 1
                      AND possuiURL = 0
                      AND LENGTH(textOriginal) > 5
                      -- ORDER by data DESC
                      -- LIMIT 15000
                      ")
      # AND id = 1021368493743255552

  dados$resposta[dados$resposta == "X"] <- 1
  dados$resposta[dados$resposta == "N"] <- 0
  dados$resposta[dados$resposta == "S"] <- 1

  #dados$resposta <- as.factor(dados$resposta)
  dados$resposta <- as.numeric(dados$resposta)
  dados$textOriginal <- enc2utf8(dados$textOriginal)
  dados$textOriginal <- iconv(dados$textOriginal, to='ASCII//TRANSLIT')
  
  dados$textParser <- enc2utf8(dados$textParser)
  dados$textParser <- iconv(dados$textParser, to='ASCII//TRANSLIT')
  
  dados$textOriginal = gsub("#drunk |#drunk$", "", dados$textOriginal,ignore.case=T)
  dados$textOriginal = gsub("#drank |#drank$", "", dados$textOriginal,ignore.case=T)
  dados$textOriginal = gsub("#imdrunk |#imdrunk$", "", dados$textOriginal,ignore.case=T)

  dados$entidades <- enc2utf8(dados$entidades)
  dados$entidades <- iconv(dados$entidades, to='ASCII//TRANSLIT')
  dados$entidades = gsub(" ", "eee", dados$entidades, ignore.case=T)
  dados$entidades = gsub("[^A-Za-z0-9,_ ]","",dados$entidades, ignore.case=T)
  dados$entidades[is.na(dados$entidades)] <- "SEMENTIDADES"

  dados$types <- enc2utf8(dados$types)
  dados$types <- iconv(dados$types, to='ASCII//TRANSLIT')
  dados$types = gsub(" ", "eee", dados$types, ignore.case=T)
  dados$types = gsub("[^A-Za-z0-9,_ ]","",dados$types, ignore.case=T)
  dados$types[is.na(dados$types)] <- "SEMENTIDADES"

  dados$enriquecimentoTypes <- enc2utf8(dados$enriquecimentoTypes)
  dados$enriquecimentoTypes <- iconv(dados$enriquecimentoTypes, to='ASCII//TRANSLIT')
  dados$enriquecimentoTypes = gsub(" ", "eee", dados$enriquecimentoTypes, ignore.case=T)
  dados$enriquecimentoTypes = gsub("[^A-Za-z0-9,_ ]","",dados$enriquecimentoTypes, ignore.case=T)
  dados$enriquecimentoTypes[is.na(dados$enriquecimentoTypes)] <- "SEMENTIDADES"

  return (dados)
}

getDadosSemKeyWords <- function() {
      dados <- query("SELECT id,
                      drunk AS resposta,
                      textSemHashtagsControle as textOriginal,
                      textSemHashtagsControle as textParser,
                      textSemHashtagsControle as textEmbedding,
                      emoticonPos,
                      emoticonNeg,
                      hashtags,
                      hora,
                      erros as numeroErros,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(tn.palavra))
                        FROM semantic_tweets_nlp tn
                        WHERE tn.idTweet = t.id
                        AND palavra IN ('/art and entertainment/dance/pole dancing', '/art and entertainment/shows and events', '/art and entertainment/shows and events/concert', '/automotive and vehicles/auto parts', '/automotive and vehicles/vehicle brands/ferrari', '/finance/financial news', '/finance/investing', '/food and drink', '/food and drink/beverages', '/food and drink/beverages/alcoholic beverages', '/food and drink/beverages/alcoholic beverages/cocktails and beer', '/food and drink/beverages/alcoholic beverages/wine', '/food and drink/beverages/non alcoholic beverages/coffee and tea', '/food and drink/beverages/non alcoholic beverages/soft drinks', '/food and drink/cuisines', '/food and drink/desserts and baking', '/food and drink/food', '/food and drink/food/salads', '/health and fitness/addiction/alcoholism', '/health and fitness/therapy', '/law, govt and politics', '/law, govt and politics/armed forces', '/law, govt and politics/espionage and intelligence', '/law, govt and politics/espionage and intelligence/surveillance', '/law, govt and politics/espionage and intelligence/terrorism', '/law, govt and politics/government', '/law, govt and politics/government/embassies and consulates', '/law, govt and politics/government/executive branch', '/law, govt and politics/government/heads of state', '/law, govt and politics/immigration', '/law, govt and politics/law enforcement', '/law, govt and politics/politics', '/law, govt and politics/politics/elections/presidential elections', '/law, govt and politics/politics/foreign policy', '/law, govt and politics/politics/lobbying', '/news/national news', '/real estate', '/science/medicine/cardiology', '/science/medicine/pharmacology', '/shopping/gifts', '/society/crime/organized crime', '/society/unrest and war', '/technology and computing/computer crime', '/technology and computing/internet technology/social network', '/technology and computing/operating systems', 'Angel4Eva23', 'AshaRangappa', 'Bill Clinton', 'BreathOfWilds', 'Christmas', 'Dean Martin', 'DeanMartin', 'DianaS72910347', 'Donald Trump', 'Drank', 'Drinking', 'Federal Bureau of Investigation', 'First Friday', 'Greeny12', 'Hashtag', 'HaveaPlan', 'IMDRUNK', 'ImDrunk', 'Imdrunk', 'JamesSNW90', 'Jimmy Carter', 'JobTitle', 'Kris', 'Location', 'Maria Butina', 'Mueller', 'NRA', 'New Year', 'New Year\\'s Day', 'Organization', 'Pandora', 'Person', 'President', 'President of the United States', 'Putin', 'Quotes', 'RT', 'RepMattGaetz', 'Republican', 'Reuters', 'Russia', 'Saturday', 'Shadow Lounge', 'Thermodynamics', 'Tonight', 'Trigraph', 'Trump', 'TwitterHandle', 'United Kingdom', 'United States', 'Vegas', 'Week-day names', 'WestcliffOnSea', 'White House', 'Zone', 'Zone/tonight', 'amp', 'bartender', 'beers', 'decency', 'drink', 'drinking', 'drinks', 'driver', 'findom', 'floor', 'friends', 'glass', 'hornyaf', 'imDrunk', 'imdrunk .', 'kylegriffin1', 'last night', 'night', 'robinblackmma', 'safe way', 'shots', 'sorrynotsorry', 'thehill', 'tonight')
                        GROUP BY tn.idTweet
                      ) AS entidades,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(tn.type))
                        FROM semantic_tweets_nlp tn
                        WHERE tn.idTweet = t.id
                        AND type IS NOT NULL
                        AND type <> ''
                        GROUP BY tn.idTweet
                      ) AS enriquecimentoTypes,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(REPLACE(ty.type, 'http://dbpedia.org/class/', '')))
                        FROM semantic_tweets_nlp tn
                        JOIN semantic_conceito c ON c.palavra = tn.palavra
                        JOIN resource_type ty ON ty.resource = c.resource
                        WHERE tn.idTweet = t.id
                        AND ty.type IN ('http://dbpedia.org/ontology/RecordLabel', 'http://dbpedia.org/class/yago/WikicatVirtualCommunities', 'http://dbpedia.org/class/yago/Community108223802', 'http://dbpedia.org/class/yago/Gathering107975026', 'http://dbpedia.org/class/yago/SocialGroup107950920', 'http://dbpedia.org/class/yago/WikicatTelevisionChannelsInFlanders', 'http://dbpedia.org/class/yago/WikicatTelevisionChannelsInTheNetherlands', 'http://dbpedia.org/class/yago/WikicatTelevisionChannelsInBelgium', 'http://dbpedia.org/class/yago/WikicatTelevisionStationsInRussia', 'http://dbpedia.org/class/yago/WikicatInternetTelevisionChannels', 'http://dbpedia.org/class/yago/WikicatTelevisionChannelsAndStationsEstablishedIn2005', 'http://dbpedia.org/class/yago/WikicatForeignTelevisionChannelsBroadcastingInTheUnitedKingdom', 'http://dbpedia.org/class/yago/WikicatRussian-languageTelevisionStations', 'http://dbpedia.org/class/yago/WikicatTelevisionStations', 'http://dbpedia.org/class/yago/WikicatSpanish-languageTelevisionStations', 'http://dbpedia.org/class/yago/WikicatEnglish-languageTelevisionStations', 'http://dbpedia.org/class/yago/TelevisionStation104406350', 'http://dbpedia.org/class/yago/Channel103006398', 'http://schema.org/TelevisionStation', 'http://dbpedia.org/class/yago/BroadcastingStation102903405', 'http://dbpedia.org/class/yago/Station104306080', 'http://www.wikidata.org/entity/Q15265344', 'http://dbpedia.org/class/yago/Facility103315023', 'http://dbpedia.org/ontology/Broadcaster', 'http://dbpedia.org/class/yago/Group100031264', 'http://dbpedia.org/ontology/TelevisionStation', 'http://www.wikidata.org/entity/Q43229', 'http://schema.org/Organization', 'http://www.ontologydesignpatterns.org/ont/dul/DUL.owl#SocialPerson', 'http://dbpedia.org/class/yago/YagoGeoEntity', 'http://dbpedia.org/ontology/Organisation', 'http://www.wikidata.org/entity/Q24229398', 'http://www.ontologydesignpatterns.org/ont/dul/DUL.owl#Agent', 'http://dbpedia.org/class/yago/Artifact100021939', 'http://dbpedia.org/ontology/Agent', 'http://dbpedia.org/class/yago/YagoPermanentlyLocatedEntity', 'http://dbpedia.org/class/yago/Object100002684', 'http://dbpedia.org/class/yago/Whole100003553', 'http://dbpedia.org/class/yago/Abstraction100002137', 'http://dbpedia.org/class/yago/WikicatDrugsActingOnTheNervousSystem', 'http://dbpedia.org/class/yago/WikicatIARCGroup1Carcinogens', 'http://dbpedia.org/class/yago/WikicatDrugs', 'http://dbpedia.org/class/yago/Carcinogen114793812', 'http://dbpedia.org/class/yago/WikicatBeerStyles', 'http://dbpedia.org/class/yago/Drug103247620', 'http://dbpedia.org/class/yago/Agent114778436', 'http://dbpedia.org/ontology/Beverage', 'http://dbpedia.org/class/yago/PhysicalEntity100001930', 'http://dbpedia.org/class/yago/WikicatSocialProblems', 'http://dbpedia.org/class/yago/Difficulty114408086', 'http://dbpedia.org/class/yago/Problem114410605', 'http://dbpedia.org/class/yago/Matter100020827', 'http://dbpedia.org/class/yago/WikicatCountriesInEurope', 'http://dbpedia.org/class/yago/Substance100020090', 'http://dbpedia.org/class/yago/WikicatNortheastAsianCountries', 'http://dbpedia.org/class/yago/WikicatEastAsianCountries', 'http://dbpedia.org/class/yago/WikicatSlavicCountriesAndTerritories', 'http://dbpedia.org/class/yago/WikicatStatesAndTerritoriesEstablishedIn862', 'http://dbpedia.org/class/yago/WikicatStatesAndTerritoriesEstablishedIn1991', 'http://dbpedia.org/class/yago/WikicatCentralAsianCountries', 'http://dbpedia.org/class/yago/WikicatRussian-speakingCountriesAndTerritories', 'http://dbpedia.org/class/yago/WikicatNorthAsianCountries', 'http://dbpedia.org/class/yago/WikicatMemberStatesOfTheCommonwealthOfIndependentStates', 'http://dbpedia.org/class/yago/WikicatCountries', 'http://dbpedia.org/class/yago/WikicatMemberStatesOfTheUnitedNations', 'http://schema.org/Country', 'http://www.wikidata.org/entity/Q6256', 'http://dbpedia.org/class/yago/WikicatFederalCountries', 'http://dbpedia.org/ontology/Country', 'http://dbpedia.org/class/yago/Country108544813', 'http://dbpedia.org/class/yago/Manner104928903', 'http://dbpedia.org/class/yago/Property104916342', 'http://dbpedia.org/class/yago/Region108630985', 'http://dbpedia.org/class/yago/Location100027167', 'http://dbpedia.org/class/yago/AdministrativeDistrict108491826', 'http://dbpedia.org/class/yago/District108552138', 'http://dbpedia.org/class/yago/WikicatElectionsInTheUnitedStates', 'http://dbpedia.org/class/yago/WikicatPresidentialElectionsInTheUnitedStates', 'http://dbpedia.org/class/yago/Disease114070360', 'http://dbpedia.org/class/yago/IllHealth114052046', 'http://dbpedia.org/class/yago/PathologicalState114051917', 'http://dbpedia.org/class/yago/Illness114061805', 'http://dbpedia.org/class/yago/PhysicalCondition114034177', 'http://dbpedia.org/class/yago/Vote100182213', 'http://dbpedia.org/class/yago/Election100181781', 'http://dbpedia.org/class/yago/Condition113920835', 'http://dbpedia.org/class/yago/GroupAction101080366', 'http://dbpedia.org/class/yago/Professional110480253', 'http://dbpedia.org/class/yago/State100024720', 'http://dbpedia.org/ontology/Place', 'http://schema.org/Place', 'http://dbpedia.org/ontology/Location', 'http://dbpedia.org/class/yago/Attribute100024264', 'http://dbpedia.org/class/yago/Sensing100876874', 'http://dbpedia.org/class/yago/SensoryActivity100876737', 'http://dbpedia.org/class/yago/Look100877127', 'http://dbpedia.org/class/yago/Observation100879759', 'http://dbpedia.org/class/yago/Holiday115183428', 'http://dbpedia.org/class/yago/WikicatHolidays', 'http://dbpedia.org/class/yago/LegalHoliday115199592', 'http://dbpedia.org/ontology/Food', 'http://dbpedia.org/class/yago/Expert109617867', 'http://dbpedia.org/class/yago/TimeOff115118453', 'http://dbpedia.org/class/yago/Vacation115137890', 'http://dbpedia.org/class/yago/Leisure115137676', 'http://dbpedia.org/class/yago/Adviser109774266', 'http://dbpedia.org/class/yago/Authority109824361', 'http://dbpedia.org/class/yago/WikicatConspiracyTheorists', 'http://www.w3.org/2003/01/geo/wgs84_pos#SpatialThing', 'http://dbpedia.org/class/yago/Educator110045713', 'http://dbpedia.org/class/yago/Observer110369528', 'http://dbpedia.org/class/yago/Theorist110706812', 'http://www.ontologydesignpatterns.org/ont/dul/DUL.owl#FunctionalSubstance', 'http://www.wikidata.org/entity/Q2095', 'http://dbpedia.org/class/yago/WikicatPeopleFromManhattan', 'http://dbpedia.org/class/yago/WikicatWritersFromNewYorkCity', 'http://dbpedia.org/class/yago/WikicatAmericanInvestors', 'http://dbpedia.org/class/yago/WikicatWritersFromFlorida', 'http://dbpedia.org/class/yago/WikicatAmericanGameShowHosts', 'http://dbpedia.org/class/yago/WikicatFordhamUniversityAlumni', 'http://dbpedia.org/class/yago/WikicatAmericanBusinessWriters', 'http://dbpedia.org/class/yago/Hotelier110187990', 'http://dbpedia.org/class/yago/WikicatBoardGameDesigners', 'http://dbpedia.org/class/yago/WikicatAmericanFinanciers', 'http://dbpedia.org/class/yago/WikicatAmericanFinancialLiteracyActivists', 'http://dbpedia.org/class/yago/WikicatAmericanFinancialCommentators', 'http://dbpedia.org/class/yago/WikicatAmericanAirlineChiefExecutives', 'http://dbpedia.org/class/yago/Restaurateur110524869', 'http://dbpedia.org/class/yago/WikicatAmericanPoliticalFundraisers', 'http://dbpedia.org/class/yago/WikicatAmericanBeautyPageantOwners', 'http://dbpedia.org/class/yago/WikicatBusinessEducators', 'http://dbpedia.org/class/yago/WikicatPeopleFromPalmBeach,Florida', 'http://dbpedia.org/class/yago/WikicatAmericanStockTraders', 'http://dbpedia.org/class/yago/Trader110720453', 'http://dbpedia.org/class/yago/Solicitor110623354', 'http://dbpedia.org/class/yago/InvestmentAdviser110215815', 'http://dbpedia.org/class/yago/WikicatAmericanRestaurateurs', 'http://dbpedia.org/class/yago/WikicatAmericanInvestmentAdvisors', 'http://dbpedia.org/class/yago/WikicatChiefExecutives', 'http://dbpedia.org/class/yago/WikicatNewYorkMilitaryAcademyAlumni', 'http://dbpedia.org/class/yago/WikicatUnitedStatesFootballLeagueExecutives', 'http://dbpedia.org/class/yago/WikicatAmericanHoteliers', 'http://dbpedia.org/class/yago/StockTrader110657835', 'http://dbpedia.org/class/yago/WikicatTheTrumpOrganizationEmployees', 'http://dbpedia.org/class/yago/Fundraiser110116478', 'http://dbpedia.org/class/yago/Petitioner110420031', 'http://dbpedia.org/class/yago/Financier110090020', 'http://dbpedia.org/class/yago/WikicatTelevisionProducersFromNewYork', 'http://dbpedia.org/class/yago/WikicatPeopleFromQueens,NewYork', 'http://dbpedia.org/class/yago/WikicatAmericanVideoGameDesigners', 'http://dbpedia.org/class/yago/WikicatAmericanRadioProducers', 'http://dbpedia.org/class/yago/Applicant109607280', 'http://dbpedia.org/class/yago/WikicatAmericanRealityTelevisionProducers', 'http://dbpedia.org/class/yago/WikicatAmericanTelevisionDirectors', 'http://dbpedia.org/class/yago/Merchant110309896', 'http://dbpedia.org/class/yago/WikicatMemberStatesOfNATO', 'http://dbpedia.org/ontology/Band', 'http://dbpedia.org/class/yago/Blogger109860415', 'http://dbpedia.org/class/yago/Investor110216106', 'http://dbpedia.org/class/yago/Employee110053808', 'http://dbpedia.org/class/yago/WikicatAmericanBloggers', 'http://dbpedia.org/class/yago/WikicatPeopleFromNewYorkCity', 'http://dbpedia.org/class/yago/InteriorDesigner110210648', 'http://dbpedia.org/class/yago/Specialist110631941', 'http://dbpedia.org/class/yago/Socialite110619409', 'http://dbpedia.org/class/yago/WikicatAmericanSocialites', 'http://dbpedia.org/class/yago/ImportantPerson110200781', 'http://dbpedia.org/class/yago/WikicatRoadsInWales', 'http://dbpedia.org/class/yago/Host110187130', 'http://dbpedia.org/class/yago/WikicatAmericanTelevisionHosts', 'http://dbpedia.org/class/yago/WikicatParticipantsInAmericanRealityTelevisionSeries', 'http://dbpedia.org/class/yago/Disputant109615465', 'http://dbpedia.org/class/yago/Reformer110515194', 'http://dbpedia.org/class/yago/WikicatAmericanTelevisionProducers', 'http://dbpedia.org/class/yago/Wikicat21st-centuryAmericanWriters', 'http://dbpedia.org/class/yago/Capitalist109609232', 'http://dbpedia.org/class/yago/WikicatChristianFestivalsAndHolyDays', 'http://dbpedia.org/class/yago/Businessperson109882716', 'http://dbpedia.org/class/yago/Militant110315837', 'http://dbpedia.org/class/yago/Executive110069645', 'http://dbpedia.org/class/yago/WikicatPublicHolidaysInUkraine', 'http://dbpedia.org/class/yago/WikicatAmericanPeopleOfGermanDescent', 'http://dbpedia.org/class/yago/WikicatAmericanPeopleOfScottishDescent', 'http://dbpedia.org/class/yago/Owner110388924', 'http://dbpedia.org/class/yago/Businessman109882007', 'http://dbpedia.org/class/yago/WikicatPeopleFromNewYork', 'http://dbpedia.org/class/yago/WikicatEnglish-speakingCountriesAndTerritories', 'http://dbpedia.org/class/yago/WikicatAmericanChiefExecutives', 'http://dbpedia.org/class/yago/Day115157225', 'http://dbpedia.org/class/yago/CalendarDay115157041', 'http://www.wikidata.org/entity/Q12136', 'http://dbpedia.org/class/yago/Peer109626238', 'http://dbpedia.org/class/yago/Associate109816771', 'http://umbel.org/umbel/rc/AilmentCondition', 'http://dbpedia.org/class/yago/Festival115162388', 'http://dbpedia.org/class/yago/Participant110401829', 'http://dbpedia.org/class/yago/Worker109632518', 'http://dbpedia.org/class/yago/TimePeriod115113229', 'http://dbpedia.org/class/yago/FundamentalQuantity113575869', 'http://dbpedia.org/class/yago/Billionaire110529684', 'http://dbpedia.org/class/yago/RichPerson110529231', 'http://dbpedia.org/class/yago/WikicatGovernmentInstitutions', 'http://dbpedia.org/class/yago/ExecutiveBranch108356074', 'http://dbpedia.org/class/yago/WikicatExecutiveBranchesOfGovernment', 'http://dbpedia.org/class/yago/WikicatAmericanBillionaires', 'http://dbpedia.org/ontology/SocietalEvent', 'http://dbpedia.org/class/yago/AdministrativeUnit108077292', 'http://dbpedia.org/class/yago/Intellectual109621545', 'http://dbpedia.org/class/yago/Scholar110557854', 'http://dbpedia.org/class/yago/Division108220714', 'http://dbpedia.org/class/yago/Branch108401248', 'http://www.wikidata.org/entity/Q1445650', 'http://dbpedia.org/class/yago/WikicatCountriesInOceania', 'http://dbpedia.org/class/yago/WikicatUnitedStates', 'http://dbpedia.org/class/yago/Wikicat20th-centuryAmericanWriters', 'http://dbpedia.org/class/yago/WikicatPublicHolidaysInRussia', 'http://dbpedia.org/class/yago/WikicatDecemberObservances', 'http://dbpedia.org/class/yago/WikicatStatesAndTerritoriesEstablishedIn1776', 'http://dbpedia.org/class/yago/YagoLegalActorGeo', 'http://www.ontologydesignpatterns.org/ont/dul/DUL.owl#TimeInterval', 'http://dbpedia.org/class/yago/Communicator109610660', 'http://dbpedia.org/class/yago/Food100021265', 'http://dbpedia.org/ontology/Disease', 'http://dbpedia.org/class/yago/Measure100033615', 'http://dbpedia.org/class/yago/Writer110794014', 'http://dbpedia.org/class/yago/Unit108189659', 'http://dbpedia.org/class/yago/Head110162991', 'http://dbpedia.org/class/yago/Alumnus109786338', 'http://dbpedia.org/class/yago/Leader109623038', 'http://dbpedia.org/class/yago/Administrator109770949', 'http://dbpedia.org/class/yago/WikicatFinancialNewsAgencies', 'http://dbpedia.org/class/yago/WikicatNewsAgenciesBasedInTheUnitedKingdom', 'http://dbpedia.org/class/yago/NewsAgency108355075', 'http://dbpedia.org/class/yago/WikicatNewsAgencies', 'http://dbpedia.org/class/yago/Agency108057206', 'http://dbpedia.org/class/yago/WikicatCompaniesEstablishedIn1851', 'http://dbpedia.org/class/yago/WikicatMediaCompaniesBasedInLondon', 'http://dbpedia.org/class/yago/WikicatBritishMedia', 'http://dbpedia.org/class/yago/WikicatAmericanPeople', 'http://dbpedia.org/class/yago/Adult109605289', 'http://dbpedia.org/class/yago/WikicatLanguagesOfCameroon', 'http://dbpedia.org/class/yago/WikicatLanguagesOfSeychelles', 'http://dbpedia.org/class/yago/WikicatLanguagesOfLebanon', 'http://dbpedia.org/class/yago/WikicatLanguagesOfCyprus', 'http://dbpedia.org/class/yago/WikicatLanguagesOfCanada', 'http://dbpedia.org/class/yago/WikicatLanguagesOfVanuatu', 'http://dbpedia.org/class/yago/WikicatLanguagesOfMauritius', 'http://dbpedia.org/class/yago/WikicatLanguagesOfRwanda', 'http://dbpedia.org/class/yago/WikicatLanguagesOfTheSolomonIslands', 'http://dbpedia.org/class/yago/WikicatLanguagesOfTheCaymanIslands', 'http://dbpedia.org/class/yago/WikicatLanguagesOfSouthSudan', 'http://dbpedia.org/class/yago/WikicatLanguagesOfSamoa', 'http://dbpedia.org/class/yago/WikicatLanguagesOfMalta', 'http://dbpedia.org/class/yago/WikicatLanguagesOfHongKong', 'http://dbpedia.org/class/yago/WikicatLanguagesOfPalau', 'http://dbpedia.org/class/yago/WikicatEnglishLanguages', 'http://dbpedia.org/class/yago/WikicatLanguagesOfUganda', 'http://dbpedia.org/class/yago/WikicatLanguagesOfNauru', 'http://dbpedia.org/class/yago/WikicatLanguagesOfSaintKittsAndNevis', 'http://dbpedia.org/class/yago/WikicatLanguagesOfLiberia', 'http://dbpedia.org/class/yago/WikicatLanguagesOfSudan', 'http://dbpedia.org/class/yago/WikicatLanguagesOfTokelau', 'http://dbpedia.org/class/yago/WikicatLanguagesOfKiribati', 'http://dbpedia.org/class/yago/WikicatLanguagesOfTheGambia', 'http://dbpedia.org/class/yago/WikicatLanguagesOfTheUnitedStatesVirginIslands', 'http://dbpedia.org/class/yago/WikicatLanguagesOfNewZealand', 'http://dbpedia.org/class/yago/WikicatLanguagesOfTheMarshallIslands', 'http://dbpedia.org/class/yago/WikicatLanguagesOfTheBritishVirginIslands', 'http://dbpedia.org/class/yago/WikicatWestGermanicLanguages', 'http://dbpedia.org/class/yago/WikicatLanguagesOfSaintVincentAndTheGrenadines', 'http://dbpedia.org/class/yago/WikicatLanguagesOfGuyana', 'http://dbpedia.org/class/yago/WikicatLanguagesOfGuam', 'http://dbpedia.org/class/yago/WikicatLanguagesOfTheFederatedStatesOfMicronesia', 'http://dbpedia.org/class/yago/WikicatLanguagesOfBotswana', 'http://dbpedia.org/class/yago/WikicatLanguagesOfIndia', 'http://dbpedia.org/class/yago/WikicatLanguagesOfKenya', 'http://dbpedia.org/class/yago/WikicatLanguagesOfTheBahamas', 'http://dbpedia.org/class/yago/WikicatLanguagesOfBrunei', 'http://dbpedia.org/class/yago/WikicatLanguagesOfFiji', 'http://dbpedia.org/class/yago/WikicatLanguagesOfDominica', 'http://dbpedia.org/class/yago/WikicatLanguagesOfNamibia', 'http://dbpedia.org/class/yago/WikicatLanguagesOfSingapore', 'http://dbpedia.org/class/yago/WikicatLanguagesOfNiue', 'http://dbpedia.org/class/yago/WikicatLanguagesOfBahrain', 'http://dbpedia.org/class/yago/WikicatLanguagesOfZimbabwe', 'http://dbpedia.org/class/yago/WikicatLanguagesOfSaintLucia', 'http://dbpedia.org/class/yago/WikicatLanguagesOfTheCookIslands', 'http://dbpedia.org/class/yago/WikicatLanguagesOfAmericanSamoa', 'http://dbpedia.org/class/yago/WikicatLanguagesOfJamaica', 'http://dbpedia.org/class/yago/WikicatLanguagesOfThePitcairnIslands', 'http://dbpedia.org/class/yago/WikicatLanguagesOfMalaysia', 'http://dbpedia.org/class/yago/WikicatLanguagesOfSwaziland', 'http://dbpedia.org/class/yago/WikicatLanguagesOfPapuaNewGuinea', 'http://dbpedia.org/class/yago/WikicatLanguagesOfZambia', 'http://dbpedia.org/class/yago/WikicatLanguagesOfAntiguaAndBarbuda', 'http://dbpedia.org/class/yago/WikicatLanguagesOfPakistan', 'http://dbpedia.org/class/yago/WikicatLanguagesOfMalawi', 'http://dbpedia.org/class/yago/WikicatLanguagesOfSouthAfrica', 'http://dbpedia.org/class/yago/WikicatLanguagesOfTuvalu', 'http://dbpedia.org/class/yago/WikicatLanguagesOfBermuda', 'http://dbpedia.org/class/yago/WikicatGermanicLanguages', 'http://dbpedia.org/class/yago/WikicatLanguagesOfGhana', 'http://dbpedia.org/class/yago/WikicatLanguagesOfAustralia', 'http://dbpedia.org/class/yago/WikicatLanguagesOfTonga', 'http://dbpedia.org/class/yago/WikicatLanguagesOfLesotho', 'http://dbpedia.org/class/yago/WikicatLanguagesOfGrenada', 'http://dbpedia.org/class/yago/WikicatLanguagesOfSierraLeone', 'http://dbpedia.org/class/yago/WikicatLanguagesOfNigeria', 'http://dbpedia.org/class/yago/WikicatStress-timedLanguages', 'http://dbpedia.org/class/yago/WikicatFusionalLanguages', 'http://dbpedia.org/class/yago/WikicatLanguagesOfEurope', 'http://dbpedia.org/class/yago/WikicatSubject–verb–objectLanguages', 'http://dbpedia.org/class/yago/WikicatLanguagesOfEritrea', 'http://dbpedia.org/class/yago/WikicatLanguagesOfTheUnitedKingdom', 'http://dbpedia.org/class/yago/WikicatLanguagesOfIreland', 'http://dbpedia.org/class/yago/WikicatLanguagesOfBelize', 'http://dbpedia.org/class/yago/WikicatLanguagesOfTrinidadAndTobago', 'http://dbpedia.org/class/yago/WikicatLanguagesOfThePhilippines', 'http://umbel.org/umbel/rc/PersonWithOccupation', 'http://dbpedia.org/class/yago/WikicatLanguages', 'http://schema.org/Language', 'http://www.wikidata.org/entity/Q315', 'http://www.wikidata.org/entity/Q34770', 'http://dbpedia.org/class/yago/Language106282651', 'http://dbpedia.org/class/yago/WikicatRoadsInEngland', 'http://dbpedia.org/class/yago/WikicatLanguagesOfTheUnitedStates', 'http://dbpedia.org/ontology/Language', 'http://dbpedia.org/class/yago/WikicatMediaCompaniesOfTheUnitedKingdom', 'http://dbpedia.org/class/yago/WikicatCompaniesOfTheUnitedKingdom', 'http://dbpedia.org/class/yago/Director110014939', 'http://dbpedia.org/class/yago/Calendar115173479', 'http://dbpedia.org/class/yago/WikicatCalendars', 'http://dbpedia.org/ontology/GolfCourse', 'http://dbpedia.org/class/yago/Salad107806221', 'http://dbpedia.org/class/yago/WikicatSalads', 'http://dbpedia.org/class/yago/Dish107557434', 'http://dbpedia.org/class/yago/Act100030358', 'http://dbpedia.org/ontology/PopulatedPlace', 'http://dbpedia.org/class/yago/Aesthetic105968971', 'http://dbpedia.org/class/yago/PhilosophicalDoctrine106167328', 'http://dbpedia.org/class/yago/WikicatPaintingTechniques', 'http://dbpedia.org/class/yago/WikicatArtisticTechniques', 'http://dbpedia.org/class/yago/WikicatAesthetics', 'http://dbpedia.org/class/yago/WikicatPrinciples', 'http://dbpedia.org/class/yago/Principle105913538', 'http://dbpedia.org/class/yago/Generalization105913275', 'http://dbpedia.org/class/yago/Doctrine105943300', 'http://dbpedia.org/class/yago/Technique105665146', 'http://dbpedia.org/ontology/Book', 'http://dbpedia.org/class/yago/WikicatMemberStatesOfTheUnionForTheMediterranean', 'http://dbpedia.org/class/yago/Nutriment107570720', 'http://dbpedia.org/class/yago/Method105660268', 'http://dbpedia.org/class/yago/Know-how105616786', 'http://dbpedia.org/class/yago/Arrangement105726596', 'http://dbpedia.org/class/yago/Structure105726345', 'http://dbpedia.org/class/yago/Event100029378', 'http://dbpedia.org/class/yago/Communication100033020', 'http://dbpedia.org/class/yago/WikicatMemberStatesOfTheEuropeanUnion', 'http://dbpedia.org/class/yago/WikicatMaleDancers', 'http://dbpedia.org/class/yago/Diplomat110013927', 'http://dbpedia.org/class/yago/WikicatSecularHolidays', 'http://dbpedia.org/class/yago/WikicatJanuaryObservances', 'http://dbpedia.org/class/yago/Lobbyist110268629', 'http://dbpedia.org/class/yago/Persuader110418841', 'http://umbel.org/umbel/rc/MusicalComposition', 'http://dbpedia.org/ontology/OfficeHolder', 'http://dbpedia.org/class/yago/Road104096066', 'http://dbpedia.org/class/yago/Ability105616246', 'http://dbpedia.org/class/yago/Dance107020538', 'http://dbpedia.org/class/yago/WikicatDances', 'http://dbpedia.org/class/yago/WikicatPublicHolidaysInTheUnitedStates', 'http://dbpedia.org/class/yago/Way104564698', 'http://dbpedia.org/class/yago/WikicatFictionalEmperorsAndEmpresses', 'http://dbpedia.org/class/yago/MustelineMammal102441326', 'http://dbpedia.org/class/yago/Black-footedFerret102443484', 'http://dbpedia.org/class/yago/WikicatFictionalFerrets', 'http://dbpedia.org/class/yago/Lawyer110249950', 'http://dbpedia.org/class/yago/Affair107447261', 'http://dbpedia.org/class/yago/WikicatNewYearCelebrations', 'http://dbpedia.org/class/yago/Celebration107450651', 'http://dbpedia.org/class/yago/WikicatMemberStatesOfTheCouncilOfEurope', 'http://dbpedia.org/class/yago/Idea105833840', 'http://dbpedia.org/class/yago/Official110372373', 'http://dbpedia.org/ontology/Election', 'http://dbpedia.org/class/yago/Accomplishment100035189', 'http://schema.org/Person', 'http://www.wikidata.org/entity/Q215627', 'http://www.wikidata.org/entity/Q5', 'http://www.ontologydesignpatterns.org/ont/dul/DUL.owl#NaturalPerson', 'http://xmlns.com/foaf/0.1/Person', 'http://dbpedia.org/class/yago/WikicatComputerSecurityExploits', 'http://dbpedia.org/class/yago/Feat100036762', 'http://dbpedia.org/class/yago/WikicatMonotheisticReligions', 'http://dbpedia.org/class/yago/WikicatAbrahamicReligions', 'http://dbpedia.org/class/yago/Substance100019613', 'http://dbpedia.org/class/yago/Institution108053576', 'http://dbpedia.org/class/yago/WikicatLobbyists', 'http://umbel.org/umbel/rc/Sport', 'http://www.w3.org/2002/07/owl#Thing', 'http://dbpedia.org/class/yago/Entertainer109616922', 'http://dbpedia.org/class/yago/Dancer109989502', 'http://umbel.org/umbel/rc/Action', 'http://dbpedia.org/class/yago/WikicatNon-alcoholicBeverages', 'http://dbpedia.org/class/yago/Scientist110560637', 'http://dbpedia.org/class/yago/Carnivore102075296', 'http://dbpedia.org/class/yago/Mammal101861778', 'http://dbpedia.org/class/yago/Placental101886756', 'http://dbpedia.org/ontology/Album', 'http://dbpedia.org/class/yago/Performer110415638', 'http://dbpedia.org/ontology/Holiday', 'http://dbpedia.org/class/yago/WikicatBritishIslands', 'http://dbpedia.org/class/yago/WikicatUnitsOfTime', 'http://dbpedia.org/class/yago/TimeUnit115154774', 'http://dbpedia.org/class/yago/Day115155220', 'http://dbpedia.org/class/yago/WikicatDays', 'http://dbpedia.org/class/yago/WikicatDaysOfTheWeek', 'http://dbpedia.org/class/yago/Maker110284064', 'http://dbpedia.org/class/yago/Manufacturer110292316', 'http://dbpedia.org/class/yago/Quality104723816', 'http://umbel.org/umbel/rc/Drink', 'http://dbpedia.org/class/yago/WikicatRoadsInKent', 'http://dbpedia.org/class/yago/Occupation100582388', 'http://dbpedia.org/class/yago/WikicatNetworks', 'http://dbpedia.org/class/yago/SocialOrganization108378819', 'http://dbpedia.org/class/yago/WikicatSocialSystems', 'http://dbpedia.org/class/yago/WikicatSociologicalTheories', 'http://dbpedia.org/class/yago/Morality104846770', 'http://dbpedia.org/class/yago/Virtue104847482', 'http://dbpedia.org/class/yago/Good104849241', 'http://dbpedia.org/class/yago/TheologicalVirtue104847991', 'http://dbpedia.org/class/yago/Religion105946687', 'http://dbpedia.org/class/yago/CardinalVirtue104847600', 'http://dbpedia.org/class/yago/WikicatDiplomatsByRole', 'http://dbpedia.org/class/yago/WikicatCitiesInEurope', 'http://dbpedia.org/class/yago/WikicatMarchObservances')
                        GROUP BY t.id
                      ) AS types
                      FROM semantic_tweets_alcolic t
                      WHERE situacao = 1
                      AND possuiURL = 0
                      AND LENGTH(textOriginal) > 5
                      -- ORDER by data DESC
                      -- LIMIT 15000
                      ")
      # AND id = 1021368493743255552

  dados$resposta[dados$resposta == "X"] <- 1
  dados$resposta[dados$resposta == "N"] <- 0
  dados$resposta[dados$resposta == "S"] <- 1

  #dados$resposta <- as.factor(dados$resposta)
  dados$resposta <- as.numeric(dados$resposta)
  dados$textOriginal <- enc2utf8(dados$textOriginal)
  dados$textOriginal <- iconv(dados$textOriginal, to='ASCII//TRANSLIT')
  
  dados$textParser <- enc2utf8(dados$textParser)
  dados$textParser <- iconv(dados$textParser, to='ASCII//TRANSLIT')
  
  dados$textOriginal = gsub("#drunk |#drunk$", "", dados$textOriginal,ignore.case=T)
  dados$textOriginal = gsub("#drank |#drank$", "", dados$textOriginal,ignore.case=T)
  dados$textOriginal = gsub("#imdrunk |#imdrunk$", "", dados$textOriginal,ignore.case=T)

  dados$entidades <- enc2utf8(dados$entidades)
  dados$entidades <- iconv(dados$entidades, to='ASCII//TRANSLIT')
  dados$entidades = gsub(" ", "eee", dados$entidades, ignore.case=T)
  dados$entidades = gsub("[^A-Za-z0-9,_ ]","",dados$entidades, ignore.case=T)
  dados$entidades[is.na(dados$entidades)] <- "SEMENTIDADES"

  dados$types <- enc2utf8(dados$types)
  dados$types <- iconv(dados$types, to='ASCII//TRANSLIT')
  dados$types = gsub(" ", "eee", dados$types, ignore.case=T)
  dados$types = gsub("[^A-Za-z0-9,_ ]","",dados$types, ignore.case=T)
  dados$types[is.na(dados$types)] <- "SEMENTIDADES"

  dados$enriquecimentoTypes <- enc2utf8(dados$enriquecimentoTypes)
  dados$enriquecimentoTypes <- iconv(dados$enriquecimentoTypes, to='ASCII//TRANSLIT')
  dados$enriquecimentoTypes = gsub(" ", "eee", dados$enriquecimentoTypes, ignore.case=T)
  dados$enriquecimentoTypes = gsub("[^A-Za-z0-9,_ ]","",dados$enriquecimentoTypes, ignore.case=T)
  dados$enriquecimentoTypes[is.na(dados$enriquecimentoTypes)] <- "SEMENTIDADES"

  return (dados)
}

getDadosSVMBaseline <- function() {
      dados <- query("SELECT id,
                      drunk AS resposta,
                      textOriginal,
                      textSemHashtagsControle as textParser,
                      emoticonPos,
                      emoticonNeg,
                      hashtags
                      FROM semantic_tweets_alcolic t
                      WHERE situacao = 1
                      AND possuiURL = 0
                      AND LENGTH(textOriginal) > 5
                      ")

  dados$resposta[dados$resposta == "X"] <- 1
  dados$resposta[dados$resposta == "N"] <- 0
  dados$resposta[dados$resposta == "S"] <- 1

  #dados$resposta <- as.factor(dados$resposta)
  dados$resposta <- as.numeric(dados$resposta)
  dados$textOriginal <- enc2utf8(dados$textOriginal)
  dados$textOriginal <- iconv(dados$textOriginal, to='ASCII//TRANSLIT')
  
  dados$textParser <- enc2utf8(dados$textParser)
  dados$textParser <- iconv(dados$textParser, to='ASCII//TRANSLIT')
  
  dados$textOriginal = gsub("#drunk |#drunk$", "", dados$textOriginal,ignore.case=T)
  dados$textOriginal = gsub("#drank |#drank$", "", dados$textOriginal,ignore.case=T)
  dados$textOriginal = gsub("#imdrunk |#imdrunk$", "", dados$textOriginal,ignore.case=T)
  return (dados)
}

getDadosSemHashtags <- function() {
  dados <- query("SELECT drunk AS resposta,
                      textOriginal,
                      hashtags
                      FROM semantic_tweets_alcolic
                      WHERE situacao = 1
                      AND possuiURL = 0
                      AND LENGTH(textOriginal) > 5
                      ")

  dados$resposta[dados$resposta == "X"] <- 1
  dados$resposta[dados$resposta == "N"] <- 0
  dados$resposta[dados$resposta == "S"] <- 1

  dados$resposta <- as.numeric(dados$resposta)
  dados$textOriginal <- enc2utf8(dados$textOriginal)
  dados$textOriginal <- iconv(dados$textOriginal, to='ASCII//TRANSLIT')
  
  dados$textOriginal = gsub("#drunk |#drunk$", "", dados$textOriginal,ignore.case=T)
  dados$textOriginal = gsub("#drank |#drank$", "", dados$textOriginal,ignore.case=T)
  dados$textOriginal = gsub("#imdrunk |#imdrunk$", "", dados$textOriginal,ignore.case=T)
  return (dados)
}

processarDados <- function(textParser, maxlen, max_words) {
  onlyTexts <- textParser
  texts <- as.character(as.matrix(onlyTexts))
  tokenizer <- text_tokenizer(num_words = max_words) %>%
    fit_text_tokenizer(texts)
  
  sequences <- texts_to_sequences(tokenizer, texts)
  word_index = tokenizer$word_index
  cat("Found", length(word_index), "unique tokens.\n")
  data <- pad_sequences(sequences, maxlen = maxlen)
  
  cat("Shape of data tensor:", dim(data), "\n")
  return (data);
}

processarSequence <- function(textParser, max_words) {
  onlyTexts <- textParser
  texts <- as.character(as.matrix(onlyTexts))
  tokenizer <- text_tokenizer(num_words = max_words) %>%
    fit_text_tokenizer(texts)
  
  sequences <- texts_to_sequences(tokenizer, texts)
  return (sequences);
}

processarSequenceByCharacter <- function(textParser, maxlen, max_words) {
  onlyTexts <- textParser
  texts <- as.character(as.matrix(onlyTexts))
  tokenizer <- text_tokenizer(num_words = max_words, char_level=1) %>%
    fit_text_tokenizer(texts)
  
  #word_index = tokenizer$word_index
  #cat("Found", length(word_index), "unique tokens.\n")

  sequences <- texts_to_sequences(tokenizer, texts)
  return (sequences);
}

obterMetricas <- function(predictions, y_test) {
  pred <- prediction(predictions, y_test);

  acc.tmp <- performance(pred,"acc");
  ind = which.max(slot(acc.tmp, "y.values")[[1]])
  acc = slot(acc.tmp, "y.values")[[1]][ind]

  prec.tmp <- performance(pred,"prec");
  ind = which.max(slot(prec.tmp, "y.values")[[1]])
  prec = slot(prec.tmp, "y.values")[[1]][ind]

  rec.tmp <- performance(pred,"rec");
  ind = which.max(slot(rec.tmp, "y.values")[[1]])
  rec = slot(rec.tmp, "y.values")[[1]][ind]

  print(paste0("Acuracia ", acc))
  print(paste0("Recall ", rec))
  print(paste0("Precisao ", prec))
}

avaliacaoFinal <- function(model, x_test, y_test) {
  results <- model %>% evaluate(x_test, y_test)
  print(results)
  predictions <- model %>% predict_classes(x_test)
 
  matriz <- confusionMatrix(data = as.factor(predictions), as.factor(y_test), positive="1")
  print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))
  return (results)
}

#library(tools)
#library(keras)

#set.seed(10)

#source(file_path_as_absolute("redesneurais/getDados.R"))

#resultados <- data.frame(matrix(ncol = 4, nrow = 0))
#names(resultados) <- c("Técnica", "InputDim", "OutputDim", "Epochs", "Batch", "F1", "Precisão", "Revocação", "Acuracia")

avaliacaoFinalSave <- function(model, x_test, y_test, history, tecnica, InputDim, OutputDim, features, iteracao) {
  results <- model %>% evaluate(x_test, y_test)
  print(results)
  predictions <- model %>% predict_classes(x_test)
 
  matriz <- confusionMatrix(data = as.factor(predictions), as.factor(y_test), positive="1")
  print(paste("F1 ", matriz$byClass["F1"] * 100, "Precisao ", matriz$byClass["Precision"] * 100, "Recall ", matriz$byClass["Recall"] * 100, "Acuracia ", matriz$overall["Accuracy"] * 100))

  resTreinamento <- as.data.frame(history$metrics)
  treinamento_acc <- resTreinamento$acc[nrow(resTreinamento)]
  treinamento_val_acc <- resTreinamento$val_acc[nrow(resTreinamento)]
  treinamento_loss <- resTreinamento$loss[nrow(resTreinamento)]
  treinamento_val_loss <- resTreinamento$val_loss[nrow(resTreinamento)]
  epochs <- history$params$epochs
  batch_size <- history$params$batch_size

  resultados <- data.frame(matrix(ncol = 16, nrow = 0))
  tableResultados <- data.frame(tecnica, InputDim, OutputDim, features, epochs, batch_size, matriz$byClass["F1"] * 100, matriz$byClass["Precision"] * 100, matriz$byClass["Recall"] * 100, matriz$overall["Accuracy"] * 100, treinamento_acc * 100, treinamento_val_acc * 100, treinamento_loss * 100, treinamento_val_loss * 100, iteracao, model_to_json(model))
  rownames(tableResultados) <- tecnica
  names(tableResultados) <- c("Tecnica", "InputDim", "OutputDim", "Features", "Epochs", "Batch", "F1", "Precisao", "Revocacao", "Acuracia", "Acuracia treinamento", "Acuracia validação", "Loss treinamento", "Loss validação", "Iteracao", "Texto")

  pathSave <- "redesneurais/planilhas/wtdb.csv"
  if (file.exists(pathSave)) {
    write.table(tableResultados, pathSave, sep = ";", col.names = F, append = T)
  } else {
    write.table(tableResultados, pathSave, sep = ";", col.names = T, append = T)
  }
  return (results)
}

testes <- data.frame(matrix(ncol = 2, nrow = 0))
names(testes) <- c("epoca", "batch")

adicionarTeste <- function(epocaParam, batchParam) {
  linha <- data.frame(epoca=epocaParam, batch=batchParam)
  testes <- rbind(testes, linha)
  return (testes)
}

mapp <- function() {
  marcosD <- questions %>%
  mutate(
    question = map(q, ~tokenize_words(.x))
  ) %>%
  select(question)
}


vectorize_sequences <- function(sequences, dimension = max_features) {
  results <- matrix(0, nrow = length(sequences), ncol = dimension)
  for (i in 1:length(sequences)) {
    if (length(sequences[[i]])) {
      results[i, sequences[[i]]] <- 1
    }
  }
  return (results)
}

processarSequence <- function(textParser, maxlen, max_words) {
  onlyTexts <- textParser
  texts <- as.character(as.matrix(onlyTexts))
  tokenizer <- text_tokenizer(num_words = max_words) %>%
    fit_text_tokenizer(texts)
  
  sequences <- texts_to_sequences(tokenizer, texts)
  return (sequences);
}

getDadosWordEmbeddings <- function() {
      dados <- query("SELECT textParser as textEmbedding
                      FROM semantic_tweets_alcolic t
                      WHERE situacao = 1
                      AND possuiURL = 0
                      AND LENGTH(textOriginal) > 5
                      UNION ALL
                      SELECT textEmbedding 
                      FROM tweets t
                      WHERE LENGTH(textEmbedding) > 5
                      UNION ALL
                      SELECT textEmbedding
                      FROM tweets_amazon t
                      WHERE LENGTH(textEmbedding) > 5
                      ")
  dados$textEmbedding <- enc2utf8(dados$textEmbedding)
  dados$textEmbedding <- iconv(dados$textEmbedding, to='ASCII//TRANSLIT')
  dados$textEmbedding <- stringi::stri_enc_toutf8(dados$textEmbedding)
  dados$textEmbedding = gsub("'", "", dados$textEmbedding, ignore.case=T)
  return (dados)
}

getDadosWordEmbeddingsV2 <- function() {
      dados <- query("SELECT textEmbedding 
                      FROM tweets t
                      WHERE LENGTH(textEmbedding) > 5
                      UNION ALL
                      SELECT textSemPalavrasControle as textEmbedding
                      FROM chat_tweets t
                      WHERE contabilizar = 1
                      AND drunk IN ('N', 'S')
                      AND LENGTH(textEmbedding) > 5
                      UNION ALL
                      SELECT textEmbedding
                      FROM tweets_amazon t
                      WHERE q2 IN ('0', '1')
                      AND LENGTH(textEmbedding) > 5
                      ")

  dados$textEmbedding <- enc2utf8(dados$textEmbedding)
  dados$textEmbedding <- iconv(dados$textEmbedding, to='ASCII//TRANSLIT')
  dados$textEmbedding <- stringi::stri_enc_toutf8(dados$textEmbedding)
  dados$textEmbedding = gsub("'", "", dados$textEmbedding, ignore.case=T)
  return (dados)
}

getDadosChat <- function() {

  dados <- query('SELECT id,
                      drunk AS resposta,
                      textSemPalavrasControle as textParser,
                      textoOriginal as textOriginal,
                      textSemPalavrasControle as textEmbedding,
                      hashtags,
                      erros as numeroErros,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(tn.palavra))
                        FROM chat_tweets_nlp tn
                        WHERE tn.idTweet = t.id
                        AND palavra IN ("mention", "Hashtag", "url", "/religion and spirituality/hinduism", "/religion and spirituality/buddhism", "Download  Pilot", "highest score", "Miley Cyrus", "giveaway", "Billy Ray Cyrus", "/technology and computing/mp3 and midi", "/art and entertainment/movies and tv/children\'s", "/technology and computing/software", "/food and drink", "media", "/religion and spirituality/christianity", "/technology and computing/internet technology/web search", "/health and fitness/addiction/alcoholism", "/food and drink/beverages/alcoholic beverages/cocktails and beer", "/sports/bowling", "/food and drink/beverages", "/sports/cricket", "/food and drink/beverages/alcoholic beverages", "/food and drink/beverages/alcoholic beverages/wine", "Saint Patrick\'s Day", "/food and drink/beverages/non alcoholic beverages/soft drinks", "/society/dating", "Quantity", "Saint Patrick", "/business and industrial/business operations/business plans", "/society/unrest and war", "#media", "/food and drink/beverages/non alcoholic beverages/bottled water", "bottle", "/health and fitness/drugs", "/family and parenting/children", "mention Thanks", "/technology and computing/internet technology/email", "/sports/table tennis and ping-pong", "drugs", "/health and fitness/addiction", "/health and fitness/addiction/smoking addiction", "/shopping/retail/outlet stores", "Shamrock", "/religion and spirituality/islam", "Irish folklore", "https", "/society/social institution/divorce", "/business and industrial/advertising and marketing/advertising", "store", "/automotive and vehicles/minivan", "/automotive and vehicles/boats and watercraft", "/art and entertainment/movies and tv/movies/reviews", "gt", "last night", "/art and entertainment/books and literature", "Person", "shots", "/food and drink/food", "/technology and computing/programming languages/javascript", "Drug", "wine", "#mention #media", "Starbucks", "/law, govt and politics/politics/elections/presidential elections", "/law, govt and politics", "text", "Alcoholic beverage", "St. Patrick\'s Day")
                        GROUP BY tn.idTweet
                      ) AS entidades,
                      (
                        SELECT GROUP_CONCAT(DISTINCT(REPLACE(ty.type, "http://dbpedia.org/class/", "")))
                        FROM chat_tweets_nlp tn
                        JOIN chat_tweets_conceito c ON c.palavra = tn.palavra
                        JOIN resource_type ty ON ty.resource = c.resource
                        WHERE tn.idTweet = t.id
                        AND ty.type IN ("http://dbpedia.org/class/yago/WikicatVirtualCommunities", "http://dbpedia.org/class/yago/Gathering107975026", "http://dbpedia.org/class/yago/Community108223802", "http://dbpedia.org/ontology/RecordLabel", "http://dbpedia.org/class/yago/SocialGroup107950920", "http://dbpedia.org/class/yago/Group100031264", "http://dbpedia.org/class/yago/Abstraction100002137", "http://dbpedia.org/class/yago/WikicatOccupationsInAviation", "http://dbpedia.org/class/yago/WikicatMilitaryAviationOccupations", "http://dbpedia.org/class/yago/WikicatPeopleFromNashville,Tennessee", "http://dbpedia.org/class/yago/WikicatWaltDisneyRecordsArtists", "http://dbpedia.org/class/yago/WikicatHollywoodRecordsArtists", "http://dbpedia.org/class/yago/WikicatFascinationRecordsArtists", "http://dbpedia.org/class/yago/WikicatMusiciansFromTennessee", "http://dbpedia.org/class/yago/WikicatChildActors", "http://dbpedia.org/class/yago/WikicatPeopleFromTennessee", "http://dbpedia.org/class/yago/WikicatActorsFromTennessee", "http://dbpedia.org/class/yago/WikicatActressesFromTennessee", "http://dbpedia.org/class/yago/WikicatAmericanChildActresses", "http://dbpedia.org/class/yago/WikicatAmericanChildActors", "http://dbpedia.org/class/yago/WikicatAmericanFemaleDancers", "http://dbpedia.org/class/yago/WikicatMusiciansFromNashville,Tennessee", "http://dbpedia.org/class/yago/WikicatActressesFromNashville,Tennessee", "http://dbpedia.org/class/yago/WikicatRCARecordsArtists", "http://dbpedia.org/class/yago/WikicatChildPopMusicians", "http://dbpedia.org/class/yago/WikicatAmericanFemalePopSingers", "http://dbpedia.org/class/yago/Dancer109989502", "http://dbpedia.org/class/yago/WikicatAmericanGuitarists", "http://dbpedia.org/class/yago/WikicatLGBTRightsActivistsFromTheUnitedStates", "http://dbpedia.org/class/yago/WikicatAmericanVoiceActresses", "http://dbpedia.org/class/yago/WikicatAmericanChildSingers", "http://dbpedia.org/class/yago/Pianist110430665", "http://dbpedia.org/class/yago/WikicatAmericanPianists", "http://dbpedia.org/class/yago/WikicatAmericanVoiceActors", "http://dbpedia.org/class/yago/WikicatAmericanDanceMusicians", "http://dbpedia.org/class/yago/WikicatAmericanActresses", "http://dbpedia.org/class/yago/Guitarist110151760", "http://dbpedia.org/class/yago/WikicatPopSingers", "http://dbpedia.org/class/yago/Wikicat21st-centuryActresses", "http://dbpedia.org/class/yago/WikicatAmericanFemaleSingers", "http://dbpedia.org/class/yago/WikicatAmericanTelevisionActresses", "http://dbpedia.org/class/yago/WikicatAmericanTelevisionActors", "http://dbpedia.org/class/yago/WikicatAmericanHipHopSingers", "http://dbpedia.org/class/yago/Occupation100582388", "http://dbpedia.org/class/yago/WikicatAmericanFilmActresses", "http://dbpedia.org/class/yago/WikicatAmericanSingers", "http://dbpedia.org/class/yago/Wikicat21st-centuryAmericanActresses", "http://dbpedia.org/class/yago/WikicatAmericanPopSingers", "http://dbpedia.org/class/yago/WikicatEnglish-languageSingers", "http://dbpedia.org/class/yago/Wikicat21st-centuryActors", "http://dbpedia.org/class/yago/Wikicat21st-centuryAmericanSingers", "http://dbpedia.org/class/yago/Actress109767700", "http://dbpedia.org/class/yago/WikicatActors", "http://dbpedia.org/class/yago/WikicatAmericanMusicians", "http://dbpedia.org/class/yago/WikicatAmericanActors", "http://dbpedia.org/class/yago/WikicatWomen", "http://dbpedia.org/class/yago/Militant110315837", "http://umbel.org/umbel/rc/MusicalPerformer", "http://dbpedia.org/class/yago/Female109619168", "http://dbpedia.org/class/yago/Woman110787470", "http://dbpedia.org/class/yago/Disputant109615465", "http://dbpedia.org/class/yago/Reformer110515194", "http://dbpedia.org/class/yago/Actor109765278", "http://dbpedia.org/class/yago/Singer110599806", "http://dbpedia.org/ontology/MusicalArtist", "http://dbpedia.org/class/yago/WikicatAmericanPeople", "http://www.w3.org/2002/07/owl#Thing", "http://dbpedia.org/class/yago/Musician110340312", "http://dbpedia.org/class/yago/Musician110339966", "http://dbpedia.org/class/yago/Artist109812338", "http://dbpedia.org/class/yago/Performer110415638", "http://dbpedia.org/class/yago/Entertainer109616922", "http://dbpedia.org/class/yago/Adult109605289", "http://dbpedia.org/class/yago/Activity100407535", "http://dbpedia.org/class/yago/Creator109614315", "http://dbpedia.org/class/yago/CausalAgent100007347", "http://dbpedia.org/class/yago/Organism100004475", "http://dbpedia.org/class/yago/LivingThing100004258", "http://dbpedia.org/class/yago/Person100007846", "http://dbpedia.org/ontology/Building", "http://dbpedia.org/class/yago/Act100030358", "http://dbpedia.org/class/yago/Event100029378", "http://dbpedia.org/ontology/Person", "http://dbpedia.org/class/yago/WikicatLivingPeople", "http://www.ontologydesignpatterns.org/ont/dul/DUL.owl#NaturalPerson", "http://schema.org/Person", "http://www.wikidata.org/entity/Q5", "http://www.wikidata.org/entity/Q215627", "http://xmlns.com/foaf/0.1/Person", "http://dbpedia.org/class/yago/PsychologicalFeature100023100", "http://dbpedia.org/class/yago/Maker110284064", "http://dbpedia.org/class/yago/Manufacturer110292316", "http://dbpedia.org/class/yago/YagoLegalActor", "http://dbpedia.org/class/yago/WikicatHighKingsOfIreland", "http://dbpedia.org/class/yago/Wikicat5th-centuryIrishPeople", "http://dbpedia.org/class/yago/WikicatIrishSoldiers", "http://dbpedia.org/class/yago/Wikicat5th-centuryIrishMonarchs", "http://dbpedia.org/class/yago/WikicatKingsOfConnacht", "http://dbpedia.org/class/yago/Wikicat4th-centuryIrishPeople", "http://dbpedia.org/class/yago/WikicatFast-foodChainsOfTheUnitedStates", "http://dbpedia.org/class/yago/Wikicat4th-centuryIrishMonarchs", "http://dbpedia.org/class/yago/WikicatMedievalIrishPeople", "http://dbpedia.org/class/yago/WikicatPsychologicalTheories", "http://dbpedia.org/class/yago/WikicatMind–bodyInterventions", "http://dbpedia.org/class/yago/Billionaire110529684", "http://dbpedia.org/class/yago/RichPerson110529231", "http://dbpedia.org/class/yago/WikicatAmericanBillionaires", "http://dbpedia.org/class/yago/Restaurateur110524869", "http://dbpedia.org/class/yago/Employee110053808", "http://dbpedia.org/class/yago/WikicatAmericanRestaurateurs", "http://dbpedia.org/class/yago/WikicatAmericanVideoGameDesigners", "http://dbpedia.org/class/yago/WikicatAmericanInvestors", "http://dbpedia.org/class/yago/WikicatAmericanRadioProducers", "http://dbpedia.org/class/yago/Explanation105793000", "http://dbpedia.org/class/yago/Theory105989479", "http://dbpedia.org/class/yago/WikicatAmericanGameShowHosts", "http://dbpedia.org/class/yago/WikicatAmericanBusinessWriters", "http://dbpedia.org/class/yago/Merchant110309896", "http://dbpedia.org/class/yago/WikicatCelticChristianBishops", "http://dbpedia.org/class/yago/WikicatBritishSlaves", "http://dbpedia.org/class/yago/WikicatNorthernBrythonicSaints", "http://dbpedia.org/class/yago/WikicatChristianMissionaries", "http://dbpedia.org/class/yago/WikicatMedievalIrishWriters", "http://dbpedia.org/class/yago/WikicatIrishBishops", "http://dbpedia.org/class/yago/WikicatArchbishopsOfArmagh", "http://dbpedia.org/class/yago/Wikicat5th-centuryChristianSaints", "http://dbpedia.org/class/yago/WikicatIrishRomanCatholicSaints", "http://dbpedia.org/class/yago/Wikicat5th-centuryWriters", "http://dbpedia.org/class/yago/WikicatChurchFathers", "http://dbpedia.org/class/yago/Wikicat5th-centuryPeople", "http://dbpedia.org/class/yago/Wikicat5th-centuryBishops", "http://dbpedia.org/class/yago/WikicatChristianMissionariesInIreland", "http://dbpedia.org/class/yago/Father110080869", "http://dbpedia.org/class/yago/WikicatRomano-BritishSaints", "http://dbpedia.org/class/yago/WikicatWritersOfCaptivityNarratives", "http://dbpedia.org/class/yago/Archbishop109805151", "http://dbpedia.org/class/yago/WikicatIrishSaints", "http://dbpedia.org/class/yago/WikicatBritishBishops", "http://dbpedia.org/class/yago/WikicatPre-diocesanBishopsInIreland", "http://dbpedia.org/class/yago/WikicatMedievalIrishSaints", "http://dbpedia.org/class/yago/WikicatSlaves", "http://dbpedia.org/class/yago/WikicatAmericanTelevisionProducers", "http://dbpedia.org/class/yago/Owner110388924", "http://dbpedia.org/class/yago/Businessman109882007", "http://dbpedia.org/class/yago/WikicatConspiracyTheorists", "http://dbpedia.org/class/yago/WikicatAmericanStockTraders", "http://dbpedia.org/class/yago/WikicatAmericanFinanciers", "http://dbpedia.org/class/yago/Trader110720453", "http://dbpedia.org/class/yago/StockTrader110657835", "http://dbpedia.org/class/yago/WikicatAmericanTelevisionDirectors", "http://dbpedia.org/class/yago/Businessperson109882716", "http://dbpedia.org/class/yago/Chain108057816", "http://dbpedia.org/class/yago/RestaurantChain108061801", "http://dbpedia.org/class/yago/WikicatCompaniesEstablishedIn1971", "http://dbpedia.org/class/yago/WikicatCompaniesBasedInSeattle,Washington", "http://dbpedia.org/class/yago/WikicatRetailCompaniesEstablishedIn1971", "http://dbpedia.org/class/yago/WikicatCoffeeCompanies", "http://dbpedia.org/class/yago/WikicatWritersFromFlorida", "http://dbpedia.org/class/yago/WikicatUnitedStatesFootballLeagueExecutives", "http://dbpedia.org/class/yago/WikicatTelevisionProducersFromNewYork", "http://dbpedia.org/class/yago/WikicatNewYorkMilitaryAcademyAlumni", "http://dbpedia.org/class/yago/WikicatChiefExecutives", "http://dbpedia.org/class/yago/WikicatBusinessEducators", "http://dbpedia.org/class/yago/WikicatBoardGameDesigners", "http://dbpedia.org/class/yago/WikicatAmericanPoliticalFundraisers", "http://dbpedia.org/class/yago/WikicatAmericanFinancialLiteracyActivists", "http://dbpedia.org/class/yago/WikicatAmericanBeautyPageantOwners", "http://dbpedia.org/class/yago/WikicatAmericanAirlineChiefExecutives", "http://dbpedia.org/class/yago/Solicitor110623354", "http://dbpedia.org/class/yago/Petitioner110420031", "http://dbpedia.org/class/yago/InvestmentAdviser110215815", "http://dbpedia.org/class/yago/Fundraiser110116478", "http://dbpedia.org/class/yago/Applicant109607280", "http://dbpedia.org/class/yago/WikicatAmericanFinancialCommentators", "http://dbpedia.org/class/yago/WikicatFordhamUniversityAlumni", "http://dbpedia.org/class/yago/WikicatAmericanRealityTelevisionProducers", "http://dbpedia.org/class/yago/WikicatAmericanInvestmentAdvisors", "http://dbpedia.org/class/yago/WikicatTheTrumpOrganizationEmployees", "http://dbpedia.org/class/yago/WikicatAmericanChiefExecutives", "http://dbpedia.org/class/yago/WikicatIrishKings", "http://dbpedia.org/class/yago/King110231515", "http://dbpedia.org/class/yago/Socialite110619409", "http://dbpedia.org/class/yago/Thinking105770926", "http://dbpedia.org/class/yago/HigherCognitiveProcess105770664")
                        GROUP BY t.id
                      ) AS types
                      FROM chat_tweets t
                      WHERE contabilizar = 1
                      AND drunk IN ("N", "S")
                      ')

  dados$resposta[dados$resposta == "N"] <- 0
  dados$resposta[dados$resposta == "S"] <- 1

  #dados$resposta <- as.factor(dados$resposta)
  dados$resposta <- as.numeric(dados$resposta)
  dados$textOriginal <- enc2utf8(dados$textOriginal)
  dados$textOriginal <- iconv(dados$textOriginal, to='ASCII//TRANSLIT')
  
  dados$textEmbedding <- enc2utf8(dados$textEmbedding)
  dados$textEmbedding <- iconv(dados$textEmbedding, to='ASCII//TRANSLIT')
  dados$textEmbedding = gsub("'", "", dados$textEmbedding, ignore.case=T)
  dados$textEmbedding = gsub("“", "", dados$textEmbedding)
  dados$textEmbedding = gsub("”", "", dados$textEmbedding)
  
  dados$textParser <- enc2utf8(dados$textParser)
  dados$textParser <- iconv(dados$textParser, to='ASCII//TRANSLIT')

  dados$hashtags = gsub("#drunk,|#drunk$", "", dados$hashtags,ignore.case=T)
  dados$hashtags = gsub("#alcohol,|#alcohol$", "", dados$hashtags,ignore.case=T)
  dados$hashtags = gsub("#beer,|#beer$", "", dados$hashtags,ignore.case=T)
  dados$hashtags = gsub("#liquor,|#liquor$", "", dados$hashtags,ignore.case=T)
  dados$hashtags = gsub("#vodka,|#vodka$", "", dados$hashtags,ignore.case=T)
  dados$hashtags = gsub("#hangover,|#hangover$", "", dados$hashtags,ignore.case=T)

  dados$hashtags = gsub("#", "#tag_", dados$hashtags)
  dados$textParser <- stringi::stri_enc_toutf8(dados$textParser)
  dados$textParser = gsub("'", "", dados$textParser)

  dados$numeroErros[dados$numeroErros > 1] <- 1
  return (dados)
}