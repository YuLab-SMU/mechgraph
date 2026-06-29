mg_validate <- function(x) {
    if (!is_mechgraph(x)) {
        stop("`x` must be a mechgraph object.", call. = FALSE)
    }

    if (!is.data.frame(x$nodes)) {
        stop("`x$nodes` must be a data.frame.", call. = FALSE)
    }
    if (!is.data.frame(x$edges)) {
        stop("`x$edges` must be a data.frame.", call. = FALSE)
    }
    if (!is.list(x$metadata)) {
        stop("`x$metadata` must be a list.", call. = FALSE)
    }

    require_columns(x$nodes, c("id", "type", "label"), "`nodes`")
    require_columns(x$edges, c("from", "to", "type"), "`edges`")

    ids <- as.character(x$nodes$id)
    if (anyNA(ids) || any(!nzchar(ids))) {
        stop("`nodes$id` must not contain missing or empty values.", call. = FALSE)
    }
    if (anyDuplicated(ids)) {
        stop("`nodes$id` must be unique.", call. = FALSE)
    }

    edges_from <- as.character(x$edges$from)
    edges_to <- as.character(x$edges$to)
    if (anyNA(edges_from) || anyNA(edges_to)) {
        stop("`edges$from` and `edges$to` must not contain missing values.", call. = FALSE)
    }

    endpoints <- unique(c(edges_from, edges_to))
    missing <- setdiff(endpoints, ids)
    if (length(missing)) {
        stop(
            "All edge endpoints must exist in `nodes$id`. Missing: ",
            paste(utils::head(missing, 5), collapse = ", "),
            if (length(missing) > 5) ", ..." else "",
            call. = FALSE
        )
    }

    invisible(TRUE)
}

require_columns <- function(x, required, label) {
    missing <- setdiff(required, names(x))
    if (length(missing)) {
        stop(
            label, " must contain required columns: ",
            paste(missing, collapse = ", "),
            call. = FALSE
        )
    }
    invisible(TRUE)
}
