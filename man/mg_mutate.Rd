\name{mg_add_nodes}
\alias{mg_add_nodes}
\alias{mg_add_edges}
\alias{mg_drop_nodes}
\alias{mg_drop_edges}
\title{Modify mechgraph nodes and edges}
\usage{
mg_add_nodes(x, nodes)

mg_add_edges(x, edges, add_missing_nodes = FALSE)

mg_drop_nodes(x, nodes)

mg_drop_edges(x, edges)
}
\arguments{
\item{x}{A mechgraph object.}
\item{nodes}{A node table, node identifiers, or rows to remove depending on the function.}
\item{edges}{An edge table, numeric row indices, or logical row mask.}
\item{add_missing_nodes}{Whether to create unknown nodes for edge endpoints missing from \code{x}.}
}
\description{
Add or remove nodes and edges while preserving the mechgraph table schema.
}
\value{
A new \code{mechgraph} object with the modified node and/or edge tables; the
input graph is left unchanged. \code{mg_add_nodes()} and \code{mg_add_edges()}
row-bind the new records onto the existing tables (with
\code{add_missing_nodes = TRUE}, \code{mg_add_edges()} creates
\code{type = "unknown"} nodes for endpoints absent from the graph).
\code{mg_drop_nodes()} removes the given nodes and every edge incident to
them; \code{mg_drop_edges()} removes the given edges (a data frame of
\code{from}/\code{to}/\code{type} rows, numeric row indices, or a logical
mask) while keeping all nodes.
}
