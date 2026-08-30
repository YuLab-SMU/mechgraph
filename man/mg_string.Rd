\name{mg_from_string}
\alias{mg_from_string}
\alias{mg_string_versions}
\alias{mg_string_file_url}
\alias{mg_string_download}
\alias{mg_string_species}
\alias{mg_string_parse}
\title{Build a mechgraph from STRING}
\usage{
mg_string_versions()

mg_string_species(version = "12.0", cache = TRUE)

mg_string_file_url(taxon_id = 9606, version = "12.0",
  network = c("functional", "physical", "detailed", "aliases", "info"))

mg_string_download(taxon_id = 9606, version = "12.0",
  network = c("functional", "physical", "detailed", "aliases", "info"),
  cache = TRUE, destdir = NULL)

mg_string_parse(links, aliases = NULL, info = NULL, taxon_id = 9606,
  version = "12.0", score_threshold = 400,
  keytype = c("entrez", "symbol", "uniprot", "ensembl_gene",
    "ensembl_protein", "string_id"), labels = TRUE)

mg_from_string(file = NULL, taxon_id = 9606, version = "12.0",
  network = c("functional", "physical"), score_threshold = 400,
  keytype = c("entrez", "symbol", "uniprot", "ensembl_gene",
    "ensembl_protein", "string_id"), labels = TRUE, cache = TRUE)
}
\arguments{
\item{taxon_id}{NCBI taxonomy id (e.g. \code{9606} for human).}
\item{version}{STRING release version (e.g. \code{"12.0"}).}
\item{network}{Which STRING table: \code{"functional"} (protein.links), \code{"physical"} (protein.physical.links), \code{"detailed"} (protein.links.detailed), \code{"aliases"} (protein.aliases) or \code{"info"} (protein.info). \code{mg_from_string()} accepts \code{"functional"} (default) and \code{"physical"}.}
\item{cache}{Whether to reuse an existing cached download.}
\item{destdir}{Optional cache directory. Defaults to a session-scoped directory
  under \code{tempdir()}; pass an explicit path for persistent caching.}
\item{links}{A local STRING links table path or data.frame (columns \code{protein1}, \code{protein2}, \code{combined_score}).}
\item{aliases}{A local \code{protein.aliases} table path or data.frame (columns \code{#string_protein_id}, \code{alias}, \code{source}). Required unless \code{keytype} is \code{"ensembl_protein"} or \code{"string_id"}.}
\item{info}{A local \code{protein.info} table path or data.frame. Used for preferred-name node labels when \code{labels = TRUE}.}
\item{score_threshold}{Minimum \code{combined_score} (0-1000) to keep an edge; \code{NULL} keeps all edges.}
\item{keytype}{Node identifier type: \code{"entrez"} (default), \code{"symbol"}, \code{"uniprot"}, \code{"ensembl_gene"}, \code{"ensembl_protein"} (Ensembl protein id without the species prefix) or \code{"string_id"} (full STRING id).}
\item{labels}{Logical, use STRING preferred names as node labels when \code{info} is available; otherwise labels equal node ids.}
\item{file}{A local STRING links table. If missing, \code{mg_from_string()} downloads STRING first.}
}
\description{
Download, parse, and convert STRING functional-association networks into a mechgraph object with \code{type = "ppi"} edges carrying the STRING combined score and provenance metadata (source, version, taxon_id, network, score threshold, keytype, URL, license). \code{mg_string_species()} returns the STRING species list for a release.
}
\details{
STRING protein ids (\code{"9606.ENSP..."}) are mapped to the requested identifier type through the STRING \code{protein.aliases} table. For \code{keytype = "entrez"} the \code{Ensembl_HGNC_entrez_id} aliases cover roughly 98\% of human STRING proteins. Edges below \code{score_threshold} are dropped; self-loops (which can appear after identifier collapse, e.g. isoforms mapping to one gene) and duplicate undirected edges (highest score kept) are removed.

The full human \code{protein.links} table is large (~1.5 GB uncompressed); the download is cached, but parsing it requires roughly that much free memory.

The identifier mapping currently assumes the human (9606) \code{protein.aliases} table: the \code{Ensembl_HGNC_*} alias sources used by \code{"entrez"}, \code{"symbol"}, \code{"uniprot"} and \code{"ensembl_gene"} exist only for human. For other species use \code{keytype = "ensembl_protein"} or \code{"string_id"} (identity mappings) until per-species alias sources are added.
}
\value{
\itemize{
  \item \code{mg_string_versions()} returns a character vector of supported
    STRING release versions (\code{"12.0"}).
  \item \code{mg_string_species()} returns a \code{data.frame} of STRING
    species for the requested release (columns \code{taxon_id},
    \code{STRING_type}, \code{STRING_name_compact}, \code{official_name_NCBI},
    \code{domain}).
  \item \code{mg_string_file_url()} returns the download URL as a character
    string.
  \item \code{mg_string_download()} returns the path to the downloaded (or
    cached) file as a character string.
  \item \code{mg_string_parse()} returns a list with components \code{nodes}
    and \code{edges}, the two \code{data.frame}s to be passed to
    \code{mg_from_edges()}.
  \item \code{mg_from_string()} returns a \code{mechgraph} object with
    \code{type = "ppi"} edges carrying the STRING \code{combined_score} and
    provenance metadata (source, version, taxon_id, network, score
    threshold, keytype, URL, license).
}
}
\examples{
## Build a mechgraph from a small STRING links table (no download)
links <- data.frame(
    protein1 = c("9606.ENSP00000000233", "9606.ENSP00000000412"),
    protein2 = c("9606.ENSP00000000412", "9606.ENSP00000001008"),
    combined_score = c(800, 700),
    stringsAsFactors = FALSE
)
mg <- mg_from_string(file = links, keytype = "string_id", labels = FALSE)
mg
mg_edges(mg)

\dontrun{
## Download and build the human STRING network (large: ~80 MB
## compressed, ~1.5 GB uncompressed) and fetch the species list.
mg <- mg_from_string(taxon_id = 9606, score_threshold = 400,
                     keytype = "entrez")
mg_string_species()
}
}
