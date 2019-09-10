#http://www.nltk.org/install.html

devtools::install_github('mlampros/fastText')
library(fastText)
NLTK = reticulate::import("nltk.corpus")
text_reuters = NLTK$reuters 
nltk = reticulate::import("nltk")

# if the 'reuters' data is not already available then it can be downloaded from within R
nltk$download('reuters')   
documents = text_reuters$fileids()
str(documents)

# List of categories
categories = text_reuters$categories()
str(categories)

# Documents in a category
category_docs = text_reuters$fileids("acq")
str(category_docs)


one_doc = text_reuters$raw("test/14843")
one_doc
documents = text_reuters$fileids()

# document ids for train - test
train_docs_id = documents[as.vector(sapply(documents, function(i) substr(i, 1, 5) == "train"))]
test_docs_id = documents[as.vector(sapply(documents, function(i) substr(i, 1, 4) == "test"))]

train_docs = lapply(1:length(train_docs_id), function(x) text_reuters$raw(train_docs_id[x]))
test_docs = lapply(1:length(test_docs_id), function(x) text_reuters$raw(test_docs_id[x]))

str(train_docs)
str(test_docs)

# train - test labels  [ some categories might have more than one label (overlapping) ]

train_labels = as.vector(sapply(train_docs_id, function(x) text_reuters$categories(x)))         
test_labels = as.vector(sapply(test_docs_id, function(x) text_reuters$categories(x)))  

concat = c(unlist(train_docs), unlist(test_docs))

length(concat)

str(concat)

clust_vec = textTinyR::tokenize_transform_vec_docs(object = concat, as_token = T,
                                                   to_lower = T, 
                                                   remove_punctuation_vector = F,
                                                   remove_numbers = F, 
                                                   trim_token = T,
                                                   split_string = T,
                                                   split_separator = " \r\n\t.,;:()?!//", 
                                                   remove_stopwords = T,
                                                   language = "english", 
                                                   min_num_char = 3, 
                                                   max_num_char = 100,
                                                   stemmer = "porter2_stemmer", 
                                                   threads = 4,
                                                   verbose = T)

unq = unique(unlist(clust_vec$token, recursive = F))
length(unq)


# I'll build also the term matrix as I'll need the global-term-weights

utl = textTinyR::sparse_term_matrix$new(vector_data = concat, file_data = NULL,
                                        document_term_matrix = TRUE)

tm = utl$Term_Matrix(sort_terms = FALSE, to_lower = T, remove_punctuation_vector = F,
                     remove_numbers = F, trim_token = T, split_string = T, 
                     stemmer = "porter2_stemmer",
                     split_separator = " \r\n\t.,;:()?!//", remove_stopwords = T,
                     language = "english", min_num_char = 3, max_num_char = 100,
                     print_every_rows = 100000, normalize = NULL, tf_idf = F, 
                     threads = 6, verbose = T)

gl_term_w = utl$global_term_weights()

str(gl_term_w)


save_dat = textTinyR::tokenize_transform_vec_docs(object = concat, as_token = T, 
                                                  to_lower = T, 
                                                  remove_punctuation_vector = F,
                                                  remove_numbers = F, trim_token = T, 
                                                  split_string = T, 
                                                  split_separator = " \r\n\t.,;:()?!//",
                                                  remove_stopwords = T, language = "english", 
                                                  min_num_char = 3, max_num_char = 100, 
                                                  stemmer = "porter2_stemmer", 
                                                  path_2folder = "/var/www/html/drunktweets/",
                                                  threads = 1,                     # whenever I save data to file set the number threads to 1
                                                  verbose = T)

save_dat

PATH_INPUT = "/var/www/html/drunktweets/output_token_single_file.txt"
PATH_OUT = "/var/www/html/drunktweets/rt_fst_model"

vecs = fastTextR::skipgram_cbow(input_path = PATH_INPUT, output_path = PATH_OUT, 
                                method = "skipgram", lr = 0.075, lrUpdateRate = 100, 
                                dim = 300, ws = 5, epoch = 5)

init = textTinyR::Doc2Vec$new(token_list = clust_vec$token, 
                              word_vector_FILE = "/var/www/html/drunktweets/rt_fst_model.vec",
                              print_every_rows = 5000, 
                              verbose = TRUE, 
                              copy_data = FALSE)   

doc2_sum = init$doc2vec_methods(method = "sum_sqrt", threads = 6)
doc2_norm = init$doc2vec_methods(method = "min_max_norm", threads = 6)
doc2_idf = init$doc2vec_methods(method = "idf", global_term_weights = gl_term_w, threads = 6)

rows_cols = 1:5

doc2_sum[rows_cols, rows_cols]
doc2_norm[rows_cols, rows_cols]
doc2_idf[rows_cols, rows_cols]

str(doc2_sum)
