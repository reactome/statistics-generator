script_path <- commandArgs(trailingOnly = TRUE)[1]

# Get the directory containing the script
script_dir <- dirname(script_path)

# Set the working directory to the script's directory
setwd(script_dir)

library(docopt)

source("R/functions.R")

"Statistics Generator

Usage:
  run.R [options] <release_date>
  run.R (-h | --help)
  run.R --version

Options:
  -h --help      Show this screen.
  --version      Show version.
  --host=<host>   Neo4j host [default: localhost]
  --port=<port>   Neo4j port [default: 7687]
  --user=<user>   Neo4j username [default: neo4j]
  --password=<password> The password for neo4j database
  --no-html    Set if you don't want to generate the interactive html file [default: FALSE]
  --output=DIR  Folder to put output files into [default: output]
  --tree=FILE    The species tree file [default: species_tree.nwk]

" -> doc
arguments <- docopt(doc, version = "1.0.0")

# Connect to Neo4j
graphdb <- connect_neo4j(arguments)

# Retrieve data from Neo4j
species_query_file_path <- "./cypher_queries/species.cyp"
species_data <- retrieve_data(graphdb, species_query_file_path)

# Additional information needed for processing
release_date <- arguments$release_date
tree_file <- arguments$tree
output_folder <- arguments$output

# Process data and get necessary information
processed_data <- process_data(species_data, tree_file, output_folder)

# Plot statistics
plot_stats(processed_data, need_html = !arguments$no_html)
