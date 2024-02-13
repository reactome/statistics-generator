#!/usr/bin/env Rscript

# Install lintr package
install.packages("lintr")

# Define the paths to the R files to be linted
r_files <- c(
  "reactome-stats-package/statistics_functions.R",
  "reactome-stats-package/run.R"
)

# Run linting on the specified files
lintr::lint(r_files)
