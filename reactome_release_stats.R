# Check and install packages needed.
packages <- c("tidyverse", "ggplot2", "magrittr", "ggiraph", "patchwork", "htmlwidgets", "plotly", "pandoc")

using <- function(...) {
    libs<-unlist(list(...))
    req<-unlist(lapply(libs,require,character.only=TRUE))
    need<-libs[req==FALSE]
    if(length(need)>0){ 
        install.packages(need, repos = "http://cran.us.r-project.org")
        lapply(need,require,character.only=TRUE)
    }
}
using(packages)

# ggtree is at bioconduct, need something specially for it
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager", repos = "http://cran.us.r-project.org")
if (!require("ggtree", quietly = TRUE)) {
    BiocManager::install("ggtree")
    require("ggtree")
}

# Files to use
tree_file <- "species_tree.nwk"
release_version <- "85"
release_date <- "June 2023"
stats_data <- paste(release_version, "release_stats", sep="/")
ordered_table_out_file <- paste(release_version, "ordered_release_stats.tsv", sep="/")
four_stats_out_file <- stats_data
reaction_stats_out_file <- paste(release_version, "reaction_release_stats", sep = "/")
need_html <- FALSE # Off by default

plot_stats <- function(stats_data,
                       four_stats_out_file,
                       reaction_stats_out_file,
                       ordered_table_out_file,
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
    ordered_short_names <- ifelse(ordered_short_names == "H. sapiens",  "*H. sapiens", ordered_short_names)
    name_key <- data_frame(SPECIES = ordered_short_names, full_name = ordered_names)
    
    #read data file and transform into long format.
    raStats <- read.delim(file = stats_data)
    raStats <- raStats %>% head (n=15) %>% arrange(match(SPECIES, ordered_short_names))# match the order of species in table and tree
    write.table(raStats, ordered_table_out_file, quote = FALSE, sep = "\t", row.names = FALSE) # save ordered data as table
    raStats_long <- raStats %>% head(n=15) %>% pivot_longer(-SPECIES, names_to = "feature", values_to = "counts") %>%
                    inner_join(name_key, by= "SPECIES")
    title_str <- paste0(paste0("Reactome Version ", release_version), "\n", "Panther\n", release_date)
    
    #factor catgories and subcatgories.
    raStats_long$full_name <- factor(raStats_long$full_name,
                                     levels = ordered_names)
    raStats_long$feature <- factor(raStats_long$feature,
                                   levels = c("PATHWAYS", "REACTIONS", "COMPLEXES", "PROTEINS"))
    
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
        scale_fill_manual(values = c('blue','red', 'green','grey')) +
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
                               levels = ordered_short_names)
   
    rxn_plot <- raStats_rxns %>% ggplot(aes(x= SPECIES, y = pct_rxns)) +
      geom_bar(aes(color = ifelse(SPECIES == "*H. sapiens", "highlight", "default")), 
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

# Get parameters from the command
args <- commandArgs(TRUE);

# two arguemtns should be provided at least
if (length(args) < 2) {
    stop("Two arguments are needed (release_version release_date)");
}

if (length(args) == 2) {
    release_version = args[1]
    release_date = args[2]
}else if (length(args) == 3) { # Don't put this as a new line in R
    release_version = args[1]
    release_date = args[2]
    need_html = ifelse(args[3] == 'TRUE', TRUE, FALSE)
}else if (length(args) == 8) { # Don't put this as a new line in R
    release_version = args[1]
    release_date = args[2]
    need_html = ifelse(args[3] == 'TRUE', TRUE, FALSE)
    stats_data = args[4]
    four_stats_out_file = args[5]
    reaction_stats_out_file = args[6]
    ordered_table_out_file = args[7]
    tree_file = args[8]
}

plot_stats(stats_data,
           four_stats_out_file,
           reaction_stats_out_file,
           ordered_table_out_file,
           release_version,
           release_date,
           tree_file,
           need_html)
