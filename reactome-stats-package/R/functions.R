library(pandoc)
library(plotly)
library(htmlwidgets)
library(patchwork)
library(ggiraph)
library(magrittr)
library(neo4jshell)
library(docopt)
library(gt)
library(jsonlite)
library(ggtree)

connect_neo4j <- function(arguments) {
  graphdb <- list(
    address = paste0("bolt://", paste(arguments$host, arguments$port, sep = ":")),
    uid = arguments$user,
    pwd = arguments$password
  )
  return(graphdb)
}

retrieve_data <- function(graphdb, species_query_file_path) {
  cql <- readChar(species_query_file_path, file.info(species_query_file_path)$size)
  species_data <- neo4j_query(graphdb, cql)
  return(species_data)
}

process_data <- function(data, tree_file, output_folder) {
  # Make phyloTree.
  phylotree <- read.tree(file = tree_file)
  phylotree$tip.label <- gsub("_", " ", phylotree$tip.label)
  tree <- ggtree(phylotree, layout = "rectangular", ladderize = TRUE, size = 0.6, branch.length = "none") +
    geom_tiplab(as_ylab = TRUE, size = 10)

  ordered_names <- get_taxa_name()

  # Match the full names with the short names in the stats data file.
  ordered_short_names <- paste0(substring(ordered_names, 1, 1), ". ", gsub("([A-z]+)\\s([A-z]+)", "\\2", ordered_names))
  name_key <- tibble(SPECIES = ordered_names, short_name = ordered_short_names, full_name = ordered_names)

  #read data file and transform into long format.
  ra_stats <- data %>%
    head(n = 15) %>%
    arrange(match(SPECIES, ordered_names)) # match the order of species in table and tree

  processed_data <- list(
    ra_stats = ra_stats,
    tree = tree,
    ordered_names = ordered_names,
    ordered_table_out_file_tsv = paste(output_folder, "ordered_release_stats.tsv", sep = "/"),
    ordered_table_out_file_html = paste(output_folder, "ordered_release_stats.html", sep = "/"),
    reaction_stats_out_file = paste(output_folder, "reaction_release_stats", sep = "/"),
    summary_stats_out_file = paste(output_folder, "summary_stats.json", sep = "/")
  )

  return(processed_data)
}

plot_stats <- function(processed_data, need_html) {
  ra_stats_long <- processed_data$ra_stats %>%
    head(n = 15) %>%
    pivot_longer(-SPECIES, names_to = "feature", values_to = "counts") %>%
    inner_join(name_key, by = "SPECIES")

  title_str <- paste0("Reactome Version ", release_version, ", Panther, ", release_date)

  #factor catgories and subcategories.
  ra_stats_long$full_name <- factor(ra_stats_long$full_name,
                                   levels = ordered_names)
  ra_stats_long$feature <- factor(ra_stats_long$feature,
                                 levels = c("PATHWAYS", "REACTIONS", "COMPLEXES", "PROTEINS", "ISOFORMS"))

  # plot all four features along with tree
  ra_stats_long <- ra_stats_long %>% mutate(tooltip = paste(full_name, "\n", counts, feature))
  bar_plot <- ra_stats_long %>% ggplot(aes(x = full_name, y = counts, fill = feature,
                                          tooltip = tooltip,
                                          data_id = feature)) +
    geom_bar_interactive(stat = "identity", position = "dodge", color = "#00000022",
                         linewidth = 0.2, width = 0.8) +
    geom_hline(yintercept = 0, linewidth = 0.2) +
    coord_flip() +
    ggtitle(title_str) +
    scale_x_discrete(limits = rev(levels(ra_stats_long$full_name))) +
    scale_y_continuous(limits = c(0, max(ra_stats_long$counts)), expand = c(0, 0)) +
    scale_fill_manual(values = c("#FF8ACC", "#9686F7", "#84D9E1", "#8CF786", "#EDDD6F")) +
    theme(panel.background = element_blank(),
          plot.title = element_text(size = 16, face = "bold",
                                    vjust = 0, hjust = 0),
          axis.line.x = element_line(linewidth = 0.5),
          axis.text.y = element_blank(),
          axis.title.y = element_blank(),
          axis.line.y = element_blank(),
          axis.ticks.y = element_blank(),
          legend.title = element_blank(),
          legend.key.size = unit(0.2, "cm"),
          legend.position = c(0.9, 0.1))


  combined_plot <- processed_data$tree +
    bar_plot +
    plot_layout(ncol = 2, widths = c(1, 3))

  # Output as a png file
  ggsave(combined_plot, file = paste0(processed_data$four_stats_out_file, ".png"), width = 14, height = 8, dpi = 300)

  # plot "reactions" counts along with tree, normalized to counts in H. sapiens.
  ra_stats_rxns <- processed_data$ra_stats %>% mutate(pct_rxns = 100 * REACTIONS / max(REACTIONS))
  ra_stats_rxns$SPECIES <- factor(ra_stats_rxns$SPECIES,
                                 levels = ordered_names)
  rxn_plot <- ra_stats_rxns %>% ggplot(aes(x = SPECIES, y = pct_rxns)) +
    geom_bar(aes(color = ifelse(SPECIES == "Homo sapiens", "highlight", "default")),
             stat = "identity", fill = "#006782", width = 0.7, linewidth = 0.5) +
    scale_color_manual(values = c(highlight = "black", default = "gray")) +
    geom_hline(yintercept = 0, linewidth = 0.2) +
    ggtitle(title_str) +
    coord_flip() +
    scale_x_discrete(limits = rev(levels(ra_stats_rxns$SPECIES))) +
    ylab("% of human reactions inferred for model organisms") +
    theme(panel.background = element_blank(),
          plot.title = element_text(size = 14, face = "bold",
                                    vjust = 0, hjust = 0.95),
          axis.line.x = element_line(linewidth = 0.5),
          axis.text.y = element_blank(),
          axis.line.y = element_blank(),
          axis.ticks.y = element_blank(),
          axis.title.y = element_blank(),
          legend.position = "none")

  combined_plot_rxns <- processed_data$tree +
    rxn_plot +
    plot_layout(ncol = 2, widths = c(1, 3))
  ggsave(combined_plot_rxns, file = paste0(processed_data$reaction_stats_out_file, ".png"), width = 14, height = 8, dpi = 300)


  # See if we need an interactive file for test
  if (need_html) {
    ff <- girafe(
      ggobj = combined_plot, width_svg = 14, height_svg = 8,
      options = list(
        sizingPolicy(padding = 0),
        opts_hover_inv(css = "opacity:0.4;"),
        opts_hover(css = "stroke-width:0.5;"),
        opts_hover_key(css = "stroke-width:0.5;"),
        opts_tooltip(use_fill = TRUE,
                     css = "padding:5pt;font-family: Open Sans;font-size:0.8rem;color:black")))
    # Output as an html
    htmlwidgets::saveWidget(as_widget(ff), paste0(processed_data$four_stats_out_file, ".html"))
  }
}


