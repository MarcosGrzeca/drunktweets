dataframe <- data.frame(ID = 1:2, Name = 'XX',
                        string_column = c('Hi\r\nyou\r\n', 'Always \r\nshare\r\n some \r\nsample\r\n data!'))
dataframe$string_column  
#> [1] Hi\r\nyou\r\n                                
#> [2] Always \r\nshare\r\n some \r\nsample\r\n data!
#> Levels: Always \r\nshare\r\n some \r\nsample\r\n data! Hi \r\nyou\r\n

dataframe$string_column <- sapply(dataframe$string_column,
                                  function(x) { gsub("[\r\n]", " ", x) })
dataframe$string_column
#> [1] "Hi you"                         "Always share some sample data!"

library(stringr)
dataframe$string_column <- str_replace(gsub("\\s+", " ", str_trim(dataframe$string_column)), "B", "b")
