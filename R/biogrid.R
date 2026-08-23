mg_biogrid_versions <- function() {
    c("latest")
}

mg_biogrid_file_url <- function(version = "latest",
                                dataset = c("mv_physical", "all"),
                                format = c("tab3", "mitab")) {
    dataset <- match.arg(dataset)
    format <- match.arg(format)

    version_label <- normalize_biogrid_version(version)
    release_dir <- if (identical(version_label, "LATEST")) {
        "Latest-Release"
    } else {
        paste0("Release-Archive/BIOGRID-", version_label)
    }

    dataset_label <- switch(
        dataset,
        mv_physical = "MV-Physical",
        all = "ALL"
    )

    paste0(
        "https://downloads.thebiogrid.org/Download/BioGRID/",
        release_dir,
        "/BIOGRID-", dataset_label, "-", version_label, ".", format, ".zip"
    )
}

mg_biogrid_download <- function(version = "latest",
                                dataset = c("mv_physical", "all"),
                                format = c("tab3", "mitab"),
                                cache = TRUE,
                                destdir = NULL,
                                quiet = TRUE) {
    dataset <- match.arg(dataset)
    format <- match.arg(format)
    url <- mg_biogrid_file_url(version = version, dataset = dataset, format = format)

    if (is.null(destdir)) {
        destdir <- file.path(yulab.utils::user_dir("mechgraph"), "biogrid")
    }
    if (!dir.exists(destdir)) {
        dir.create(destdir, recursive = TRUE, showWarnings = FALSE)
    }

    destfile <- file.path(destdir, basename(url))
    if (!cache || !file.exists(destfile)) {
        .mg_download(url, destfile)
    }

    destfile
}

mg_from_biogrid <- function(file = NULL,
                            version = "latest",
                            dataset = "mv_physical",
                            format = c("tab3", "mitab"),
                            taxon_id = NULL,
                            cache = TRUE) {
    format <- match.arg(format)
    source_url <- NA_character_
    if (is.null(file)) {
        source_url <- mg_biogrid_file_url(version = version, dataset = dataset, format = format)
        file <- mg_biogrid_download(
            version = version,
            dataset = dataset,
            format = format,
            cache = cache
        )
    }

    parsed <- mg_biogrid_parse(file, format = format, taxon_id = taxon_id)
    metadata <- list(
        source = "BioGRID",
        source_version = version,
        dataset = dataset,
        format = format,
        taxon_id = taxon_id,
        url = source_url,
        retrieved_at = as.character(Sys.time()),
        license = "MIT"
    )

    mg_from_edges(parsed$edges, nodes = parsed$nodes, metadata = metadata)
}

mg_biogrid_parse <- function(file, format = c("tab3", "mitab"), taxon_id = NULL) {
    format <- match.arg(format)
    path <- resolve_biogrid_table(file)

    if (identical(format, "tab3")) {
        parse_biogrid_tab3(path, taxon_id = taxon_id)
    } else {
        parse_biogrid_mitab(path, taxon_id = taxon_id)
    }
}

parse_biogrid_tab3 <- function(file, taxon_id = NULL) {
    x <- utils::read.delim(
        file,
        sep = "\t",
        header = TRUE,
        quote = "",
        comment.char = "",
        check.names = FALSE,
        stringsAsFactors = FALSE
    )

    cols <- names(x)
    id_a <- first_existing(cols, c("BioGRID ID Interactor A", "Systematic Name Interactor A", "Official Symbol Interactor A"))
    id_b <- first_existing(cols, c("BioGRID ID Interactor B", "Systematic Name Interactor B", "Official Symbol Interactor B"))
    symbol_a <- first_existing(cols, c("Official Symbol Interactor A", "Systematic Name Interactor A"))
    symbol_b <- first_existing(cols, c("Official Symbol Interactor B", "Systematic Name Interactor B"))
    tax_a <- first_existing(cols, c("Organism ID Interactor A"))
    tax_b <- first_existing(cols, c("Organism ID Interactor B"))

    if (is.null(id_a) || is.null(id_b)) {
        stop("Could not identify BioGRID interactor columns in TAB3 file.", call. = FALSE)
    }

    if (!is.null(taxon_id) && !is.null(tax_a) && !is.null(tax_b)) {
        keep <- as.character(x[[tax_a]]) == as.character(taxon_id) &
            as.character(x[[tax_b]]) == as.character(taxon_id)
        x <- x[keep, , drop = FALSE]
    }

    from <- paste0("BIOGRID:", x[[id_a]])
    to <- paste0("BIOGRID:", x[[id_b]])
    label_a <- if (!is.null(symbol_a)) x[[symbol_a]] else from
    label_b <- if (!is.null(symbol_b)) x[[symbol_b]] else to

    edges <- data.frame(
        from = from,
        to = to,
        type = "ppi",
        source = "BioGRID",
        evidence = value_or_na(x, "Experimental System"),
        evidence_type = value_or_na(x, "Experimental System Type"),
        pmid = value_or_na(x, "Pubmed ID"),
        stringsAsFactors = FALSE
    )

    nodes <- unique_node_table(
        id = c(from, to),
        label = c(label_a, label_b),
        taxon_id = c(value_or_na(x, tax_a), value_or_na(x, tax_b))
    )

    list(nodes = nodes, edges = edges)
}

parse_biogrid_mitab <- function(file, taxon_id = NULL) {
    x <- utils::read.delim(
        file,
        sep = "\t",
        header = FALSE,
        quote = "",
        comment.char = "",
        check.names = FALSE,
        stringsAsFactors = FALSE
    )
    if (ncol(x) < 2) {
        stop("MITAB file must contain at least two interactor columns.", call. = FALSE)
    }

    if (!is.null(taxon_id) && ncol(x) >= 11) {
        keep <- grepl(paste0("taxid:", taxon_id, "\\b"), x[[10]]) &
            grepl(paste0("taxid:", taxon_id, "\\b"), x[[11]])
        x <- x[keep, , drop = FALSE]
    }

    from <- normalize_mitab_id(x[[1]])
    to <- normalize_mitab_id(x[[2]])
    labels <- if (ncol(x) >= 5) {
        list(normalize_mitab_alias(x[[5]]), normalize_mitab_alias(x[[6]]))
    } else {
        list(from, to)
    }

    edges <- data.frame(
        from = from,
        to = to,
        type = "ppi",
        source = "BioGRID",
        evidence = if (ncol(x) >= 7) x[[7]] else NA_character_,
        pmid = if (ncol(x) >= 9) x[[9]] else NA_character_,
        stringsAsFactors = FALSE
    )

    nodes <- unique_node_table(
        id = c(from, to),
        label = c(labels[[1]], labels[[2]])
    )

    list(nodes = nodes, edges = edges)
}

resolve_biogrid_table <- function(file) {
    if (grepl("[.]zip$", file, ignore.case = TRUE)) {
        files <- utils::unzip(file, list = TRUE)
        candidates <- files$Name[!grepl("/$", files$Name)]
        if (!length(candidates)) {
            stop("BioGRID zip file does not contain a table.", call. = FALSE)
        }
        exdir <- tempfile("mechgraph-biogrid-")
        dir.create(exdir)
        utils::unzip(file, files = candidates[1], exdir = exdir)
        file.path(exdir, candidates[1])
    } else {
        file
    }
}

normalize_biogrid_version <- function(version) {
    if (tolower(version) %in% c("latest", "current")) {
        "LATEST"
    } else {
        as.character(version)
    }
}

first_existing <- function(x, candidates) {
    hit <- candidates[candidates %in% x]
    if (length(hit)) hit[[1]] else NULL
}

value_or_na <- function(x, column) {
    if (is.null(column) || !column %in% names(x)) {
        rep(NA_character_, nrow(x))
    } else {
        as.character(x[[column]])
    }
}

unique_node_table <- function(id, label, taxon_id = NULL) {
    if (is.null(taxon_id)) {
        taxon_id <- rep(NA_character_, length(id))
    }
    nodes <- data.frame(
        id = as.character(id),
        type = "protein",
        label = as.character(label),
        taxon_id = as.character(taxon_id),
        stringsAsFactors = FALSE
    )
    nodes[!duplicated(nodes$id), , drop = FALSE]
}

normalize_mitab_id <- function(x) {
    sub("^[^:]+:", "", as.character(x))
}

normalize_mitab_alias <- function(x) {
    y <- sub("[|].*$", "", as.character(x))
    sub("^[^:]+:", "", y)
}
