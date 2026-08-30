\name{mg_validate}
\alias{mg_validate}
\title{Validate a mechgraph object}
\usage{
mg_validate(x)
}
\arguments{
\item{x}{A mechgraph object.}
}
\description{
Checks the required node and edge schema and verifies that edge endpoints are present in \code{nodes$id}.
}
\value{
Invisible \code{TRUE} when \code{x} is a valid \code{mechgraph} object. An
error is raised (with a message describing the problem) when \code{x} is not a
\code{mechgraph}, the node or edge tables are missing required columns, node
ids are missing, empty, or duplicated, or edge endpoints reference nodes that
are not in \code{nodes$id}.
}
