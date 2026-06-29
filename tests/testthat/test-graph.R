test_that("mg_graph creates and validates a mechgraph object", {
    nodes <- data.frame(
        id = c("A", "B"),
        type = c("protein", "protein"),
        label = c("A", "B")
    )
    edges <- data.frame(
        from = "A",
        to = "B",
        type = "physical_interaction"
    )

    x <- mg_graph(nodes, edges)

    expect_s3_class(x, "mechgraph")
    expect_true(is_mechgraph(x))
    expect_equal(nrow(mg_nodes(x)), 2)
    expect_equal(nrow(mg_edges(x)), 1)
})

test_that("mg_validate rejects missing endpoints", {
    nodes <- data.frame(id = "A", type = "protein", label = "A")
    edges <- data.frame(from = "A", to = "B", type = "physical_interaction")

    expect_error(mg_graph(nodes, edges), "Missing: B")
})

test_that("mg_from_edges infers nodes", {
    edges <- data.frame(from = "A", to = "B", type = "ppi")

    x <- mg_from_edges(edges)

    expect_equal(sort(mg_nodes(x)$id), c("A", "B"))
    expect_equal(mg_nodes(x)$type, c("unknown", "unknown"))
})
