
#' A word vector is a giant matrix of words, and each word contains a numeric array that represents the semantic
#' meaning of that word. This is useful so we can discover relationships and analogies between words programmatically.
#' The classic example is "king" minus "man" plus "woman" is most similar to "queen"


# function definition --------------------------------------------------------------------------

    # input .txt file, exports list of list of values and character vector of names (words)
    proc_pretrained_vec <- function(p_vec) {


        # initialize space for values and the names of each word in vocab
        vals <- vector(mode = "list", length(p_vec))
        names <- character(length(p_vec))

        # loop through to gather values and names of each word
        for(i in 1:length(p_vec)) {
            if(i %% 1000 == 0) {print(i)}
            this_vec <- p_vec[i]
            this_vec_unlisted <- unlist(strsplit(this_vec, " "))
            this_vec_values <- as.numeric(this_vec_unlisted[-1])  # this needs testing, does it become numeric?
            this_vec_name <- this_vec_unlisted[1]

            vals[[i]] <- this_vec_values
            names[[i]] <- this_vec_name
        }

        # convert lists to data.frame and attach the names
        glove <- data.frame(vals)
        names(glove) <- names

        return(glove)
    }




# using the function -------------------------------------------------------------------------

    # here we are reading in the unzipped, raw, GloVe pre-trained word vector object (.txt)
    # all you have to change is the file path to where you GloVe object has been unzipped
    g6b_300 <- scan(file = "/var/www/html/glove.twitter.27B.100d.txt", what="", sep="\n")


    # call the function to convert the raw GloVe vector to data.frame (extra lines are for wall-time reporting)
    t_temp <- Sys.time()
    glove.300 <- proc_pretrained_vec(g6b_300)  # this is the actual function call
    (t_elap_temp <- paste0(round(as.numeric(Sys.time() - t_temp, units="mins"), digits = 2), " minutes"))
    
    print(dim(glove.300)) 
    # [1]   300  400000
    
    
    
    
# NOTES: ------------------------------------------------------------------------------------------
    
    #' I chose to use the 6 billion token, 300-dimension-per-word, 400k vocabulary word vector, so that
    #' explains why the dimensions of this dataframe are 300 rows by 400k columns 
    #'
    #' each column is a different word's numeric vector representation. it might be useful to t(glove.300)
    #' to transpose into a matrix for some calculations like sim2 from text2vec package
    


# BONUS MATERIAL: definition for finding similar word vectors ----------------------------------------------

    # let's have some fun with this and try out the most common examples 
    # this section requires the "text2vec" library
    # install.packages("text2vec")  # uncomment and execute this if you don't have that package

    find_sim_wvs <- function(this_wv, all_wvs, top_n_res=40) {
        # this_wv will be a numeric vector; all_wvs will be a data.frame with words as columns and dimesions as rows
        require(text2vec)
        this_wv_mat <- matrix(this_wv, ncol=length(this_wv), nrow=1)
        all_wvs_mat <- as.matrix(all_wvs)
        
        if(dim(this_wv_mat)[[2]] != dim(all_wvs_mat)[[2]]) {
            print("switching dimensions on the all_wvs_matrix")
            all_wvs_mat <- t(all_wvs_mat)
        }
        
        cos_sim = sim2(x=all_wvs_mat, y=this_wv_mat, method="cosine", norm="l2")
        sorted_cos_sim <- sort(cos_sim[,1], decreasing = T) 
        return(head(sorted_cos_sim, top_n_res))
                
    }



    # try out the function - we're hoping that "queen" will be in the top 5 results here
    this_word_vector <- glove.300[['king']] - glove.300[['man']] + glove.300[['woman']]      
    find_sim_wvs(this_word_vector, glove.300, top_n_res=5)

    
    # "flock is to geese as bison is to ___________"  (hoping for "herd")
    # funny... "buffalo" tends to gravitate towards the city while "bison" is the animal
    my_wv <- glove.300[['flock']] - glove.300[['geese']] + glove.300[['buffalo']]  # all cities because "buffalo, NY"
    find_sim_wvs(my_wv, glove.300, top_n_res=10)
    my_wv <- glove.300[['flock']] - glove.300[['geese']] + glove.300[['bison']]    # here we go, we got our "herds" we're looking for
    find_sim_wvs(my_wv, glove.300, top_n_res=10)


