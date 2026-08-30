\name{mg_nodes}
\alias{mg_nodes}
\alias{mg_edges}
\alias{mg_metadata}
\alias{mg_sources}
\title{Access mechgraph tables and metadata}
\usage{
mg_nodes(x)

mg_edges(x)

mg_metadata(x)

mg_sources(x)
}
\arguments{
\item{x}{A mechgraph object.}
}
\description{
Return the node table, edge table, metadata list, or unique source labels from a mechgraph object.
}
\value{
\itemize{
  \item \code{mg_nodes()} returns the node table, a \code{data.frame} with
    the required columns \code{id}, \code{type}, \code{label} plus any
    additional node columns.
  \item \code{mg_edges()} returns the edge table, a \code{data.frame} with
    the required columns \code{from}, \code{to}, \code{type} plus any
    additional edge columns.
  \item \code{mg_metadata()} returns the metadata \code{list} stored in the
    graph.
  \item \code{mg_sources()} returns a sorted character vector of the unique
    non-missing source labels found in the node and edge tables.
}
}
