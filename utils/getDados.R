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
                      textOriginal,
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
      dados <- query("SELECT textOriginal as textEmbedding
                      FROM semantic_tweets_alcolic t
                      WHERE situacao = 1
                      AND possuiURL = 0
                      AND LENGTH(textOriginal) > 5
                      UNION ALL
                      SELECT textEmbedding 
                      FROM tweets t
                      WHERE LENGTH(textoParserRisadaEmoticom) > 5
                      ")

  dados$textEmbedding <- enc2utf8(dados$textEmbedding)
  dados$textEmbedding <- iconv(dados$textEmbedding, to='ASCII//TRANSLIT')
  dados$textEmbedding = gsub("'", "", dados$textEmbedding, ignore.case=T)
  return (dados)
}