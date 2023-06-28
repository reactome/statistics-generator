#!/usr/bin/env Rscript

suppressPackageStartupMessages(library("docopt"))
suppressPackageStartupMessages(library('tidyverse'))
suppressPackageStartupMessages(library('magrittr'))
suppressPackageStartupMessages(library('ggiraph'))
suppressPackageStartupMessages(library('htmlwidgets'))
suppressPackageStartupMessages(library('plotly'))
suppressPackageStartupMessages(library('pandoc'))
suppressPackageStartupMessages(library('ggtree'))
suppressPackageStartupMessages(library('patchwork'))
suppressPackageStartupMessages(library('neo4jshell'))
suppressPackageStartupMessages(library('xtable'))
suppressPackageStartupMessages(library('jsonlite'))

'Statistics Generator

Usage:
  reactome_release_stats.R [options] <release_date>
  reactome_release_stats.R (-h | --help)
  reactome_release_stats.R --version

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

' -> doc
arguments <- docopt(doc, version="1.0.0")

graphdb <- list(address = paste("bolt://",
                                paste(arguments$host,
                                      arguments$port,
                                      sep=":"),
                                sep=""),
                uid = arguments$user,
                pwd = arguments$password)

CQL <- "MATCH (n:DBInfo) RETURN n.version AS version;"
db_info = neo4j_query(graphdb, CQL)

release_version = db_info[1,"version"]
print(paste("release_version", release_version, sep = ": "))

species_query_file_path <- "./cypher_queries/species.cyp"
CQL <- readChar(species_query_file_path, file.info(species_query_file_path)$size)
species_data <- neo4j_query(graphdb, CQL)

release_date = arguments$release_date
tree_file <- arguments$tree
need_html = ifelse(arguments$no_html == 'TRUE', FALSE, TRUE)

stats_data = paste(arguments$output, "release_stats", sep = "/")
write.table(species_data,
            file = stats_data,
            quote = FALSE,
            sep ="\t",
            row.names = FALSE,
            col.names = TRUE)

four_stats_out_file <- stats_data
ordered_table_out_file_tsv <- paste(arguments$output, "ordered_release_stats.tsv", sep="/")
ordered_table_out_file_html <- paste(arguments$output, "ordered_release_stats.html", sep="/")
reaction_stats_out_file <- paste(arguments$output, "reaction_release_stats", sep="/")
summary_stats_out_file <- paste(arguments$output, "summary_stats.json", sep="/")

summary_query_filepath <- "./cypher_queries/summary.cyp"
CQL <- readChar(summary_query_filepath, file.info(summary_query_filepath)$size)
summary_data <- neo4j_query(graphdb, CQL)

summary_json = toJSON(summary_data, pretty=TRUE)
cat(summary_json, file=summary_stats_out_file)

plot_stats <- function(stats_data,
                       four_stats_out_file,
                       reaction_stats_out_file,
                       ordered_table_out_file_tsv,
                       ordered_table_out_file_html,
                       release_version,
                       release_date,
                       tree_file,
                       need_html = FALSE) {
    # Make phyloTree.
    phylotree <- read.tree(file = tree_file)
    phylotree$tip.label <- gsub("_", " ", phylotree$tip.label)
    tree <- ggtree(phylotree, layout = "rectangular", ladderize = FALSE, size = 0.6) +
            geom_tiplab(as_ylab = TRUE, size = 10)
    
    ordered_names <- get_taxa_name()
    
    # Match the full names with the short names in the stats data file.
    ordered_short_names <- paste0(substring(ordered_names, 1, 1),". ", gsub("([A-z]+)\\s([A-z]+)", "\\2", ordered_names))
    name_key <- tibble(SPECIES = ordered_names, short_name = ordered_short_names, full_name=ordered_names)

    #read data file and transform into long format.
    raStats <- read.delim(file = stats_data)
    raStats <- raStats %>% head (n=15) %>% arrange(match(SPECIES, ordered_names))# match the order of species in table and tree
    write.table(raStats, ordered_table_out_file_tsv, quote = FALSE, sep = "\t", row.names = FALSE) # save ordered data as table

    print(xtable(raStats),
          include.rownames=FALSE,
          type="html",
          file=ordered_table_out_file_html)

    raStats_long <- raStats %>% head(n=15) %>% pivot_longer(-SPECIES, names_to = "feature", values_to = "counts") %>%
                    inner_join(name_key, by= "SPECIES")

    title_str <- paste0(paste0("Reactome Version ", release_version), "\n", "Panther\n", release_date)

    #factor catgories and subcatgories.
    raStats_long$full_name <- factor(raStats_long$full_name,
                                     levels = ordered_names)
    raStats_long$feature <- factor(raStats_long$feature,
                                   levels = c("PATHWAYS", "REACTIONS", "COMPLEXES", "PROTEINS", "ISOFORMS"))

    # plot all four features along with tree
    raStats_long <- raStats_long %>% mutate(tooltip = paste(full_name, "\n", counts, feature))
    bar_plot <- raStats_long %>% ggplot(aes(x= full_name, y = counts, fill = feature, 
                                            tooltip = tooltip,
                                            data_id = feature)) +
        geom_bar_interactive(stat="identity", position = "dodge", color = "black",
                             linewidth = 0.2, width = 0.8) +
        geom_hline(yintercept = 0, linewidth = 0.2) +
        coord_flip() +
        ggtitle(title_str) +
        scale_x_discrete(limits = rev(levels(raStats_long$full_name))) +
        scale_fill_manual(values = c('blue', 'red', 'green','grey', 'yellow')) +
        theme(panel.background = element_blank(),
              plot.title = element_text(size = 16, face = "bold",
                                        vjust = -16, hjust = 1),
              axis.line.x = element_line(linewidth = 0.5),
              axis.text.y = element_blank(),
              axis.title.y = element_blank(),
              axis.line.y = element_blank(),
              axis.ticks.y = element_blank(),
              legend.title = element_blank(),
              legend.key.size = unit(0.2, "cm"),
              legend.position = c(0.9, 0.1))
    
    
    combined_plot <- tree + bar_plot + plot_layout(ncol = 2, widths = c(3,3))
    # Output as a png file
    ggsave(combined_plot, file = paste0(four_stats_out_file, ".png"), width = 14, height = 6, dpi = 300)
    
    # plot "reactions" counts along with tree, normalized to counts in H. sapiens.
    raStats_rxns <- raStats %>% mutate(pct_rxns = 100*REACTIONS/max(REACTIONS))
    raStats_rxns$SPECIES <- factor(raStats_rxns$SPECIES,
                               levels = ordered_names)
    rxn_plot <- raStats_rxns %>% ggplot(aes(x= SPECIES, y = pct_rxns)) +
      geom_bar(aes(color = ifelse(SPECIES == "Homo sapiens", "highlight", "default")),
               stat="identity", fill = "red", width = 0.7, linewidth = 0.5 )+
      scale_color_manual(values = c(highlight = "black", default = "gray")) +
      geom_hline(yintercept = 0, linewidth = 0.2) + 
      ggtitle(title_str) +
      coord_flip() +
      scale_x_discrete(limits = rev(levels(raStats_rxns$SPECIES))) +
      ylab("% of human reactions inferred for model organisms") +
      theme(panel.background = element_blank(),
            plot.title = element_text(size = 14, face = "bold",
                                      vjust = -16, hjust = 0.95),
            axis.line.x = element_line(linewidth = 0.5),
            axis.text.y = element_blank(),
            axis.line.y = element_blank(),
            axis.ticks.y = element_blank(),
            axis.title.y = element_blank(),
            legend.position = "none")
    
    combined_plot_rxns<- tree + rxn_plot + plot_layout(ncol = 2, widths = c(3,3))
    ggsave(combined_plot_rxns, file = paste0(reaction_stats_out_file, ".png"), width = 14, height = 6, dpi = 300)
    
    
    # See if we need an interactive file for test
    if (need_html) {
        ff <- girafe(
            ggobj = combined_plot, width_svg = 14, height_svg = 6,
            options = list(
                opts_hover_inv(css = "opacity:0.4;"),
                opts_hover(css = "stroke-width:2;"),
                opts_hover_key(css = "stroke-width:2;"),
                opts_tooltip(use_fill = TRUE,
                             css = "padding:5pt;font-family: Open Sans;font-size:0.8rem;color:black")))
        # Output as a html
        htmlwidgets::saveWidget(as_widget(ff), paste0(four_stats_out_file, ".html"))
    }
}


plot_stats(stats_data,
           four_stats_out_file,
           reaction_stats_out_file,
           ordered_table_out_file_tsv,
           ordered_table_out_file_html,
           release_version,
           release_date,
           tree_file,
           need_html)
