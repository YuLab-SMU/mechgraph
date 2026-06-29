mg_nodes <- function(x) {
    mg_validate(x)
    x$nodes
}

mg_edges <- function(x) {
    mg_validate(x)
    x$edges
}

mg_metadata <- function(x) {
    mg_validate(x)
    x$metadata
}

mg_sources <- function(x) {
    mg_validate(x)
    values <- character()
    if ("source" %in% names(x$nodes)) {
        values <- c(values, as.character(x$nodes$source))
    }
    if ("source" %in% names(x$edges)) {
        values <- c(values, as.character(x$edges$source))
    }
    sort(unique(values[!is.na(values) & nzchar(values)]))
}
