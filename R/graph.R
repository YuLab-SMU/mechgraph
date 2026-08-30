mg_graph <- function(nodes, edges, metadata = list(), validate = TRUE) {
    nodes <- as.data.frame(nodes, stringsAsFactors = FALSE)
    edges <- as.data.frame(edges, stringsAsFactors = FALSE)

    x <- list(
        nodes = nodes,
        edges = edges,
        metadata = metadata
    )
    class(x) <- "mechgraph"

    if (validate) {
        mg_validate(x)
    }

    x
}

mg_empty <- function(metadata = list()) {
    nodes <- data.frame(
        id = character(),
        type = character(),
        label = character(),
        stringsAsFactors = FALSE
    )
    edges <- data.frame(
        from = character(),
        to = character(),
        type = character(),
        stringsAsFactors = FALSE
    )
    mg_graph(nodes, edges, metadata = metadata)
}

is_mechgraph <- function(x) {
    inherits(x, "mechgraph")
}

#' @export
#' @noRd
print.mechgraph <- function(x, ...) {
    cat("<mechgraph>\n")
    cat("  nodes: ", nrow(x$nodes), "\n", sep = "")
    cat("  edges: ", nrow(x$edges), "\n", sep = "")
    node_types <- unique(x$nodes$type)
    edge_types <- unique(x$edges$type)
    if (length(node_types)) {
        cat("  node types: ", paste(node_types, collapse = ", "), "\n", sep = "")
    }
    if (length(edge_types)) {
        cat("  edge types: ", paste(edge_types, collapse = ", "), "\n", sep = "")
    }
    invisible(x)
}

#' @export
#' @noRd
as.data.frame.mechgraph <- function(x, row.names = NULL, optional = FALSE, ...) {
    mg_edges(x)
}
