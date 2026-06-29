\name{mg_filter_nodes}
\alias{mg_filter_nodes}
\alias{mg_filter_edges}
\alias{mg_induced_subgraph}
\title{Filter mechgraph objects}
\usage{
mg_filter_nodes(x, type = NULL, ids = NULL, source = NULL)

mg_filter_edges(x, type = NULL, source = NULL, score = NULL, weight = NULL)

mg_induced_subgraph(x, nodes)
}
\arguments{
\item{x}{A mechgraph object.}
\item{type}{Optional node or edge type filter.}
\item{ids}{Optional node identifier filter.}
\item{source}{Optional source filter.}
\item{score}{Optional score threshold or range.}
\item{weight}{Optional weight threshold or range.}
\item{nodes}{Node identifiers or a node table defining the induced subgraph.}
}
\description{
Filter node and edge tables and return a new mechgraph object.
}
