test_that("BioGRID latest MV physical URL is deterministic", {
    url <- mg_biogrid_file_url(dataset = "mv_physical", format = "tab3")

    expect_equal(
        url,
        "https://downloads.thebiogrid.org/Download/BioGRID/Latest-Release/BIOGRID-MV-Physical-LATEST.tab3.zip"
    )
})

test_that("BioGRID download reuses cached files for the same version", {
    destdir <- tempfile("biogrid-cache-")
    dir.create(destdir)
    cached <- file.path(destdir, basename(mg_biogrid_file_url()))
    writeLines("cached", cached)

    path <- mg_biogrid_download(destdir = destdir, cache = TRUE)

    expect_equal(path, cached)
    expect_equal(readLines(path), "cached")
})

test_that("BioGRID TAB3 parser returns a mechgraph-compatible table pair", {
    fixture <- tempfile(fileext = ".tab3.txt")
    writeLines(
        c(
            paste(
                "BioGRID ID Interactor A",
                "BioGRID ID Interactor B",
                "Official Symbol Interactor A",
                "Official Symbol Interactor B",
                "Experimental System",
                "Experimental System Type",
                "Pubmed ID",
                "Organism ID Interactor A",
                "Organism ID Interactor B",
                sep = "\t"
            ),
            paste(
                "1", "2", "TP53", "MDM2", "Two-hybrid", "physical", "12345", "9606", "9606",
                sep = "\t"
            ),
            paste(
                "1", "3", "TP53", "Trp53", "Affinity Capture-Western", "physical", "23456", "9606", "10090",
                sep = "\t"
            )
        ),
        fixture
    )

    parsed <- mg_biogrid_parse(fixture, format = "tab3", taxon_id = 9606)
    x <- mg_from_edges(parsed$edges, nodes = parsed$nodes)

    expect_equal(nrow(mg_edges(x)), 1)
    expect_equal(sort(mg_nodes(x)$label), c("MDM2", "TP53"))
    expect_equal(mg_edges(x)$source, "BioGRID")
})
