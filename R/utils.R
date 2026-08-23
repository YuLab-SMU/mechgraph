## stable wrapper over the yulab.utils download helper.
## `mydownload` is not exported by yulab.utils; resolve it at run time via
## getFromNamespace (the CRAN-friendly way to use an internal) instead of
## a `:::` call.
.mg_download <- function(url, destfile) {
    getFromNamespace("mydownload", "yulab.utils")(url, destfile)
}

rbind_fill <- function(...) {
    dots <- list(...)
    if (length(dots) == 1 && is.list(dots[[1]]) && !is.data.frame(dots[[1]])) {
        dots <- dots[[1]]
    }
    dots <- dots[vapply(dots, function(x) !is.null(x) && nrow(x) > 0, logical(1))]
    if (!length(dots)) {
        return(data.frame())
    }

    all_names <- unique(unlist(lapply(dots, names), use.names = FALSE))
    dots <- lapply(dots, function(x) {
        missing <- setdiff(all_names, names(x))
        for (name in missing) {
            x[[name]] <- NA
        }
        x[all_names]
    })

    do.call(rbind, c(dots, make.row.names = FALSE))
}

empty_like <- function(x) {
    out <- x[0, , drop = FALSE]
    row.names(out) <- NULL
    out
}

match_edge_rows <- function(edges, query) {
    query <- as.data.frame(query, stringsAsFactors = FALSE)
    require_columns(query, c("from", "to", "type"), "`edges`")

    key <- paste(edges$from, edges$to, edges$type, sep = "\r")
    query_key <- paste(query$from, query$to, query$type, sep = "\r")
    key %in% query_key
}
