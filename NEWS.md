# mechgraph 0.0.1

Initial release of the mechanism evidence graph data model. Built
demand-driven: the first real consumer is the NSEA workflow
(`clusterProfiler::nseGO()` / `ReactomePA::nsePathway()`), which now
accepts a `mechgraph` network through `enrichit::prepare_network()`.

## Core container

+ `mg_graph()`, `mg_empty()`, `mg_validate()`, `is_mechgraph()`:
  construct and validate a `mechgraph` object (nodes/edges/metadata
  base `data.frame` tables).
+ Accessors `mg_nodes()`, `mg_edges()`, `mg_metadata()`, `mg_sources()`.
+ Mutators `mg_add_nodes()`, `mg_add_edges()`, `mg_drop_nodes()`,
  `mg_drop_edges()`, `mg_bind()`, `mg_combine()`.
+ Filters `mg_filter_nodes()`, `mg_filter_edges()`,
  `mg_induced_subgraph()`.
+ Builder `mg_from_edges()`, coercion `as_mechgraph()`.
+ QC summary `mg_qc()`.

## STRING backend

+ `mg_from_string()`: download and map a STRING functional or physical
  network (protein.links / protein.physical.links) into a `mechgraph`
  with `type = "ppi"` edges carrying the STRING combined score and full
  provenance metadata.
+ Identifier mapping through the STRING `protein.aliases` table:
  `keytype = "entrez"` (default), `"symbol"`, `"uniprot"`,
  `"ensembl_gene"`, `"ensembl_protein"`, `"string_id"`.
+ `mg_string_versions()`, `mg_string_file_url()`,
  `mg_string_download()` (cached), `mg_string_parse()`,
  `mg_string_species()`.

## BioGRID backend

+ `mg_from_biogrid()`: download and parse BioGRID multi-validated
  physical interactions (TAB3/MITAB) into a `mechgraph` with
  `type = "ppi"` edges.
+ `mg_biogrid_versions()`, `mg_biogrid_file_url()`,
  `mg_biogrid_download()` (cached), `mg_biogrid_parse()`.
