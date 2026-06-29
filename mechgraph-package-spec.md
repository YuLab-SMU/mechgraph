# mechgraph package development spec

## 1. Purpose

`mechgraph` is a lightweight low-level R package for representing, combining, querying, and summarizing biological mechanism evidence graphs.

Its role is not to perform enrichment analysis, semantic similarity analysis, WGCNA, or visualization. Its role is to provide a common graph data model and minimal graph operations that higher-level YuLab packages can depend on.

One-sentence positioning:

> `mechgraph` provides a dependency-light graph data model and algorithm layer for evidence-backed biological mechanism interpretation.

Chinese positioning:

> `mechgraph` 是一个轻量的生物机制证据图底层包，用于承载和操作来自 PPI、共表达、语义相似性、调控关系、通路关系等来源的机制证据。

## 2. Design Constraints

### 2.1 Dependency direction

`mechgraph` must be a foundation package. It can be imported by:

- `GOSemSim`
- `clusterProfiler`
- `enrichplot`
- `ggtree`
- `ggtangle`
- `ReactomePA`
- `DOSE`
- `enrichit`

Therefore `mechgraph` must not import these packages.

Allowed direction:

```text
mechgraph
  ↑
GOSemSim      clusterProfiler      ggtree      ggtangle      enrichplot
```

Disallowed direction:

```text
mechgraph -> GOSemSim
mechgraph -> clusterProfiler
mechgraph -> ggtree
mechgraph -> ggtangle
```

### 2.2 Non-goals

`mechgraph` must not:

- run ORA, GSEA, NSEA, or other enrichment methods
- parse `enrichResult`, `gseaResult`, or `compareClusterResult` internally
- calculate GO semantic similarity internally
- run WGCNA pipelines internally
- render publication plots internally
- call LLMs or generate natural-language biological interpretations
- infer causality or claim confirmed mechanisms
- depend on Bioconductor annotation packages

These features belong in higher-level packages:

- `clusterProfiler`: enrichment objects, term-gene graphs, interpretation workflows
- `GOSemSim`: GO semantic similarity and semantic graph construction
- `WGCNA`: coexpression module construction
- `ggtree`: tree visualization of SPT/MST outputs
- `ggtangle`: network visualization
- `enrichplot`: enrichment-aware visualization
- `enrichit`: topology-aware enrichment algorithms

### 2.3 Dependency budget

The core package should use base R data structures and keep hard dependencies minimal.

Recommended hard dependencies:

```text
Imports:
  methods
  stats
  utils
```

Optional hard dependencies if the developer experience requires them:

```text
Imports:
  rlang
```

Recommended optional dependencies:

```text
Suggests:
  igraph
  curl
  jsonlite
  testthat
```

Design rule:

- Core object construction must not require `igraph`.
- Graph algorithms may require `igraph` through `Suggests`.
- Download helpers may require `curl` or use `utils::download.file()`.
- No `dplyr`, `tibble`, `purrr`, `AnnotationDbi`, `GOSemSim`, `clusterProfiler`, `WGCNA`, `ggplot2`, `ggtree`, or `ggtangle` in `Imports`.

## 3. Conceptual Model

### 3.1 Mechanism evidence graph

A mechanism evidence graph is a graph whose nodes and edges represent biological entities and evidence relationships that may help explain a biological mechanism.

It is not a causal model by default. It is an evidence container.

Examples of node types:

- `gene`
- `protein`
- `term`
- `pathway`
- `module`
- `regulator`
- `compound`
- `phenotype`
- `sample_cluster`

Examples of edge types:

- `ppi`
- `physical_interaction`
- `functional_association`
- `coexpression`
- `semantic_similarity`
- `term_gene`
- `pathway_membership`
- `regulation`
- `activation`
- `inhibition`
- `phosphorylation`
- `ligand_receptor`
- `module_membership`

Examples of evidence sources:

- STRING
- WGCNA-derived TOM or adjacency matrix
- GOSemSim-derived semantic similarity graph
- OmniPath
- BioGRID
- IntAct
- Reactome
- Pathway Commons
- SIGNOR
- user-supplied edge list

### 3.2 Layered evidence

`mechgraph` should support multiple evidence layers in one graph:

```text
PPI edge              STRING
semantic edge         GOSemSim
coexpression edge     WGCNA-derived TOM
term-gene edge        clusterProfiler
pathway relation      Reactome / Pathway Commons
regulatory edge       OmniPath / SIGNOR / user input
```

The package should make evidence combination easy while keeping evidence provenance intact.

### 3.3 Mechanism-specific design

`mechgraph` is not just a PPI network container. PPI is only one evidence layer. The package should represent candidate biological mechanisms as evidence-backed graph structures that can be inspected, reduced, and interpreted conservatively.

The core mechanism model should distinguish:

```text
entity      biological object, such as gene, protein, term, pathway, module, or phenotype
relation    evidence-backed relationship between entities
context     experiment-specific signal attached to nodes or edges
subgraph    compact mechanism candidate extracted from a larger graph
claim       conservative interpretation derived from evidence and context
```

Example:

```text
TP53 --physical_interaction--> MDM2
source: BioGRID
evidence: experimental system / PMID
context: logFC, p-value, sample cluster, condition
status: evidence-supported relation, not causal by default
```

This means `mechgraph` should support:

- evidence layers such as BioGRID PPI, coexpression, semantic similarity, term-gene membership, pathway membership, and regulation;
- context layers such as differential expression, cell type, time point, WGCNA module, phenotype, and query gene set membership;
- topology-aware reduction such as hubs, bridges, shortest paths, MST/SPT, connector nodes, and induced mechanism subgraphs;
- conservative language and metadata that prevent users or downstream tools from treating association evidence as confirmed causality.

The difference between a generic PPI graph and a mechanism graph is:

```text
PPI graph        asks who is connected to whom.
Mechanism graph  asks how evidence-backed connections form a traceable candidate explanation in a specific biological context.
```

Therefore BioGRID should be treated as the first physical-interaction evidence backend, not as the conceptual boundary of the package.

### 3.4 Claims are not evidence

`mechgraph` should keep biological evidence, experimental context, and interpretation claims separate.

Evidence records come from sources such as BioGRID, STRING, HuRI, WGCNA-derived matrices, GO semantic similarity, pathway databases, or user-supplied tables. Claims are interpretations derived from those records.

Recommended claim schema:

```text
claim_id
subject
predicate
object
support_edges
support_sources
support_pmids
confidence
status
caveat
created_by
created_at
```

Example claim:

```text
subject: TP53
predicate: may connect
object: MDM2-associated stress response genes
support_sources: BioGRID
status: candidate
caveat: physical interaction evidence alone does not establish direction or causality
```

Important rule:

> LLM output, natural-language summaries, and automated interpretations are claims, not evidence.

They may be stored alongside the graph for review, but they must not be silently merged into edge evidence or source provenance.

### 3.5 LLM-readiness contract

The core `mechgraph` package should be LLM-ready but should not call LLMs directly.

LLM calls, prompt templates, model selection, API keys, and `aisdk` integration should live in a higher-level package or downstream workflow, such as:

```text
mechgraph.llm
enrichit
clusterProfiler
other YuLab interpretation workflows
```

The core package should provide structured exports that can be passed to an LLM safely:

```r
mg_mechanism_summary(x, nodes = NULL, max_edges = 50)
mg_evidence_table(x, nodes = NULL)
mg_context_table(x, nodes = NULL)
mg_llm_payload(x, nodes = NULL, format = c("list", "json", "markdown"))
mg_claims(x)
mg_add_claims(x, claims)
```

The LLM-facing payload should be structured, compact, and provenance-preserving. It should include:

```text
graph summary
focus nodes or query sets
node table
edge table
evidence fields
context fields
source/version/license metadata
PMID/URL fields where available
uncertainty and causality constraints
```

Recommended payload shape:

```r
list(
    graph = list(
        n_nodes = 42,
        n_edges = 87,
        node_types = c("protein", "term"),
        edge_types = c("physical_interaction", "term_gene")
    ),
    focus = list(
        query_nodes = c("TP53", "MDM2"),
        phenotype = "tumor stress basal cluster"
    ),
    nodes = nodes_df,
    edges = edges_df,
    evidence = evidence_df,
    context = context_df,
    constraints = list(
        causal_claim_allowed = FALSE,
        require_citations = TRUE,
        uncertainty_language = TRUE
    )
)
```

Design rules:

- `mechgraph` must not require `aisdk` or any LLM SDK in `Imports`.
- LLM-related functions in the core package should only prepare, validate, or store structured data.
- Any function that generates natural language using an LLM should live outside the core package.
- LLM payloads should be small enough for model context windows and should prefer selected mechanism subgraphs over full networks.
- Payloads should preserve provenance and uncertainty constraints so downstream LLMs can cite sources and avoid overclaiming.
- LLM-generated claims should be stored as claim records with caveats and support links, not as new biological evidence.

## 4. Core Data Schema

### 4.1 Object class

The main object class should be simple:

```r
mechgraph <- list(
    nodes = nodes_df,
    edges = edges_df,
    metadata = metadata_list
)
class(mechgraph) <- "mechgraph"
```

Do not start with S4 unless a strong need emerges. A list-based S3 object is easier for CRAN users, downstream packages, and tests.

Object-system decision:

- The MVP should use an S3 list-based class.
- `nodes` and `edges` are the canonical storage layer and must remain base `data.frame` objects.
- `metadata` is a plain named list.
- `igraph` is an optional algorithm backend, not the canonical storage format.
- Constructors and validators should enforce the schema; accessors and coercion methods should keep the object easy to inspect.

Rationale:

- A plain `data.frame`/`list` without a class is too loose for downstream dispatch.
- A full `igraph` object as the primary representation would make provenance-rich edge records and dependency-light installation harder.
- S4 is more appropriate only if future Bioconductor integration requires strict slots, formal validity, or complex inheritance.
- R6 is not a good fit because `mechgraph` should behave like a data container transformed by functions, not a mutable stateful object.
- S7 may be revisited later, but its ecosystem maturity and downstream compatibility are not yet strong enough to justify it for the MVP.

Practical rule:

```text
Store as S3 mechgraph -> validate as base tables -> convert to igraph only inside optional algorithm functions.
```

If a future version moves beyond S3, the migration must preserve the public table contract:

```r
mg_nodes(x)
mg_edges(x)
mg_metadata(x)
as_mechgraph(x, ...)
```

Downstream packages should not need to know the internal object system in order to extract node and edge tables.

### 4.2 Required node columns

`nodes` must be a base `data.frame`.

Required columns:

```text
id        character, unique node identifier
type      character, node type
label     character, display label
```

Recommended optional columns:

```text
source        character
taxon_id      character or integer
id_type       character
description   character
```

Node IDs must be stable and unique inside a graph.

### 4.3 Required edge columns

`edges` must be a base `data.frame`.

Required columns:

```text
from      character, source node id
to        character, target node id
type      character, edge type
```

Recommended optional columns:

```text
weight          numeric
score           numeric
direction       character: "directed", "undirected", or NA
sign            character: "positive", "negative", "activation", "inhibition", or NA
source          character
source_version  character
evidence        character
evidence_type   character
pmid            character
url             character
retrieved_at    POSIXct or character
```

### 4.4 Metadata

`metadata` is a named list.

Recommended fields:

```text
organism
taxon_id
source
source_version
build
created_at
call
license
```

Metadata should be optional but preserved by graph operations whenever possible.

## 5. Core API

### 5.1 Constructors and validators

```r
mg_graph(nodes, edges, metadata = list(), validate = TRUE)
mg_empty(metadata = list())
mg_validate(x)
is_mechgraph(x)
```

Validation rules:

- `nodes` and `edges` are data frames.
- `nodes$id` is present, character-compatible, non-missing, and unique.
- `edges$from`, `edges$to`, and `edges$type` are present.
- all edge endpoints exist in `nodes$id`, unless `repair = TRUE` is used.
- required columns are not silently dropped.

Optional repair:

```r
mg_repair(x, add_missing_nodes = TRUE)
```

### 5.2 Accessors

```r
mg_nodes(x)
mg_edges(x)
mg_metadata(x)
mg_sources(x)
mg_node_types(x)
mg_edge_types(x)
```

Accessors should return base R objects and avoid tibble-specific behavior.

### 5.3 Mutators

```r
mg_add_nodes(x, nodes)
mg_add_edges(x, edges, add_missing_nodes = FALSE)
mg_drop_nodes(x, nodes)
mg_drop_edges(x, edges)
mg_update_metadata(x, ...)
mg_bind(...)
```

`mg_bind()` should combine multiple `mechgraph` objects while preserving evidence source columns.

### 5.4 Filters and subgraphs

```r
mg_filter_nodes(x, type = NULL, ids = NULL, source = NULL)
mg_filter_edges(x, type = NULL, source = NULL, score = NULL, weight = NULL)
mg_induced_subgraph(x, nodes)
mg_neighborhood(x, nodes, order = 1, mode = c("all", "in", "out"))
mg_between(x, nodes_a, nodes_b)
```

These functions are central for mechanism explanation because users rarely need the whole graph.

### 5.5 Coercion

Generic:

```r
as_mechgraph(x, ...)
```

Core methods in `mechgraph`:

```r
as_mechgraph.data.frame(x, ...)
as_mechgraph.matrix(x, ...)
as_mechgraph.list(x, ...)
```

Optional methods if `igraph` is installed:

```r
as_mechgraph.igraph(x, ...)
as_igraph(x, ...)
```

Higher-level packages should define their own methods:

```r
clusterProfiler::as_mechgraph.enrichResult()
GOSemSim::as_mechgraph.semData()
```

`mechgraph` must not define methods for classes owned by packages it does not import.

## 6. Input Builders

### 6.1 Generic edge-list input

```r
mg_from_edges(edges, nodes = NULL, metadata = list())
```

This should be the most robust and best-tested input path.

Expected edge-list minimum:

```text
from
to
type
```

If `nodes = NULL`, nodes are inferred from unique endpoints.

### 6.2 Adjacency and similarity matrices

```r
mg_from_adjacency(mat, threshold = NULL, type = "association", mode = "undirected")
mg_from_similarity(mat, threshold = NULL, type = "similarity", keep_diag = FALSE)
```

These functions support:

- coexpression adjacency matrices
- semantic similarity matrices generated by `GOSemSim`
- pathway or term similarity matrices
- user-defined association matrices

They should not care how the matrix was computed.

### 6.3 WGCNA-derived networks

`mechgraph` should accept WGCNA outputs but not run WGCNA.

```r
mg_from_wgcna_tom(tom, genes = NULL, threshold = NULL, signed = FALSE)
mg_from_wgcna_adjacency(adj, genes = NULL, threshold = NULL, signed = FALSE)
mg_from_wgcna_modules(modules, kME = NULL)
```

Expected behavior:

- TOM/adjacency matrices produce gene-gene coexpression edges.
- module assignments produce gene-module membership edges.
- `kME` can become edge weight or node context.

Example edge types:

```text
coexpression
module_membership
```

The documentation should say explicitly:

> WGCNA model fitting, module detection, and TOM calculation remain the responsibility of `WGCNA` or user code.

### 6.4 STRING-derived networks

STRING should be the first built-in remote data source because current `clusterProfiler` already has related code.

Suggested API:

```r
mg_string_species(version = "12.0")
mg_string_versions()
mg_string_download(taxon_id = 9606, version = "12.0",
                   network = c("functional", "physical", "detailed", "aliases", "info"),
                   cache = TRUE)
mg_from_string(taxon_id = 9606, version = "12.0",
               network = c("functional", "physical"),
               score_threshold = 400,
               cache = TRUE)
```

Supported files for early versions:

1. `protein.links`
2. `protein.physical.links`
3. `protein.links.detailed`
4. `protein.info`
5. `protein.aliases`
6. `species`

Implementation rules:

- Do not ship large STRING data files in the package.
- Download to a user cache directory.
- Record URL, version, retrieval time, taxon ID, and score threshold in metadata.
- Keep STRING IDs intact; do not silently convert IDs to gene symbols.
- Avoid importing `STRINGdb`.

### 6.5 Lightweight experimentally supported PPI sources

STRING is useful as the broad, high-coverage backend, but it is intentionally large and mixes evidence channels. `mechgraph` should also support a smaller experimentally supported PPI backend for users who want a conservative physical-interaction layer.

Recommended source strategy:

```text
heavy backend      STRING functional / physical networks
light backend      experimentally supported physical PPI
```

The light backend should prefer sources that are:

- physical PPI focused
- experimentally supported, not prediction-only
- downloadable as plain tabular or MITAB-like files
- license-compatible with open-source package use
- small enough to cache and parse without turning `mechgraph` into a heavy data package

Recommended MVP candidate:

```text
BioGRID multi-validated physical interactions
```

Rationale:

- BioGRID provides curated interaction data with stable release downloads.
- The multi-validated physical dataset excludes genetic interactions and keeps only physical interactions passing cross-validation criteria.
- BioGRID downloads are available under the MIT License, which is straightforward for package integration.
- Tabular and MITAB formats make it implementable without adding heavy parser dependencies.

Suggested API:

```r
mg_biogrid_versions()
mg_biogrid_download(version = "latest",
                    dataset = c("mv_physical", "organism", "all"),
                    format = c("tab3", "mitab"),
                    cache = TRUE)
mg_from_biogrid(version = "latest",
                dataset = "mv_physical",
                taxon_id = NULL,
                cache = TRUE)
```

Human-specific optional candidate:

```text
HuRI
```

Rationale:

- HuRI is a systematic human binary PPI reference map with about 53,000 protein-protein interactions.
- It is much smaller than broad functional association networks and is experimentally generated.
- It is human-only, so it should not be the general light backend, but it is a strong optional human reference layer.

Suggested API:

```r
mg_huri_download(cache = TRUE)
mg_from_huri(cache = TRUE)
```

Other sources to treat cautiously:

- `IntAct`: excellent curated molecular-interaction resource and PSI-MI aligned, but broader and more complex than needed for the first light backend. Good phase-2 candidate.
- `DIP`: experimentally oriented and historically important, but license and maintenance constraints make it less attractive as the first default.
- `HPRD`: human-focused but old and less suitable as a modern default data source.
- integrated resources such as HIPPIE, APID, mentha, or OmniPath can be valuable later, but they add source-merging and confidence-scoring policy decisions that should stay out of the MVP.

Implementation rules:

- Do not ship full BioGRID, HuRI, or IntAct data in the package.
- Download into a user cache directory and record source, version, URL, license, retrieval time, and filters.
- Preserve original source identifiers and publication/evidence fields when present.
- For the light backend, default to physical PPI edges with `type = "physical_interaction"` or `type = "ppi"`.
- Do not collapse duplicate evidence records by default.

## 7. Graph Algorithms

Graph algorithms may depend on `igraph` in `Suggests`.

Each graph algorithm should:

- check for `igraph` at runtime
- convert internally with `as_igraph()`
- return `mechgraph` or base `data.frame` objects
- preserve provenance when returning subgraphs

### 7.1 Basic topology

```r
mg_components(x)
mg_degree(x, mode = c("all", "in", "out"))
mg_hubs(x, method = c("degree", "betweenness", "pagerank"), n = 20)
mg_bridges(x, method = "betweenness", n = 20)
mg_component_stats(x)
```

### 7.2 Paths and explanatory subgraphs

```r
mg_shortest_paths(x, from, to, weight = NULL)
mg_k_shortest_paths(x, from, to, k = 5, weight = NULL)
mg_spt(x, root, terminals = NULL, weight = NULL)
mg_mst(x, weight = "weight")
mg_connectors(x, groups, method = c("betweenness", "paths"))
```

`mg_spt()` and `mg_mst()` are important integration points for `ggtree`.

`mechgraph` should compute and return the tree-like graph. `ggtree` should own rendering methods.

### 7.3 Mechanism subgraph extraction

```r
mg_prune(x, keep = c("terminals", "hubs", "bridges"), n = 100)
mg_explain_connection(x, from, to, k = 3)
mg_explain_group(x, nodes, method = c("spt", "mst", "steiner"))
```

These functions support mechanism explanation by reducing a large graph into a compact evidence subgraph.

### 7.4 Advanced algorithms

These should be extension-stage features:

```r
mg_steiner_tree(x, terminals, weight = NULL)
mg_prize_tree(x, prize, cost = NULL)
mg_random_walk(x, seeds, restart = 0.7)
mg_diffusion(x, seeds)
```

Do not include them in the first MVP unless there is a clear implementation path and tests.

## 8. Evidence Fusion

Evidence fusion is one of the differentiating features of `mechgraph`.

### 8.1 Combining graphs

```r
mg_combine(..., merge_nodes = TRUE, merge_edges = FALSE)
```

Combination must preserve edge-level provenance.

If the same biological relation appears in multiple sources, do not collapse it by default. Users should be able to inspect individual evidence records.

### 8.2 Consensus edges

```r
mg_consensus_edges(x, by = c("from", "to", "type"), min_sources = 2)
mg_edge_evidence(x, from, to, type = NULL)
mg_score_edges(x, method = c("source_count", "weighted_mean", "max"))
```

Use cases:

- identify edges supported by both PPI and coexpression
- identify edges supported by multiple databases
- prioritize evidence for interpretation

## 9. Context Annotation

`mechgraph` should support adding experimental context without interpreting it.

```r
mg_add_node_context(x, data, by = "id")
mg_add_edge_context(x, data, by = c("from", "to"))
mg_context(x)
```

Examples of node context:

- logFC
- p-value
- adjusted p-value
- expression
- cell type
- time point
- gene cluster
- WGCNA module color
- term membership

The package should not decide whether a gene is biologically important. It should only store and expose context fields.

## 10. Quality Control

Mechanism graphs can be misleading if coverage is poor or hub bias dominates. `mechgraph` should provide lightweight QC.

```r
mg_qc(x)
mg_mapping_rate(x, input)
mg_source_coverage(x, input = NULL)
mg_isolated_nodes(x)
mg_largest_component(x)
mg_degree_bias(x, nodes)
```

QC output should be a simple list or data frame.

Recommended QC metrics:

- number of nodes
- number of edges
- number of connected components
- largest component size
- isolated node count
- edge source distribution
- node type distribution
- input mapping rate
- query gene coverage
- degree distribution summary

## 11. Null Models

Null models are valuable for mechanism explanation because they prevent over-interpreting dense-looking graphs.

MVP may only include simple functions; advanced permutation can come later.

```r
mg_randomize(x, method = c("degree_preserving", "edge_shuffle"), n = 1)
mg_connectivity_score(x, nodes)
mg_observed_vs_random(x, nodes, n = 1000, method = "degree_preserving")
```

Questions these functions answer:

- Are query genes more connected than expected by chance?
- Is a bridge node meaningful or merely high-degree?
- Is a term subnetwork unusually dense?

These are not enrichment tests. They are graph-context diagnostics for mechanism interpretation.

## 12. ID Mapping Contract

`mechgraph` should define ID fields and simple mapping helpers, but it should not depend on annotation packages.

```r
mg_map_ids(x, map, from = "id", to = "symbol")
mg_unmapped(input, map)
mg_id_types(x)
```

The mapping table can come from:

- `clusterProfiler::bitr()`
- `AnnotationDbi`
- STRING aliases
- user-supplied table

Required behavior:

- never silently discard unmapped IDs
- report mapping rate
- preserve original IDs

Recommended node columns:

```text
id
label
id_type
symbol
entrez
ensembl
uniprot
taxon_id
```

Only `id`, `type`, and `label` are required.

## 13. Import and Export

### 13.1 File formats

MVP:

```r
mg_read_edges(file, ...)
mg_write_edges(x, file, ...)
mg_write_json(x, file)
mg_read_json(file)
```

Extension:

```r
mg_read_graphml(file)
mg_write_graphml(x, file)
mg_to_cytoscape(x)
mg_write_cytoscape_tables(x, node_file, edge_file)
```

GraphML support may require `igraph` and should stay optional.

### 13.2 Plain table interoperability

Always support:

```r
as.data.frame(mg_edges(x))
as.data.frame(mg_nodes(x))
```

Do not require users to understand custom classes to extract the graph.

## 14. Integration Contracts for Other Packages

### 14.1 GOSemSim

`GOSemSim` should remain responsible for semantic similarity calculation.

Possible `GOSemSim` APIs:

```r
go_semantic_graph(...)
gene_semantic_graph(...)
term_similarity_edges(...)
as_mechgraph.semData(...)
```

Expected output:

```text
from      to        type                   weight  source
GO:xxxx   GO:yyyy   semantic_similarity    0.83    GOSemSim
```

`mechgraph` should only consume the edge list or `mechgraph` object.

### 14.2 clusterProfiler

`clusterProfiler` should remain responsible for enrichment result objects and term-gene relationships.

Possible `clusterProfiler` APIs:

```r
as_mechgraph.enrichResult(...)
as_mechgraph.gseaResult(...)
term_mechgraph(...)
```

Expected graph layers:

```text
term -> gene        term_gene
term -> pathway     database_relation
cluster -> term     cluster_membership
```

`clusterProfiler` can combine these with STRING/WGCNA/semantic graphs through `mg_combine()`.

### 14.3 ggtree

`ggtree` should own visualization of tree-like graph outputs.

`mechgraph` provides:

```r
mg_spt()
mg_mst()
```

`ggtree` may provide:

```r
as.treedata.mechgraph()
geom_* methods
```

### 14.4 ggtangle

`ggtangle` should own graph visualization.

`mechgraph` provides nodes and edges. `ggtangle` may define:

```r
autoplot.mechgraph()
geom_edge_* integrations
```

### 14.5 enrichit

`enrichit` can use `mechgraph` as a common input format for network-aware methods, but algorithm-specific result classes remain in `enrichit`.

## 15. Recommended Package Structure

```text
mechgraph/
  DESCRIPTION
  NAMESPACE
  R/
    graph.R
    validate.R
    accessors.R
    mutate.R
    filter.R
    coerce.R
    builders.R
    string.R
    wgcna.R
    algorithms.R
    evidence.R
    context.R
    qc.R
    null.R
    io.R
    utils.R
  tests/
    testthat/
      test-graph.R
      test-validate.R
      test-builders.R
      test-combine.R
      test-filter.R
      test-qc.R
      test-algorithms.R
      test-string.R
  vignettes/
    mechgraph.Rmd
    string-network.Rmd
    wgcna-input.Rmd
    evidence-fusion.Rmd
```

## 16. MVP Scope

### 16.1 MVP goals

The first release should prove that `mechgraph` can serve as a stable low-level mechanism graph layer.

MVP must support:

1. Create and validate a `mechgraph` object.
2. Build graphs from edge lists, matrices, and WGCNA-derived inputs.
3. Download/load STRING networks as optional data source.
4. Combine multiple evidence graphs.
5. Query subgraphs and neighborhoods.
6. Run basic graph algorithms through optional `igraph`.
7. Provide QC summaries.

### 16.2 MVP functions

Core:

```r
mg_graph()
mg_validate()
is_mechgraph()
mg_nodes()
mg_edges()
mg_metadata()
mg_add_nodes()
mg_add_edges()
mg_bind()
mg_filter_nodes()
mg_filter_edges()
mg_induced_subgraph()
```

Builders:

```r
mg_from_edges()
mg_from_adjacency()
mg_from_similarity()
mg_from_wgcna_tom()
mg_from_wgcna_modules()
```

STRING:

```r
mg_string_species()
mg_string_download()
mg_from_string()
```

Algorithms:

```r
mg_components()
mg_hubs()
mg_bridges()
mg_shortest_paths()
mg_spt()
mg_mst()
```

Evidence and QC:

```r
mg_combine()
mg_edge_evidence()
mg_consensus_edges()
mg_qc()
mg_mapping_rate()
```

### 16.3 MVP non-goals

Do not include in MVP:

- semantic similarity calculation
- enrichment result parsing
- plotting
- LLM interpretation
- causal inference
- PubMed evidence retrieval
- full OmniPath/BioGRID/IntAct integrations
- advanced Steiner tree or prize-collecting algorithms

## 17. Extension Roadmap

### Phase 1: Core graph object

Deliver:

- object constructor
- validator
- accessors
- edge-list and matrix builders
- basic tests

### Phase 2: Evidence fusion

Deliver:

- graph combination
- evidence lookup
- consensus edges
- provenance preservation

### Phase 3: STRING backend

Deliver:

- species metadata
- version metadata
- cached download
- functional and physical network import
- detailed scores if feasible

### Phase 4: WGCNA-derived input

Deliver:

- TOM import
- adjacency import
- module membership graph
- kME handling

### Phase 5: Topology algorithms

Deliver:

- components
- hubs
- bridges
- shortest paths
- SPT
- MST

### Phase 6: QC and null models

Deliver:

- coverage and mapping metrics
- component statistics
- observed-vs-random connectivity

### Phase 7: downstream package integration

Deliver in downstream packages, not in `mechgraph`:

- `GOSemSim` semantic graph export
- `clusterProfiler` enrichment result export
- `ggtree` tree visualization
- `ggtangle` graph visualization

## 18. Naming Rules

Use `mg_` prefix for exported functions owned by `mechgraph`.

Reasons:

- avoids conflicts with common graph functions
- keeps API discoverable
- keeps downstream methods readable

Preferred terminology:

- `node`, not vertex in user-facing API
- `edge`, not link
- `source`, for evidence source
- `type`, for node/edge biological relationship type
- `context`, for experimental annotations
- `provenance`, for database/version/retrieval metadata
- `mechanism graph`, not causal graph

Avoid overclaiming:

- do not use "confirmed mechanism"
- do not use "causal" unless the edge source explicitly provides causal direction and the documentation qualifies it
- prefer "candidate", "putative", "evidence-supported", and "mechanism evidence"

## 19. Testing Strategy

### 19.1 Unit tests

Required tests:

- constructor rejects invalid node and edge tables
- missing endpoint handling is explicit
- graph combination preserves duplicate evidence
- filtering preserves metadata
- matrix builders produce expected edge counts
- WGCNA input builders handle named and unnamed matrices
- STRING URL construction is deterministic
- algorithm wrappers fail clearly if `igraph` is unavailable
- QC output is stable

### 19.2 Network tests

Remote downloads should not run by default on CRAN.

Use:

- mocked URL construction tests
- small local fixture files
- `skip_on_cran()` for live STRING checks

### 19.3 Golden fixtures

Include tiny test fixtures:

- 5-node PPI graph
- 5-gene coexpression matrix
- 4-term semantic similarity matrix
- small mixed evidence graph

These fixtures should be small enough to inspect manually.

## 20. Documentation Plan

### 20.1 README

README should explain:

- what a mechanism evidence graph is
- what `mechgraph` does not do
- how to create a graph from an edge list
- how to combine STRING, WGCNA-derived, and semantic edges
- how downstream packages are expected to integrate

### 20.2 Vignettes

Recommended vignettes:

1. `mechgraph`: core object and schema
2. `string-network`: STRING download and subgraph extraction
3. `wgcna-input`: importing WGCNA-derived networks
4. `evidence-fusion`: combining PPI, coexpression, and semantic evidence
5. `topology`: SPT, MST, hubs, bridges, and explanatory subgraphs

## 21. Open Questions

These should be decided before implementation:

1. Should `igraph` be in `Imports` or `Suggests`?
2. Should cache handling use `tools::R_user_dir()` directly or a YuLab utility?
3. Should `mechgraph` live on CRAN first, Bioconductor first, or both?
4. Should STRING download code move out of `clusterProfiler` immediately or stay duplicated during transition?
5. The object should remain S3 list-based for the MVP. Revisit S4 or S7 only after downstream adoption exposes a concrete need for formal slots, stricter validity, or complex inheritance. R6 should remain out of scope unless the package later introduces a genuinely stateful workflow, which is not part of the current design.
6. Should edge direction use a strict enum or allow arbitrary source-specific strings?
7. How much license metadata should be enforced for external data sources?

## 22. Success Criteria

The package is successful if:

- `clusterProfiler` can convert enrichment results into a `mechgraph` without `mechgraph` depending on `clusterProfiler`.
- `GOSemSim` can export semantic similarity edges as a `mechgraph` without `mechgraph` depending on `GOSemSim`.
- WGCNA-derived coexpression networks can be represented without importing `WGCNA`.
- STRING networks can be downloaded and represented without importing `STRINGdb`.
- `ggtree` can visualize SPT/MST outputs by defining methods downstream.
- `ggtangle` can visualize `mechgraph` objects by consuming node and edge tables.
- users can combine multiple evidence sources and inspect provenance.
- the core package remains dependency-light and testable on CRAN.
