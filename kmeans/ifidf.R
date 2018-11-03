library(tools)
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
dados <- getDadosTFIDF()

library(dplyr)
library(tidytext)

book_words <- dados %>%
  unnest_tokens(word, text) %>%
  count(book, word, sort = TRUE) %>%
  ungroup()

book_words

book_words <- book_words %>%
  bind_tf_idf(word, book, n)

mais_importantes <- book_words %>%
  arrange(desc(tf_idf)) %>% 
  top_n(1000)

mais_importantes$word


# book_words %>%
#   arrange(desc(tf_idf)) %>%
#   mutate(word = factor(word, levels = rev(unique(word)))) %>% 
#   group_by(book) %>% 
#   top_n(15) %>% 
#   ungroup %>%
#   ggplot(aes(word, tf_idf, fill = book)) +
#   geom_col(show.legend = FALSE) +
#   labs(x = NULL, y = "tf-idf") +
#   facet_wrap(~book, ncol = 2, scales = "free") +
#   coord_flip()
