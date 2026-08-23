## STRING evidence backend for mechgraph
##
## Downloads and parses STRING (https://string-db.org) functional
## association networks and represents them as a mechgraph with
## provenance metadata. Mirrors the BioGRID backend (R/biogrid.R):
##   mg_string_versions()   known STRING releases
##   mg_string_file_url()   download URL for a STRING table
##   mg_string_download()   download (cached) a STRING table
##   mg_string_parse()      parse STRING tables into nodes/edges
##   mg_from_string()       build a mechgraph from STRING (end to end)

## ---------------------------------------------------------------------------
## Versions and URLs
## ---------------------------------------------------------------------------

# Known STRING release versions
#
# @return Character vector of STRING releases supported by the download
#   helpers. Other versions can be passed explicitly to
#   [mg_string_file_url()] / [mg_string_download()] / [mg_from_string()].
# @export
mg_string_versions <- function() {
    c("12.0")
}

# STRING download URL
#
# @param taxon_id NCBI taxonomy id (e.g. 9606 for human). Must be numeric.
# @param version STRING release version (e.g. "12.0"). Must match
#   `^[0-9]+(\\.[0-9]+)?$`.
# @param network Which STRING table: "functional" (protein.links),
#   "physical" (protein.physical.links), "detailed" (protein.links.detailed),
#   "aliases" (protein.aliases) or "info" (protein.info).
# @return The download URL.
# @export
mg_string_file_url <- function(taxon_id = 9606,
                               version = "12.0",
                               network = c("functional", "physical", "detailed",
                                           "aliases", "info")) {
    network <- match.arg(network)
    taxon_id <- as.character(taxon_id)
    version <- as.character(version)
    if (!grepl("^[0-9]+$", taxon_id)) {
        stop("taxon_id must be numeric (NCBI taxonomy id), got: ", taxon_id,
             call. = FALSE)
    }
    if (!grepl("^[0-9]+(\\.[0-9]+)?$", version)) {
        stop("version must match '^[0-9]+(\\.[0-9]+)?$', got: ", version,
             call. = FALSE)
    }
    prefix <- switch(
        network,
        functional = "protein.links",
        physical   = "protein.physical.links",
        detailed   = "protein.links.detailed",
        aliases    = "protein.aliases",
        info       = "protein.info"
    )
    paste0(
        "https://stringdb-downloads.org/download/",
        prefix, ".v", version, "/",
        taxon_id, ".", prefix, ".v", version, ".txt.gz"
    )
}

## ---------------------------------------------------------------------------
## Download with caching
## ---------------------------------------------------------------------------

# Download a STRING table (cached)
#
# Downloads one of the STRING tables into a cache directory (default
# `yulab.utils::user_dir("mechgraph")/string`) and returns the local path.
# The download is skipped when the file is already cached.
#
# @param taxon_id NCBI taxonomy id (e.g. 9606 for human).
# @param version STRING release version (e.g. "12.0").
# @param network Which STRING table (see [mg_string_file_url()]).
# @param cache logical, reuse a previously downloaded file.
# @param destdir optional cache directory (defaults to the user cache dir).
# @return Path to the downloaded (or cached) file.
# @importFrom yulab.utils user_dir
# @export
mg_string_download <- function(taxon_id = 9606,
                               version = "12.0",
                               network = c("functional", "physical", "detailed",
                                           "aliases", "info"),
                               cache = TRUE,
                               destdir = NULL) {
    network <- match.arg(network)
    url <- mg_string_file_url(taxon_id = taxon_id, version = version,
                              network = network)

    if (is.null(destdir)) {
        destdir <- file.path(yulab.utils::user_dir("mechgraph"), "string")
    }
    if (!dir.exists(destdir)) {
        dir.create(destdir, recursive = TRUE, showWarnings = FALSE)
    }

    destfile <- file.path(destdir, basename(url))
    if (!cache || !file.exists(destfile)) {
        .mg_download(url, destfile)
        ## integrity guard: a failed/truncated download must not poison the
        ## cache for later runs
        if (!file.exists(destfile) || file.info(destfile)$size == 0) {
            unlink(destfile)
            stop("Failed to download STRING table: ", url, call. = FALSE)
        }
    }

    destfile
}

# STRING species table
#
# Downloads and returns the STRING species list for a release as a
# data.frame with columns taxon_id, STRING_type, STRING_name_compact,
# official_name_NCBI and domain.
#
# @param version STRING release version (e.g. "12.0").
# @param cache logical, reuse a previously downloaded file.
# @return A data.frame of STRING species.
# @export
mg_string_species <- function(version = "12.0",
                              cache = TRUE) {
    version <- as.character(version)
    if (!grepl("^[0-9]+(\\.[0-9]+)?$", version)) {
        stop("version must match '^[0-9]+(\\.[0-9]+)?$', got: ", version,
             call. = FALSE)
    }
    url <- paste0(
        "https://stringdb-downloads.org/download/species.v",
        version, ".txt"
    )
    destdir <- file.path(yulab.utils::user_dir("mechgraph"), "string")
    if (!dir.exists(destdir)) {
        dir.create(destdir, recursive = TRUE, showWarnings = FALSE)
    }
    destfile <- file.path(destdir, basename(url))
    if (!cache || !file.exists(destfile)) {
        .mg_download(url, destfile)
        if (!file.exists(destfile) || file.info(destfile)$size == 0) {
            unlink(destfile)
            stop("Failed to download STRING species table: ", url,
                 call. = FALSE)
        }
    }
    utils::read.table(
        destfile,
        sep = "\t",
        header = TRUE,
        quote = "",
        comment.char = "",
        check.names = FALSE,
        stringsAsFactors = FALSE
    )
}

## ---------------------------------------------------------------------------
## Parsing
## ---------------------------------------------------------------------------

read_string_table <- function(x, sep = "") {
    if (is.data.frame(x)) {
        return(x)
    }
    if (!file.exists(x)) {
        stop("File does not exist: ", x, call. = FALSE)
    }
    con <- gzfile(x, open = "rt")
    on.exit(close(con))
    utils::read.table(
        con,
        sep = sep,
        header = TRUE,
        quote = "",
        comment.char = "",
        check.names = FALSE,
        stringsAsFactors = FALSE
    )
}

## alias source used for each supported keytype; NULL means identity mapping
##
## NOTE: the Ensembl_HGNC_* alias sources exist in the human
## (9606) protein.aliases table. For other species the STRING alias
## source names differ, so mapped keytypes (entrez/symbol/uniprot/
## ensembl_gene) currently assume human; use keytype =
## "ensembl_protein" or "string_id" (identity mappings) for other
## species until per-species alias sources are added.
string_alias_source <- function(keytype) {
    switch(
        keytype,
        entrez          = "Ensembl_HGNC_entrez_id",
        symbol          = "Ensembl_HGNC_symbol",
        uniprot         = "Ensembl_HGNC_uniprot_ids",
        ensembl_gene    = "Ensembl_HGNC_ensembl_gene_id",
        ensembl_protein = NULL,
        string_id       = NULL
    )
}

## one identifier per STRING protein, first alias wins
string_id_map <- function(aliases, keytype) {
    source <- string_alias_source(keytype)
    if (is.null(source)) {
        return(NULL)
    }
    if (!all(c("#string_protein_id", "alias", "source") %in% names(aliases))) {
        stop(
            "STRING aliases table must have columns ",
            "'#string_protein_id', 'alias', 'source'.",
            call. = FALSE
        )
    }
    hit <- aliases[[3]] == source
    if (!any(hit)) {
        stop("No '", source, "' aliases found in the STRING aliases table.",
             call. = FALSE)
    }
    sub <- aliases[hit, , drop = FALSE]
    sub <- sub[!duplicated(sub[[1]]), , drop = FALSE]
    stats::setNames(as.character(sub[[2]]), as.character(sub[[1]]))
}

## map STRING protein ids (e.g. "9606.ENSP...") to node ids for keytype
string_map_ids <- function(p, id_map, keytype) {
    if (identical(keytype, "string_id")) {
        return(as.character(p))
    }
    if (identical(keytype, "ensembl_protein")) {
        return(sub("^[0-9]+\\.", "", as.character(p)))
    }
    out <- unname(id_map[as.character(p)])
    out[is.na(out)] <- NA_character_
    out
}

# Parse STRING tables into a mechgraph node/edge pair
#
# Reads STRING `protein.links` (plus optional `protein.aliases` and
# `protein.info`) tables and returns a list with `nodes` and `edges`,
# suitable for [mg_from_edges()]. STRING protein ids are mapped to the
# requested identifier type; edges below `score_threshold` are dropped;
# self-loops (which can appear after identifier collapse) and duplicate
# undirected edges (highest score kept) are removed.
#
# @param links Path or data.frame of the `protein.links` table (columns
#   `protein1`, `protein2`, `combined_score`).
# @param aliases Path or data.frame of the `protein.aliases` table
#   (columns `#string_protein_id`, `alias`, `source`). Required unless
#   `keytype` is "ensembl_protein" or "string_id".
# @param info Path or data.frame of the `protein.info` table (columns
#   `#string_protein_id`, `preferred_name`, ...). Used for node labels
#   when `labels = TRUE`.
# @param taxon_id NCBI taxonomy id, recorded in the node table.
# @param version STRING release version, recorded for provenance.
# @param score_threshold minimum combined_score (0-1000) to keep an edge;
#   `NULL` keeps all edges.
# @param keytype Node identifier type: "entrez" (default), "symbol",
#   "uniprot", "ensembl_gene", "ensembl_protein" (Ensembl protein id
#   without the species prefix) or "string_id" (full STRING id).
# @param labels logical, use STRING preferred names as node labels when
#   `info` is available; otherwise labels equal node ids.
# @return A list with `nodes` and `edges` data.frames.
# @export
mg_string_parse <- function(links,
                            aliases = NULL,
                            info = NULL,
                            taxon_id = 9606,
                            version = "12.0",
                            score_threshold = 400,
                            keytype = c("entrez", "symbol", "uniprot",
                                        "ensembl_gene", "ensembl_protein",
                                        "string_id"),
                            labels = TRUE) {
    keytype <- match.arg(keytype)
    links <- read_string_table(links, sep = "")
    if (!all(c("protein1", "protein2", "combined_score") %in% names(links))) {
        stop("STRING links table must have columns 'protein1', 'protein2', 'combined_score'.",
             call. = FALSE)
    }

    if (!is.null(score_threshold)) {
        links <- links[links$combined_score >= score_threshold, , drop = FALSE]
    }
    if (nrow(links) == 0) {
        stop("No STRING edges pass score_threshold = ", score_threshold, ".",
             call. = FALSE)
    }

    p1 <- as.character(links$protein1)
    p2 <- as.character(links$protein2)
    score <- as.numeric(links$combined_score)

    id_map <- NULL
    if (keytype %in% c("entrez", "symbol", "uniprot", "ensembl_gene")) {
        if (is.null(aliases)) {
            stop("aliases table is required for keytype = '", keytype, "'.",
                 call. = FALSE)
        }
        aliases <- read_string_table(aliases, sep = "\t")
        id_map <- string_id_map(aliases, keytype)
    }

    e1 <- string_map_ids(p1, id_map, keytype)
    e2 <- string_map_ids(p2, id_map, keytype)

    keep <- !is.na(e1) & !is.na(e2) & nzchar(e1) & nzchar(e2)
    dropped <- sum(!keep)
    if (dropped > 0) {
        message("mg_string_parse: dropped ", dropped, " edges (",
                round(100 * dropped / length(e1), 1),
                "%) with unmapped STRING proteins.")
    }
    e1 <- e1[keep]
    e2 <- e2[keep]
    score <- score[keep]

    ## self-loops can appear after identifier collapse (isoforms map to one gene)
    nz <- e1 != e2
    e1 <- e1[nz]
    e2 <- e2[nz]
    score <- score[nz]

    ## undirected dedup, keep the highest score
    key <- paste(pmin(e1, e2), pmax(e1, e2), sep = "\r")
    ord <- order(-score)
    keep2 <- !duplicated(key[ord])
    ord <- ord[keep2]
    e1 <- e1[ord]
    e2 <- e2[ord]
    score <- score[ord]

    ## node labels: preferred_name from protein.info when requested
    preferred <- NULL
    if (labels && !is.null(info)) {
        info <- read_string_table(info, sep = "\t")
        if (ncol(info) >= 2) {
            preferred <- stats::setNames(
                as.character(info[[2]]),
                as.character(info[[1]])
            )
        }
    }

    nodes <- string_node_table(e1, e2, p1[keep][nz][ord], p2[keep][nz][ord],
                               id_map, preferred, keytype, taxon_id)

    edges <- data.frame(
        from = e1,
        to = e2,
        type = "ppi",
        score = score,
        source = "STRING",
        stringsAsFactors = FALSE
    )

    list(nodes = nodes, edges = edges)
}

## build the node table; string_ids are the original ids of the kept edges
string_node_table <- function(e1, e2, s1, s2, id_map, preferred, keytype, taxon_id) {
    id <- unique(c(e1, e2))
    label <- id

    if (!is.null(preferred) && !is.null(id_map)) {
        ## node id -> first STRING protein -> preferred name
        node2string <- stats::setNames(
            names(id_map)[match(id, unname(id_map))],
            id
        )
        lbl <- preferred[node2string]
        lbl[is.na(lbl)] <- id[is.na(lbl)]
        label <- unname(lbl)
    } else if (!is.null(preferred) && is.null(id_map)) {
        ## identity keytypes: index preferred (keyed by the full STRING id)
        ## by name; node ids keep the species prefix only for "string_id",
        ## while "ensembl_protein" ids are prefix-stripped
        key_id <- if (identical(keytype, "ensembl_protein")) {
            paste0(taxon_id, ".", id)
        } else {
            id
        }
        lbl <- preferred[key_id]
        lbl[is.na(lbl)] <- id[is.na(lbl)]
        label <- unname(lbl)
    }

    data.frame(
        id = id,
        type = "protein",
        label = as.character(label),
        taxon_id = as.character(taxon_id),
        stringsAsFactors = FALSE
    )
}

## ---------------------------------------------------------------------------
## End-to-end builder
## ---------------------------------------------------------------------------

# Build a mechgraph from STRING
#
# Downloads the STRING functional or physical association network for a
# species and returns it as a [mg_graph()] with `type = "ppi"` edges
# carrying the STRING combined score, and provenance metadata (source,
# version, taxon_id, score threshold, keytype, URL, license).
#
# STRING protein ids are mapped to the requested identifier type through
# the STRING `protein.aliases` table (e.g. `Ensembl_HGNC_entrez_id` for
# `keytype = "entrez"`, which covers ~98% of human STRING proteins).
#
# @param file Optional local path to a STRING links table; when `NULL`
#   the table is downloaded (and cached).
# @param taxon_id NCBI taxonomy id (e.g. 9606 for human).
# @param version STRING release version (e.g. "12.0").
# @param network Which STRING network: "functional" (protein.links,
#   default) or "physical" (protein.physical.links).
# @param score_threshold minimum combined_score (0-1000) to keep an edge;
#   `NULL` keeps all edges.
# @param keytype Node identifier type (see [mg_string_parse()]).
# @param labels logical, use STRING preferred names as node labels
#   (requires downloading the `protein.info` table).
# @param cache logical, reuse cached downloads.
# @return A `mechgraph` object.
# @export
mg_from_string <- function(file = NULL,
                           taxon_id = 9606,
                           version = "12.0",
                           network = c("functional", "physical"),
                           score_threshold = 400,
                           keytype = c("entrez", "symbol", "uniprot",
                                       "ensembl_gene", "ensembl_protein",
                                       "string_id"),
                           labels = TRUE,
                           cache = TRUE) {
    keytype <- match.arg(keytype)
    network <- match.arg(network)

    links_file <- if (is.null(file)) {
        mg_string_download(taxon_id = taxon_id, version = version,
                           network = network, cache = cache)
    } else {
        file
    }
    aliases_file <- if (keytype %in% c("entrez", "symbol", "uniprot", "ensembl_gene")) {
        mg_string_download(taxon_id = taxon_id, version = version,
                           network = "aliases", cache = cache)
    } else {
        NULL
    }
    info_file <- if (labels) {
        mg_string_download(taxon_id = taxon_id, version = version,
                           network = "info", cache = cache)
    } else {
        NULL
    }

    parsed <- mg_string_parse(
        links = links_file,
        aliases = aliases_file,
        info = info_file,
        taxon_id = taxon_id,
        version = version,
        score_threshold = score_threshold,
        keytype = keytype,
        labels = labels
    )

    metadata <- list(
        source = "STRING",
        source_version = version,
        taxon_id = taxon_id,
        network = network,
        score_threshold = score_threshold,
        keytype = keytype,
        labels = labels,
        url = mg_string_file_url(taxon_id = taxon_id, version = version,
                                 network = network),
        retrieved_at = as.character(Sys.time()),
        license = "CC BY 4.0"
    )

    mg_from_edges(parsed$edges, nodes = parsed$nodes, metadata = metadata)
}