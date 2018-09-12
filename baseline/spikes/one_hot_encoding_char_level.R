library(keras)
samples <- c("The cat sat on the mat.", "The dog ate my homework.", "Cat")
# Creates a tokenizer, configured to only take into account the 1,000 
# most common words, then builds the word index.
tokenizer <- text_tokenizer(num_words = 1000, char_level = TRUE) %>%
  fit_text_tokenizer(samples)
# Turns strings into lists of integer indices
sequences <- texts_to_sequences(tokenizer, samples)
# You could also directly get the one-hot binary representations. Vectorization 
# modes other than one-hot encoding are supported by this tokenizer.
one_hot_results <- texts_to_matrix(tokenizer, samples, mode = "binary")
# How you can recover the word index that was computed
word_index <- tokenizer$word_index
cat("Found", length(word_index), "unique tokens.\n")

word_index

View(one_hot_results)
