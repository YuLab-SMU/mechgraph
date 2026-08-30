\name{mg_bind}
\alias{mg_bind}
\alias{mg_combine}
\title{Combine mechgraph objects}
\usage{
mg_bind(...)

mg_combine(..., merge_nodes = TRUE, merge_edges = FALSE)
}
\arguments{
\item{...}{Mechgraph objects, or a list of mechgraph objects.}
\item{merge_nodes}{Reserved for API compatibility. Nodes are currently merged by identifier.}
\item{merge_edges}{Whether to drop duplicate edges with the same \code{from}, \code{to}, and \code{type}.}
}
\description{
Combine graphs while preserving duplicate evidence records by default.
}
\value{
A new \code{mechgraph} object. \code{mg_bind()} row-binds the edge tables of
the input graphs (duplicate evidence records are preserved), merges the node
tables by identifier (duplicated node ids are dropped), and records the input
metadata in a list under \code{metadata$inputs}. \code{mg_combine()} additionally
removes duplicate edges sharing the same \code{from}, \code{to}, and \code{type}
when \code{merge_edges = TRUE}.
}
