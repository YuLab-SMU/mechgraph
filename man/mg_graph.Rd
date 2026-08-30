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
\value{
\code{mg_graph()} returns a \code{mechgraph} object: an S3 list with
components \code{nodes} (a \code{data.frame} with columns \code{id},
\code{type}, \code{label}), \code{edges} (a \code{data.frame} with columns
\code{from}, \code{to}, \code{type}), and \code{metadata} (a named list).
When \code{validate = TRUE} the object is checked with \code{mg_validate()}
before being returned. \code{mg_empty()} returns such an object with empty
node and edge tables. \code{is_mechgraph()} returns \code{TRUE} if \code{x}
inherits from class \code{"mechgraph"} and \code{FALSE} otherwise.
}
