library(tools)
library(tm)

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

dataset <- "exp1"

if (dataset == "exp1") {
	dados <- getDadosBaselineByQ("q1")
	fileName <- "bert/exp1.csv"
	
}

dados <- subset(dados, select = c(textEmbedding, resposta))
dump(dados, fileName)