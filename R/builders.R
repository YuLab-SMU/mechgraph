mg_from_edges <- function(edges, nodes = NULL, metadata = list()) {
    edges <- as.data.frame(edges, stringsAsFactors = FALSE)
    require_columns(edges, c("from", "to", "type"), "`edges`")

    edges$from <- as.character(edges$from)
    edges$to <- as.character(edges$to)
    edges$type <- as.character(edges$type)

    if (is.null(nodes)) {
        ids <- unique(c(edges$from, edges$to))
        nodes <- data.frame(
            id = ids,
            type = "unknown",
            label = ids,
            stringsAsFactors = FALSE
        )
    } else {
        nodes <- as.data.frame(nodes, stringsAsFactors = FALSE)
        require_columns(nodes, c("id", "type", "label"), "`nodes`")
        nodes$id <- as.character(nodes$id)
        nodes$type <- as.character(nodes$type)
        nodes$label <- as.character(nodes$label)
    }

    mg_graph(nodes = nodes, edges = edges, metadata = metadata)
}

as_mechgraph <- function(x, ...) {
    UseMethod("as_mechgraph")
}

#' @export
#' @noRd
as_mechgraph.data.frame <- function(x, ...) {
    mg_from_edges(x, ...)
}

#' @export
#' @noRd
as_mechgraph.mechgraph <- function(x, ...) {
    x
}
