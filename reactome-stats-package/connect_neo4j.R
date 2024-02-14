connect_neo4j <- function(arguments) {
  graphdb <- list(
    address = paste0("bolt://", paste(arguments$host, arguments$port, sep = ":")),
    uid = ifelse(!is.null(arguments$user), arguments$user, ""),
    pwd = ifelse(!is.null(arguments$password), arguments$password, "")
  )
  return(graphdb)
}
