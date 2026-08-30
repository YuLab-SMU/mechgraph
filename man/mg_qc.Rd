\name{mg_qc}
\alias{mg_qc}
\title{Summarize mechgraph quality-control metrics}
\usage{
mg_qc(x)
}
\arguments{
\item{x}{A mechgraph object.}
}
\description{
Return lightweight graph summary metrics including node and edge counts, isolated node count, and type/source distributions.
}
\value{
A named \code{list} with components:
\itemize{
  \item \code{n_nodes}: total number of nodes.
  \item \code{n_edges}: total number of edges.
  \item \code{n_isolated_nodes}: number of nodes that are not an endpoint of
    any edge.
  \item \code{node_type_distribution}: a \code{table} of node types.
  \item \code{edge_type_distribution}: a \code{table} of edge types.
  \item \code{edge_source_distribution}: a \code{table} of edge source labels
    (empty \code{table} when the edge table has no \code{source} column).
}
}
