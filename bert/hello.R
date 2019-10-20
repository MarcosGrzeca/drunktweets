# install.packages("devtools")
# Set up a GITHUB_PAT with Sys.setenv(GITHUB_PAT = "YOURPATHERE")
devtools::install_github(
  "jonathanbratt/RBERT", 
  build_vignettes = TRUE
)

tensorflow::install_tensorflow(version = "1.13.1")
