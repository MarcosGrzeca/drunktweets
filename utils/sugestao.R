load("pos2.Rda")

options(max.print = 99999999)

str(as.double(pos[1]$id[1]))

a <- sprintf("%0.0f", pos[1]$id)
a

dump(a, "sugestoes.csv")

write.table(a, file = "sugestoes.csv", append = FALSE, quote = TRUE, sep = ",", eol = "\n", na = "?", dec = ".", row.names = FALSE, col.names = TRUE, qmethod = c("escape", "double"), fileEncoding = "")
