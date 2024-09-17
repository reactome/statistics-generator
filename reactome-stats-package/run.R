#!/usr/bin/env Rscript

source("statistics_functions.R")

suppressPackageStartupMessages(library("docopt"))
suppressPackageStartupMessages(library("neo4jshell"))

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
  --no-html    Set of you don\'t want to generate the interactive html file [default: FALSE]
  --output=DIR  Folder to put output files into [default: output]
  --tree=FILE    The species tree file [default: species_tree.nwk]

" -> doc
arguments <- docopt(doc, version = "1.0.0")

graphdb <- connect_neo4j(arguments)

cql <- "MATCH (n:DBInfo) RETURN n.releaseNumber AS version;"
db_info <- neo4j_query(graphdb, cql)

release_version <- db_info[1, "version"]
print(paste("release_version", release_version, sep = ": "))

species_query_file_path <- "./cypher_queries/species.cyp"
cql <- readChar(species_query_file_path, file.info(species_query_file_path)$size)
species_data <- neo4j_query(graphdb, cql)

release_date <- arguments$release_date
tree_file <- arguments$tree
need_html <- ifelse(arguments$no_html == "TRUE", FALSE, TRUE)

stats_data <- paste(arguments$output, "release_stats", sep = "/")
write.table(species_data,
            file = stats_data,
            quote = FALSE,
            sep = "\t",
            row.names = FALSE,
            col.names = TRUE)

four_stats_out_file <- stats_data
ordered_table_out_file_tsv <- paste(arguments$output, "ordered_release_stats.tsv", sep = "/")
ordered_table_out_file_html <- paste(arguments$output, "ordered_release_stats.html", sep = "/")
reaction_stats_out_file <- paste(arguments$output, "reaction_release_stats", sep = "/")
summary_stats_out_file <- paste(arguments$output, "summary_stats.json", sep = "/")

summary_query_filepath <- "./cypher_queries/summary.cyp"
cql <- readChar(summary_query_filepath, file.info(summary_query_filepath)$size)
summary_data <- neo4j_query(graphdb, cql)

summary_json <- toJSON(summary_data, pretty = TRUE)
cat(summary_json, file = summary_stats_out_file)

plot_stats <- plot_stats(stats_data,
                         four_stats_out_file,
                         reaction_stats_out_file,
                         ordered_table_out_file_tsv,
                         ordered_table_out_file_html,
                         release_version,
                         release_date,
                         tree_file,
                         need_html)
