mg_qc <- function(x) {
    mg_validate(x)

    list(
        n_nodes = nrow(x$nodes),
        n_edges = nrow(x$edges),
        n_isolated_nodes = length(setdiff(x$nodes$id, unique(c(x$edges$from, x$edges$to)))),
        node_type_distribution = table_or_empty(x$nodes$type),
        edge_type_distribution = table_or_empty(x$edges$type),
        edge_source_distribution = if ("source" %in% names(x$edges)) {
            table_or_empty(x$edges$source)
        } else {
            table()
        }
    )
}

table_or_empty <- function(x) {
    if (!length(x)) {
        table(character())
    } else {
        table(x, useNA = "ifany")
    }
}
