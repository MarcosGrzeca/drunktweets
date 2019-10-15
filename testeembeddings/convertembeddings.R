#https://github.com/FredericGodin/TwitterEmbeddings

# library(rword2vec)
# library(readr)
# library(quanteda)


# wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=1lw5Hr6Xw0G0bMT1ZllrtMqEgCTrM7dzc' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1lw5Hr6Xw0G0bMT1ZllrtMqEgCTrM7dzc" -O FILENAME && rm -rf /tmp/cookies.txt

library(rword2vec)
bin_to_txt("/var/www/html/FILENAME", "/var/www/html/drunktweets/word2vec_tokens.txt")