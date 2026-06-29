mg_add_nodes <- function(x, nodes) {
    mg_validate(x)
    nodes <- as.data.frame(nodes, stringsAsFactors = FALSE)
    require_columns(nodes, c("id", "type", "label"), "`nodes`")

    out <- x
    out$nodes <- rbind_fill(x$nodes, nodes)
    mg_graph(out$nodes, out$edges, metadata = x$metadata)
}

mg_add_edges <- function(x, edges, add_missing_nodes = FALSE) {
    mg_validate(x)
    edges <- as.data.frame(edges, stringsAsFactors = FALSE)
    require_columns(edges, c("from", "to", "type"), "`edges`")

    nodes <- x$nodes
    endpoints <- unique(c(as.character(edges$from), as.character(edges$to)))
    missing <- setdiff(endpoints, as.character(nodes$id))
    if (length(missing) && add_missing_nodes) {
        nodes <- rbind_fill(
            nodes,
            data.frame(
                id = missing,
                type = "unknown",
                label = missing,
                stringsAsFactors = FALSE
            )
        )
    }

    mg_graph(nodes, rbind_fill(x$edges, edges), metadata = x$metadata)
}

mg_drop_nodes <- function(x, nodes) {
    mg_validate(x)
    ids <- if (is.data.frame(nodes)) {
        as.character(nodes$id)
    } else {
        as.character(nodes)
    }

    keep_nodes <- !as.character(x$nodes$id) %in% ids
    keep_edges <- !as.character(x$edges$from) %in% ids &
        !as.character(x$edges$to) %in% ids

    mg_graph(
        x$nodes[keep_nodes, , drop = FALSE],
        x$edges[keep_edges, , drop = FALSE],
        metadata = x$metadata
    )
}

mg_drop_edges <- function(x, edges) {
    mg_validate(x)

    if (is.logical(edges)) {
        if (length(edges) != nrow(x$edges)) {
            stop("Logical `edges` must have length equal to the number of edges.", call. = FALSE)
        }
        drop <- edges
    } else if (is.numeric(edges)) {
        drop <- seq_len(nrow(x$edges)) %in% edges
    } else {
        drop <- match_edge_rows(x$edges, edges)
    }

    mg_graph(
        x$nodes,
        x$edges[!drop, , drop = FALSE],
        metadata = x$metadata
    )
}

mg_bind <- function(...) {
    graphs <- list(...)
    if (length(graphs) == 1 && is.list(graphs[[1]]) && !is_mechgraph(graphs[[1]])) {
        graphs <- graphs[[1]]
    }
    if (!length(graphs)) {
        return(mg_empty())
    }

    lapply(graphs, mg_validate)
    nodes <- rbind_fill(lapply(graphs, mg_nodes))
    nodes <- nodes[!duplicated(as.character(nodes$id)), , drop = FALSE]
    edges <- rbind_fill(lapply(graphs, mg_edges))

    metadata <- list(
        source = "mg_bind",
        inputs = lapply(graphs, mg_metadata)
    )

    mg_graph(nodes, edges, metadata = metadata)
}

mg_combine <- function(..., merge_nodes = TRUE, merge_edges = FALSE) {
    x <- mg_bind(...)
    if (merge_edges) {
        edge_key <- paste(x$edges$from, x$edges$to, x$edges$type, sep = "\r")
        x$edges <- x$edges[!duplicated(edge_key), , drop = FALSE]
        x <- mg_graph(x$nodes, x$edges, metadata = x$metadata)
    }
    x
}
