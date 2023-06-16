# statistics-generator

## Cypher queries to generate automatically release statistics

Cypher queries that are used to generate stats file. This file is used for the R script to generate image files for two Reaction web pages: [Statistics](https://reactome.org/about/statistics "Statistics") and [Computationally Inferred Events](https://reactome.org/documentation/inferred-events "Computationally Inferred Events")

## R script to generate image files

reactome_release_stats.R is used to generate the plot for the release stats. To use this script, install R first. It is supposed to work with the latest version of R. But it is recommended to use **R 4.2** to avoid any incompatibility headache with used libraries. 

To run this script, the tree file, species_tree.nwk, is needed, . This tree file was generated using [TimeTree](http://timetree.org "timetree") and displayed on the linear timescale for distances between species.

To run this script, provide the following parameter in a script as following:

```
Rscipt reactome_release_stats.R release_version release_date {need_html} {stats_data four_stats_out_file reaction_stats_out_file ordered_table_out_file tree_file}
```

The first two parameters are required. The other parameters are optional. need_html TRUE for generating an interactive html file. Its value should be "TRUE" or "FALSE" (no quotation marks. case is important. The default is FALSE). The last five parameters should be provided in all if any of them is needed: stats_data is a tab-delimited file for the numbers (default release_stats in the release folder (e.g. 85), four_stats_out_file is the prefix of the file names (default is release_stats. No need to add .png), reaction_stats_out_file is the prefix for the reaction only png file used in [https://reactome.org/documentation/inferred-events](https://reactome.org/documentation/inferred-events "reaction_release_stat") (default is reaction_release_stats), tree_file is the original tree (the default is species_tree.nwk in the folder running this script). After running the script, the following file should be generated in the release folder (e.g. folder 85) with the default settings:

- release_stats.png
- reaction_release_stats.png
- ordered_release_stats.tsv (re-ordered release_stats file. The order is based on the tree. It is a simple tab delimited file.)
- release_stats.html (if need_html is set as TRUE)
- release_stats_files (if need_html is set as TRUE. A folder contains required JavaScript libraries)

release_data should be something like "June 2023" (Quotation marks are needed!)

**Note: To make the interactive html version work, pandoc is need. Pandoc can be installed by following this doc: https://pandoc.org/installing.html**
