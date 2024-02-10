print("Installing Packages")

install.packages("pandoc")
install.packages("plotly")
install.packages("htmlwidgets")
install.packages("patchwork")
install.packages("ggiraph")
install.packages("magrittr")

install.packages("ggplot2")
install.packages("tidyverse")

install.packages("neo4jshell")
install.packages("docopt")
install.packages("patchwork")
install.packages("gt")
install.packages("jsonlite")

# ggtree is at bioconduct, need something specially for it
install.packages("BiocManager", repos = "http://cran.us.r-project.org")
BiocManager::install("ggtree")
