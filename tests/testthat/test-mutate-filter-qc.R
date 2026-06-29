test_graph <- function() {
    nodes <- data.frame(
        id = c("A", "B", "C"),
        type = c("protein", "protein", "term"),
        label = c("A", "B", "C"),
        stringsAsFactors = FALSE
    )
    edges <- data.frame(
        from = c("A", "B"),
        to = c("B", "C"),
        type = c("physical_interaction", "term_gene"),
        source = c("BioGRID", "user"),
        weight = c(0.9, 0.2),
        stringsAsFactors = FALSE
    )
    mg_graph(nodes, edges)
}

test_that("mg_add_nodes and mg_add_edges extend a graph", {
    x <- test_graph()
    x <- mg_add_nodes(x, data.frame(id = "D", type = "protein", label = "D"))
    x <- mg_add_edges(x, data.frame(from = "C", to = "D", type = "association"))

    expect_equal(nrow(mg_nodes(x)), 4)
    expect_equal(nrow(mg_edges(x)), 3)
})

test_that("mg_add_edges can add missing endpoint nodes explicitly", {
    x <- test_graph()
    x <- mg_add_edges(
        x,
        data.frame(from = "A", to = "D", type = "physical_interaction"),
        add_missing_nodes = TRUE
    )

    expect_true("D" %in% mg_nodes(x)$id)
    expect_equal(mg_nodes(x)$type[mg_nodes(x)$id == "D"], "unknown")
})

test_that("mg_drop_nodes removes incident edges", {
    x <- mg_drop_nodes(test_graph(), "B")

    expect_equal(mg_nodes(x)$id, c("A", "C"))
    expect_equal(nrow(mg_edges(x)), 0)
})

test_that("mg_filter_edges filters by source and numeric columns", {
    x <- test_graph()

    expect_equal(nrow(mg_filter_edges(x, source = "BioGRID")$edges), 1)
    expect_equal(nrow(mg_filter_edges(x, weight = 0.5)$edges), 1)
})

test_that("mg_induced_subgraph keeps only internal edges", {
    x <- mg_induced_subgraph(test_graph(), c("A", "B"))

    expect_equal(sort(mg_nodes(x)$id), c("A", "B"))
    expect_equal(nrow(mg_edges(x)), 1)
})

test_that("mg_bind preserves duplicate evidence edges", {
    x <- test_graph()
    y <- test_graph()
    z <- mg_bind(x, y)

    expect_equal(nrow(mg_nodes(z)), 3)
    expect_equal(nrow(mg_edges(z)), 4)
})

test_that("mg_combine can merge duplicate edges when requested", {
    x <- test_graph()
    z <- mg_combine(x, x, merge_edges = TRUE)

    expect_equal(nrow(mg_edges(z)), 2)
})

test_that("mg_qc returns stable summary fields", {
    qc <- mg_qc(test_graph())

    expect_equal(qc$n_nodes, 3)
    expect_equal(qc$n_edges, 2)
    expect_equal(qc$n_isolated_nodes, 0)
    expect_true("BioGRID" %in% names(qc$edge_source_distribution))
})

test_that("BioGRID MITAB parser supports taxon filtering", {
    fixture <- tempfile(fileext = ".mitab.txt")
    writeLines(
        c(
            paste(
                "biogrid:1", "biogrid:2", "-", "-", "symbol:TP53", "symbol:MDM2",
                "psi-mi:\"MI:0018\"(two hybrid)", "-", "pubmed:12345",
                "taxid:9606(human)", "taxid:9606(human)",
                sep = "\t"
            ),
            paste(
                "biogrid:1", "biogrid:3", "-", "-", "symbol:TP53", "symbol:Trp53",
                "psi-mi:\"MI:0004\"(affinity chromatography technology)", "-", "pubmed:23456",
                "taxid:9606(human)", "taxid:10090(mouse)",
                sep = "\t"
            )
        ),
        fixture
    )

    parsed <- mg_biogrid_parse(fixture, format = "mitab", taxon_id = 9606)

    expect_equal(nrow(parsed$edges), 1)
    expect_equal(sort(parsed$nodes$label), c("MDM2", "TP53"))
})
