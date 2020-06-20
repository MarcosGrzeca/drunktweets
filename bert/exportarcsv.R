library(tools)
library(tm)

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

dataset <- "ds3"

if (dataset == "exp1") {
	dados <- getDadosBaselineByQ("q1")
	fileName <- "bert/exp1.csv"
} else if (dataset == "exp2") {
	dados <- getDadosBaselineByQ("q2")
	fileName <- "bert/exp2.csv"
} else if (dataset == "exp3") {
	dados <- getDadosBaselineByQ("q3")
	fileName <- "bert/exp3.csv"
} else if (dataset == "ds2") {
	dados <- getDadosChat()
	fileName <- "bert/ds2.csv"
} else if (dataset == "ds3") {
	source(file_path_as_absolute("utils/getDadosAmazon.R"))
    dados <- getDadosAmazon()
	fileName <- "bert/ds3.csv"
}

dados$textEmbedding <- sapply(dados$textEmbedding,
                                  function(x) { gsub("[\r\n]", " ", x) })

dados <- subset(dados, select = c(textEmbedding, resposta))
dump(dados, fileName)