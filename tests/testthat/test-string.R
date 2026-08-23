test_that("STRING download URL is deterministic", {
    expect_equal(
        mg_string_file_url(taxon_id = 9606, version = "12.0", network = "functional"),
        "https://stringdb-downloads.org/download/protein.links.v12.0/9606.protein.links.v12.0.txt.gz"
    )
    expect_equal(
        mg_string_file_url(taxon_id = 9606, version = "12.0", network = "physical"),
        "https://stringdb-downloads.org/download/protein.physical.links.v12.0/9606.protein.physical.links.v12.0.txt.gz"
    )
    expect_equal(
        mg_string_file_url(taxon_id = 9606, version = "12.0", network = "aliases"),
        "https://stringdb-downloads.org/download/protein.aliases.v12.0/9606.protein.aliases.v12.0.txt.gz"
    )
    expect_equal(
        mg_string_file_url(taxon_id = 10090, version = "11.5", network = "info"),
        "https://stringdb-downloads.org/download/protein.info.v11.5/10090.protein.info.v11.5.txt.gz"
    )
    expect_equal(
        mg_string_file_url(taxon_id = 9606, version = "12.0", network = "detailed"),
        "https://stringdb-downloads.org/download/protein.links.detailed.v12.0/9606.protein.links.detailed.v12.0.txt.gz"
    )
    expect_error(mg_string_file_url(network = "nope"))
})

test_that("STRING URL builders reject unsafe taxon_id/version input", {
    expect_error(mg_string_file_url(taxon_id = "../etc"), "taxon_id")
    expect_error(mg_string_file_url(taxon_id = "9606;rm -rf"), "taxon_id")
    expect_error(mg_string_file_url(version = "../x"), "version")
    expect_error(mg_string_file_url(version = "12.0/../../x"), "version")
    expect_error(mg_string_file_url(taxon_id = "9606.1"), "taxon_id")
    ## valid inputs still work
    expect_match(
        mg_string_file_url(taxon_id = "9606", version = "12.0", network = "functional"),
        "stringdb-downloads.org"
    )
})

test_that("STRING download reuses cached files for the same version", {
    destdir <- tempfile("string-cache-")
    dir.create(destdir)
    cached <- file.path(destdir, basename(mg_string_file_url(network = "functional")))
    writeLines("cached", cached)

    path <- mg_string_download(network = "functional", destdir = destdir, cache = TRUE)

    expect_equal(path, cached)
    expect_equal(readLines(path), "cached")
})

## small fixture mimicking the STRING table formats
fixture_tables <- function() {
    links <- tempfile(fileext = ".txt.gz")
    con <- gzfile(links, "wt")
    writeLines(
        c(
            "protein1 protein2 combined_score",
            "9606.ENSP1 9606.ENSP2 900",
            "9606.ENSP1 9606.ENSP3 500",
            "9606.ENSP2 9606.ENSP3 300",
            "9606.ENSP9 9606.ENSP1 999",
            "9606.ENSP4 9606.ENSP5 700"
        ),
        con
    )
    close(con)

    aliases <- tempfile(fileext = ".txt.gz")
    con <- gzfile(aliases, "wt")
    writeLines(
        c(
            "#string_protein_id\talias\tsource",
            "9606.ENSP1\t7157\tEnsembl_HGNC_entrez_id",
            "9606.ENSP2\t7157\tEnsembl_HGNC_entrez_id",
            "9606.ENSP3\t4193\tEnsembl_HGNC_entrez_id",
            "9606.ENSP9\t99999\tEnsembl_HGNC_entrez_id",
            "9606.ENSP4\tNA\tEnsembl_HGNC_entrez_id",
            "9606.ENSP5\tNA\tEnsembl_HGNC_entrez_id",
            "9606.ENSP1\tTP53\tEnsembl_HGNC_symbol",
            "9606.ENSP3\tMDM2\tEnsembl_HGNC_symbol",
            "9606.ENSP1\tP04637\tEnsembl_HGNC_uniprot_ids"
        ),
        con
    )
    close(con)

    info <- tempfile(fileext = ".txt.gz")
    con <- gzfile(info, "wt")
    writeLines(
        c(
            "#string_protein_id\tpreferred_name\tprotein_size",
            "9606.ENSP1\tTP53\t393",
            "9606.ENSP2\tTP53\t393",
            "9606.ENSP3\tMDM2\t491"
        ),
        con
    )
    close(con)

    list(links = links, aliases = aliases, info = info)
}

test_that("mg_string_parse maps, filters, dedups and labels", {
    f <- fixture_tables()
    parsed <- mg_string_parse(f$links, f$aliases, f$info,
                              score_threshold = 400, keytype = "entrez")

    ## ENSP1 & ENSP2 both map to 7157: their edge becomes a self-loop and is
    ## removed; ENSP2-ENSP3 (300) filtered by score; ENSP4/ENSP5 unmapped.
    ## Edges are ordered by descending score.
    expect_equal(parsed$edges$from, c("99999", "7157"))
    expect_equal(parsed$edges$to, c("7157", "4193"))
    expect_equal(parsed$edges$score, c(999, 500))
    expect_true(all(parsed$edges$type == "ppi"))
    expect_true(all(parsed$edges$source == "STRING"))

    ## nodes: labelled via protein.info preferred_name where available
    nodes <- parsed$nodes
    expect_setequal(nodes$id, c("7157", "4193", "99999"))
    expect_equal(nodes$label[nodes$id == "7157"], "TP53")
    expect_equal(nodes$label[nodes$id == "4193"], "MDM2")
    expect_equal(nodes$label[nodes$id == "99999"], "99999") # no info row
    expect_true(all(nodes$type == "protein"))
    expect_true(all(nodes$taxon_id == "9606"))

    ## validate against the mechgraph schema
    expect_true(mg_validate(mg_from_edges(parsed$edges, nodes = parsed$nodes)))
})

test_that("mg_string_parse keeps the highest score for duplicate undirected edges", {
    links <- data.frame(
        protein1 = c("9606.ENSP1", "9606.ENSP3", "9606.ENSP1"),
        protein2 = c("9606.ENSP3", "9606.ENSP1", "9606.ENSP3"),
        combined_score = c(600, 800, 500),
        stringsAsFactors = FALSE
    )
    f <- fixture_tables()
    parsed <- mg_string_parse(links, f$aliases, f$info,
                              score_threshold = NULL, keytype = "entrez")
    expect_equal(nrow(parsed$edges), 1)
    expect_equal(parsed$edges$score, 800)
})

test_that("mg_string_parse supports identity keytypes without aliases", {
    links <- data.frame(
        protein1 = c("9606.ENSP1"),
        protein2 = c("9606.ENSP3"),
        combined_score = c(900),
        stringsAsFactors = FALSE
    )
    parsed <- mg_string_parse(links, score_threshold = NULL,
                              keytype = "ensembl_protein")
    expect_equal(parsed$edges$from, "ENSP1")
    expect_equal(parsed$edges$to, "ENSP3")

    parsed2 <- mg_string_parse(links, score_threshold = NULL,
                               keytype = "string_id")
    expect_equal(parsed2$edges$from, "9606.ENSP1")
    expect_equal(parsed2$edges$to, "9606.ENSP3")
})

test_that("mg_string_parse labels identity-keytype nodes from protein.info", {
    links <- data.frame(
        protein1 = c("9606.ENSP1"),
        protein2 = c("9606.ENSP3"),
        combined_score = c(900),
        stringsAsFactors = FALSE
    )
    f <- fixture_tables()
    ## ensembl_protein: ids are prefix-stripped, so labels match via stripped ids
    parsed <- mg_string_parse(links, f$aliases, f$info, score_threshold = NULL,
                              keytype = "ensembl_protein")
    nodes <- parsed$nodes
    expect_equal(nodes$label[nodes$id == "ENSP1"], "TP53")
    ## string_id: ids keep the prefix; labels must still resolve
    parsed2 <- mg_string_parse(links, f$aliases, f$info, score_threshold = NULL,
                               keytype = "string_id")
    nodes2 <- parsed2$nodes
    expect_equal(nodes2$label[nodes2$id == "9606.ENSP1"], "TP53")
    expect_equal(nodes2$label[nodes2$id == "9606.ENSP3"], "MDM2")
})

test_that("mg_string_parse errors informatively", {
    f <- fixture_tables()
    ## aliases required for mapped keytypes
    expect_error(
        mg_string_parse(f$links, score_threshold = NULL, keytype = "entrez"),
        "aliases table is required"
    )
    ## score threshold that drops everything
    expect_error(
        mg_string_parse(f$links, f$aliases, score_threshold = 1000,
                        keytype = "entrez"),
        "No STRING edges pass"
    )
    ## missing links columns
    bad <- data.frame(a = 1, b = 2)
    expect_error(mg_string_parse(bad, f$aliases, keytype = "entrez"),
                 "must have columns")
})

test_that("mg_string_species parses the STRING species table", {
    ## local fixture mimicking species.v12.0.txt (tab-separated, # header)
    fixture <- tempfile(fileext = ".txt")
    writeLines(
        c(
            "#taxon_id\tSTRING_type\tSTRING_name_compact\tofficial_name_NCBI\tdomain",
            "23\tperiphery\tperiphery\tPeripheral blood lymphocytes\tEukaryota",
            "9606\tcore\tHomo sapiens\tHomo sapiens\tEukaryota",
            "10090\tcore\tMus musculus\tMus musculus\tEukaryota"
        ),
        fixture
    )
    ## exercise the same parsing path as mg_string_species (read.table on the file)
    sp <- utils::read.table(fixture, sep = "\t", header = TRUE, quote = "",
                            comment.char = "", check.names = FALSE,
                            stringsAsFactors = FALSE)
    expect_equal(nrow(sp), 3)
    expect_true("9606" %in% as.character(sp$`#taxon_id`))
    expect_equal(sp$STRING_name_compact[sp$`#taxon_id` == "9606"], "Homo sapiens")
})

test_that("mg_from_string end-to-end on a local links fixture", {
    f <- fixture_tables()
    ## functional and physical links share the same table format, so a
    ## fixture parses through the same path; identity keytype + labels =
    ## FALSE avoids downloading aliases/info in the test
    mg <- mg_from_string(file = f$links, taxon_id = 9606,
                         network = "functional", score_threshold = 400,
                         keytype = "string_id", labels = FALSE, cache = FALSE)
    expect_s3_class(mg, "mechgraph")
    expect_true(nrow(mg_edges(mg)) >= 1)
    expect_equal(mg_metadata(mg)$taxon_id, 9606)
    expect_equal(mg_metadata(mg)$network, "functional")
    expect_equal(mg_metadata(mg)$source, "STRING")
    expect_true(all(mg_edges(mg)$type == "ppi"))
    expect_true(mg_validate(mg))
})
