library(ggplot2)

# 950 x 255
#Antiga Ordenação
valoresExp1 <- c(87.58, 85.96, 86.70, 92, 87.96, 89.83, 87.41, 89.12, 88.17, 84.29, 87.05, 85.09, 87.52, 92.15, 89.83)
valoresExp2 <- c(99.57, 77.80, 87.35, 93.26, 84.97, 88.68, 94.09, 83.39, 88.31, 93.10, 83.14, 87.61, 96.72, 81.4, 89.06)
valoresExp3 <- c(86.67, 71.85, 78.01, 77.92, 84.23, 80.53, 77.7, 76.74, 76.93, 74.96, 84.52, 78.36, 95.18, 80.89, 88.03)
valoresExp4 <- c(79.47, 80.15, 79.64, 77.12, 76.73, 76.49, 83.33, 75.27, 78.92, 71.53, 72.21, 71.71, 97.66, 99.78, 98.71)

#Nova ordenação
valoresExp1 <- c(87.52, 92.15, 89.83, 92, 87.96, 89.83, 87.58, 85.96, 86.70, 87.41, 89.12, 88.17, 84.29, 87.05, 85.09)
valoresExp2 <- c(96.72, 81.4, 89.06, 93.26, 84.97, 88.68, 99.57, 77.80, 87.35, 94.09, 83.39, 88.31, 93.10, 83.14, 87.61)
valoresExp3 <- c(95.18, 80.89, 88.03, 77.92, 84.23, 80.53, 86.67, 71.85, 78.01, 77.7, 76.74, 76.93, 74.96, 84.52, 78.36)
valoresExp4 <- c(82.79, 96.99, 72.236, 77.12, 76.73, 76.49, 79.47, 80.15, 79.64, 83.33, 75.27, 78.92, 71.53, 72.21, 71.71)
valoresExp5 <- c(88.36, 94.58, 91.36, 85.31, 95.80, 90.17, 83.71, 94.01, 88.47, 83.98, 95.15, 89.13, 80.25, 95.97, 87.32)

# df1 <- data.frame(supp=rep(c("Hidden Layers", "GloVe", "Hidden layers + GloVe", "Skip Grams", "Semantic Framework"), each=3),
#                   metric=rep(c("Recall", "Precision", "F1-Measure"),5),
#                   len=valoresExp4)

# head(df1)
# df1$metric <- factor(df1$metric, levels = c("Recall", "Precision", "F1-Measure"))

# ggplot(data=df1, aes(x=metric, y=len, fill=supp)) +
#   geom_bar(stat="identity", position=position_dodge()) +
#   geom_text(aes(label=len), vjust=1.6, color="white",
#           position = position_dodge(0.9), size=3.5) +
#   labs(title="", x = "", y = "", color = "Categorias", fill = "")

headers <- c("Semantic Framework", "GloVe", "Hidden Layers", "Hidden layers + GloVe", "Skip Grams")

dfCerto <- data.frame(supp=rep(headers, each=3),
                  metric=rep(c("Recall", "Precision", "F1-Measure"),5),
                  len=valoresExp4)

head(dfCerto)
dfCerto$supp <- factor(dfCerto$supp, levels = headers)
dfCerto$metric <- factor(dfCerto$metric, levels = c("Recall", "Precision", "F1-Measure"))

ggplot(data=dfCerto, aes(x=metric, y=len, fill=supp)) +
  geom_bar(stat="identity", position=position_dodge()) +
  geom_text(aes(label=len), vjust=1.6, color="white",
          position = position_dodge(0.9), size=3.5) +
  labs(title="", x = "", y = "", color = "Categorias", fill = "")

