# Reactome Statistics Generator

## Cypher queries to generate automatically release statistics

Cypher queries are used to generate stats files. This file is used for the R script to generate image files for two Reaction web pages: [Statistics](https://reactome.org/about/statistics "Statistics") and [Computationally Inferred Events](https://reactome.org/documentation/inferred-events "Computationally Inferred Events")

## R script to generate image files

reactome_release_stats.R is used to generate the plot for the release stats. To use this script, install R first. It is supposed to work with the latest version of R. But using **R 4.2** is recommended to avoid any incompatibility headache with used libraries. 

To run this script, the tree file, species_tree.nwk, is needed. This tree file was generated using [TimeTree](http://timetree.org "timetree") and displayed on the linear timescale for distances between species.

To run this script, provide the following parameter in a script as follows:

```
Rscipt reactome_release_stats.R --help
```

```
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
  --no-html    Set of you don't want to generate the interactive html file [default: FALSE]
  --output=DIR  Folder to put output files into [default: output]
  --tree=FILE    The species tree file [default: species_tree.nwk]
```
## After running the following files should be in the output folder

- release_stats.png
- reaction_release_stats.png
- ordered_release_stats.tsv (re-ordered release_stats file. The order is based on the tree)
- ordered_release_stats.html
- release_stats.html (if need_html is set as TRUE)
- release_stats_files (if need_html is set as TRUE. A folder contains required JavaScript libraries)
- summary_stats.json



Reaction release stats are placed here: [https://reactome.org/documentation/inferred-events](https://reactome.org/documentation/inferred-events "reaction_release_stat")

release_date should be something like "June 2023" (Quotation marks are needed!)

**Note: To make the interactive html version work, pandoc is needed. Pandoc can be installed by following this doc: https://pandoc.org/installing.html**

## Docker

To create the image:

```bash
make build-image
```

To run the image:

```bash
docker run -v $(pwd)/output:/output --net=host  reactome/statistics-generator:1.0.0 /bin/bash -c 'Rscript reactome_release_stats.R "June 2023"'
```

setting "net" equal to "host" will make it so that the statistics-generator has access to the noe4j running on the host.

This repo is being continuously integrated using Jenkins using the Jenkinsfile-ci and the statistics-generator image is stored in ECR.
