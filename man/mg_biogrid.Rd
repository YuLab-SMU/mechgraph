\name{mg_from_biogrid}
\alias{mg_from_biogrid}
\alias{mg_biogrid_versions}
\alias{mg_biogrid_file_url}
\alias{mg_biogrid_download}
\alias{mg_biogrid_parse}
\title{Build a mechgraph from BioGRID}
\usage{
mg_biogrid_versions()

mg_biogrid_file_url(version = "latest", dataset = c("mv_physical", "all"),
  format = c("tab3", "mitab"))

mg_biogrid_download(version = "latest", dataset = c("mv_physical", "all"),
  format = c("tab3", "mitab"), cache = TRUE, destdir = NULL, quiet = TRUE)

mg_biogrid_parse(file, format = c("tab3", "mitab"), taxon_id = NULL)

mg_from_biogrid(file = NULL, version = "latest", dataset = "mv_physical",
  format = c("tab3", "mitab"), taxon_id = NULL, cache = TRUE)
}
\arguments{
\item{version}{BioGRID version string, or \code{"latest"}.}
\item{dataset}{BioGRID dataset. The MVP supports \code{"mv_physical"} and \code{"all"}.}
\item{format}{Download or parse format. The MVP supports \code{"tab3"} and \code{"mitab"}.}
\item{cache}{Whether to reuse an existing cached download.}
\item{destdir}{Optional cache directory. Defaults to a BioGRID directory under \code{yulab.utils::user_dir("mechgraph")}.}
\item{quiet}{Reserved for API compatibility. Downloads are handled by \code{yulab.utils:::mydownload()}.}
\item{file}{A local BioGRID table or zip file. If missing, \code{mg_from_biogrid()} downloads BioGRID first.}
\item{taxon_id}{Optional NCBI taxonomy identifier used to filter both interactors.}
}
\description{
Download, parse, and convert BioGRID physical interaction tables into a mechgraph object.
}
