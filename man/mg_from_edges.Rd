\name{mg_from_edges}
\alias{mg_from_edges}
\alias{as_mechgraph}
\title{Build a mechgraph from an edge list}
\usage{
mg_from_edges(edges, nodes = NULL, metadata = list())

as_mechgraph(x, ...)
}
\arguments{
\item{edges}{A data frame with required columns \code{from}, \code{to}, and \code{type}.}
\item{nodes}{Optional node table with required columns \code{id}, \code{type}, and \code{label}.}
\item{metadata}{A named list of graph metadata.}
\item{x}{An object to coerce.}
\item{...}{Additional arguments passed to methods.}
}
\description{
Create a mechgraph from a plain edge list. If \code{nodes} is missing, nodes are inferred from edge endpoints.
}
\value{
\code{mg_from_edges()} returns a \code{mechgraph} object (an S3 list with
components \code{nodes}, \code{edges}, and \code{metadata}). When \code{nodes}
is missing, a node table with \code{type = "unknown"} is inferred from the
unique edge endpoints. \code{as_mechgraph()} returns the coerced object: for a
\code{data.frame} it returns \code{mg_from_edges(x, ...)} and for a
\code{mechgraph} it returns the object unchanged.
}
