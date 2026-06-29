\name{mg_graph}
\alias{mg_graph}
\alias{mg_empty}
\alias{is_mechgraph}
\title{Create and inspect mechgraph objects}
\usage{
mg_graph(nodes, edges, metadata = list(), validate = TRUE)

mg_empty(metadata = list())

is_mechgraph(x)
}
\arguments{
\item{nodes}{A base data frame with required columns \code{id}, \code{type}, and \code{label}.}
\item{edges}{A base data frame with required columns \code{from}, \code{to}, and \code{type}.}
\item{metadata}{A named list of graph metadata.}
\item{validate}{Whether to validate the object before returning it.}
\item{x}{An object to test.}
}
\description{
Create the lightweight S3 list object used by mechgraph.
}
