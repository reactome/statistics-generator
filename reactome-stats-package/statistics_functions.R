source("connect_neo4j.R")

suppressPackageStartupMessages(library("tidyverse"))
suppressPackageStartupMessages(library("tidyr"))
suppressPackageStartupMessages(library("magrittr"))
suppressPackageStartupMessages(library("ggiraph"))
suppressPackageStartupMessages(library("htmlwidgets"))
suppressPackageStartupMessages(library("plotly"))
suppressPackageStartupMessages(library("pandoc"))
suppressPackageStartupMessages(library("ggtree"))
suppressPackageStartupMessages(library("gt"))
suppressPackageStartupMessages(library("patchwork"))
suppressPackageStartupMessages(library("neo4jshell"))
suppressPackageStartupMessages(library("jsonlite"))
suppressPackageStartupMessages(library("ape"))
suppressPackageStartupMessages(library("tibble"))
suppressPackageStartupMessages(library("dplyr"))
suppressPackageStartupMessages(library("ggplot2"))


plot_stats <- function(stats_data,
                       four_stats_out_file,
                       reaction_stats_out_file,
                       ordered_table_out_file_tsv,
                       ordered_table_out_file_html,
                       release_version,
                       release_date,
                       tree_file,
                       need_html = FALSE) {

  SPECIES <- NULL # nolint[object_usage_linter]

  # Make phyloTree.
  phylotree <- read.tree(file = tree_file)
  phylotree$tip.label <- gsub("_", " ", phylotree$tip.label)
  tree <- ggtree(phylotree, layout = "rectangular", ladderize = TRUE, size = 0.6, branch.length = "none") +
    geom_tiplab(as_ylab = TRUE, size = 10, face = "bold")

  ordered_names <- get_taxa_name()

  # Match the full names with the short names in the stats data file.
  ordered_short_names <- paste0(substring(ordered_names, 1, 1), ". ", gsub("([A-z]+)\\s([A-z]+)", "\\2", ordered_names))
  name_key <- tibble(SPECIES = ordered_names, short_name = ordered_short_names, full_name = ordered_names)

  #read data file and transform into long format.
  ra_stats <- read.delim(file = stats_data)
  ra_stats <- ra_stats %>%
    head(n = 15) %>%
    arrange(match(SPECIES, ordered_names)) # match the order of species in table and tree
  write.table(ra_stats, ordered_table_out_file_tsv, quote = FALSE, sep = "\t", row.names = FALSE) # save ordered data as table

  ra_stats |>
    gt() |>
    cols_align(align = "right", columns = SPECIES) |>
    cols_label(SPECIES = "Species", PROTEINS = "Proteins", ISOFORMS = "Isoforms", COMPLEXES = "Complexes", REACTIONS = "Reactions", PATHWAYS = "Pathways") |>
    fmt_number(decimals = 0, use_seps = TRUE) |>
    tab_style(style = cell_text(weight = "bold"), locations = cells_column_labels()) |>
    tab_style(style = cell_text(style = "italic"), locations = cells_body(columns = SPECIES)) |>
    as_raw_html() |>
    write(file = ordered_table_out_file_html)


  ra_stats_long <- ra_stats %>%
    head(n = 15) %>%
    pivot_longer(-SPECIES, names_to = "feature", values_to = "counts") %>%
    inner_join(name_key, by = "SPECIES")

  title_str <- paste0("Reactome Version ", release_version, ", Panther, ", release_date)

  #factor catgories and subcatgories.
  ra_stats_long$full_name <- factor(ra_stats_long$full_name,
                                    levels = ordered_names)
  ra_stats_long$feature <- factor(ra_stats_long$feature,
                                 levels = c("PATHWAYS", "REACTIONS", "COMPLEXES", "PROTEINS", "ISOFORMS"))

  # plot all four features along with tree
  ra_stats_long <- ra_stats_long %>% mutate(tooltip = paste(full_name, "\n", counts, feature)) # nolint[object_usage_linter]
  bar_plot <- ra_stats_long %>% ggplot(aes(x = full_name, y = counts, fill = feature, # nolint[object_usage_linter]
                                          tooltip = tooltip, # nolint[object_usage_linter]
                                          data_id = feature)) + # nolint[object_usage_linter]
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


  combined_plot <- tree +
    bar_plot +
    plot_layout(ncol = 2, widths = c(1, 3))

  # Output as a png file
  ggsave(combined_plot, file = paste0(four_stats_out_file, ".png"), width = 14, height = 8, dpi = 300)

  # plot "reactions" counts along with tree, normalized to counts in H. sapiens.
  ra_stats_rxns <- ra_stats %>% mutate(pct_rxns = 100 * REACTIONS / max(REACTIONS)) # nolint[object_usage_linter]
  ra_stats_rxns$SPECIES <- factor(ra_stats_rxns$SPECIES,
                                 levels = ordered_names)
  rxn_plot <- ra_stats_rxns %>% ggplot(aes(x = SPECIES, y = pct_rxns)) + # nolint[object_usage_linter]
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

  combined_plot_rxns <- tree +
    rxn_plot +
    plot_layout(ncol = 2, widths = c(1, 3))
  ggsave(combined_plot_rxns, file = paste0(reaction_stats_out_file, ".png"), width = 14, height = 8, dpi = 300)


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
    # Output as a html
    htmlwidgets::saveWidget(as_widget(ff), paste0(four_stats_out_file, ".html"))
  }
}
