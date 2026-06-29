mg_filter_nodes <- function(x, type = NULL, ids = NULL, source = NULL) {
    mg_validate(x)
    keep <- rep(TRUE, nrow(x$nodes))

    if (!is.null(type)) {
        keep <- keep & as.character(x$nodes$type) %in% as.character(type)
    }
    if (!is.null(ids)) {
        keep <- keep & as.character(x$nodes$id) %in% as.character(ids)
    }
    if (!is.null(source)) {
        if (!"source" %in% names(x$nodes)) {
            keep <- rep(FALSE, nrow(x$nodes))
        } else {
            keep <- keep & as.character(x$nodes$source) %in% as.character(source)
        }
    }

    mg_induced_subgraph(x, x$nodes$id[keep])
}

mg_filter_edges <- function(x, type = NULL, source = NULL, score = NULL, weight = NULL) {
    mg_validate(x)
    keep <- rep(TRUE, nrow(x$edges))

    if (!is.null(type)) {
        keep <- keep & as.character(x$edges$type) %in% as.character(type)
    }
    if (!is.null(source)) {
        if (!"source" %in% names(x$edges)) {
            keep <- rep(FALSE, nrow(x$edges))
        } else {
            keep <- keep & as.character(x$edges$source) %in% as.character(source)
        }
    }
    if (!is.null(score)) {
        keep <- keep & numeric_filter(x$edges, "score", score)
    }
    if (!is.null(weight)) {
        keep <- keep & numeric_filter(x$edges, "weight", weight)
    }

    mg_graph(x$nodes, x$edges[keep, , drop = FALSE], metadata = x$metadata)
}

mg_induced_subgraph <- function(x, nodes) {
    mg_validate(x)
    ids <- if (is.data.frame(nodes)) {
        as.character(nodes$id)
    } else {
        as.character(nodes)
    }

    keep_nodes <- as.character(x$nodes$id) %in% ids
    keep_edges <- as.character(x$edges$from) %in% ids &
        as.character(x$edges$to) %in% ids

    mg_graph(
        x$nodes[keep_nodes, , drop = FALSE],
        x$edges[keep_edges, , drop = FALSE],
        metadata = x$metadata
    )
}

numeric_filter <- function(x, column, range) {
    if (!column %in% names(x)) {
        return(rep(FALSE, nrow(x)))
    }
    values <- suppressWarnings(as.numeric(x[[column]]))
    if (length(range) == 1) {
        values >= range
    } else if (length(range) == 2) {
        values >= min(range) & values <= max(range)
    } else {
        stop("Numeric filters must be length 1 or 2.", call. = FALSE)
    }
}
