library(tools)

DESC <- "Exp1 GloVe- CNN + Semantic Enrichment + Word embeddings"
source(file_path_as_absolute("pca/loader.R"))

library(Rtsne)
library(ggplot2)
library(plotly)

tsne <- Rtsne(train_sequences, perplexity = 100, pca = TRUE)

tsne_plot <- tsne$Y %>%
  as.data.frame() %>%
  mutate(word = row.names(train_sequences)) %>%
  ggplot(aes(x = V1, y = V2, label = word)) + 
  geom_text(size = 3)
tsne_plot