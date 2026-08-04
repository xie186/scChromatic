
<!-- README.md is generated from README.Rmd. -->

# scChromatic

[![R-CMD-check](https://github.com/xie186/scChromatic/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/xie186/scChromatic/actions/workflows/R-CMD-check.yaml)
[![test-coverage](https://github.com/xie186/scChromatic/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/xie186/scChromatic/actions/workflows/test-coverage.yaml)

Reproducible, provenance-aware color systems for single-cell data
visualization.

## Why single-cell analyses need persistent color mappings

Palette calls assign colors by position. After a subset or factor
reorder, the same cell type can silently receive a different color.
`sc_color_map()` stores a named label-to-color contract once, so every
downstream figure reuses the same assignments.

## Installation

``` r
# install.packages("pak")
pak::pak("xie186/scChromatic")
```

## Example dataset

`sc_example` is a deterministic synthetic PBMC-like dataset with 720
cells. It contains a UMAP-like embedding plus cell identity, parent
lineage, sample, condition, marker expression, signed score, pseudotime,
and QC columns.

``` r
data(sc_example)
dim(sc_example)
head(sc_example[c("cell_type", "sample", "condition", "MS4A1")])
```

## Quick start

``` r
library(scChromatic)
library(ggplot2)

data(sc_example)
cell_types <- levels(sc_example$cell_type)
cell_map <- sc_color_map(sc_example$cell_type, palette = "chromatic")
as_named_colors(cell_map)

ggplot(sc_example, aes(UMAP1, UMAP2, color = cell_type)) +
  geom_point(size = 0.7) +
  scale_color_sc_map(cell_map)
```

## Stable colors across subsets

``` r
full_colors <- as_named_colors(cell_map)[cell_types]
stimulated <- subset(
  sc_example,
  condition == "Stimulated" & cell_type %in% c("CD4 T", "NK", "Monocyte")
)
subset_colors <- as_named_colors(cell_map)[levels(droplevels(stimulated$cell_type))]
stopifnot(identical(subset_colors, full_colors[names(subset_colors)]))

ggplot(stimulated, aes(UMAP1, UMAP2, color = cell_type)) +
  geom_point(size = 0.7) +
  scale_color_sc_map(cell_map)
```

## Continuous expression and signed scores

``` r
ggplot(sc_example, aes(UMAP1, UMAP2, color = MS4A1)) +
  geom_point() +
  scale_color_sc_c("viridis")

ggplot(sc_example, aes(UMAP1, UMAP2, color = signed_score)) +
  geom_point() +
  scale_color_sc_c("chromatic_balance", midpoint = 0)
```

## Lineages, pseudotime, and QC

``` r
lineage_map <- sc_hierarchy_map(sc_example$lineage, sc_example$cell_type)

ggplot(sc_example, aes(UMAP1, UMAP2, color = cell_type)) +
  geom_point(size = 0.7) +
  scale_color_sc_map(lineage_map)

ggplot(sc_example, aes(UMAP1, UMAP2, color = pseudotime)) +
  geom_point(size = 0.7) +
  scale_color_sc_c("cividis")
```

## Portable, versioned color maps

``` r
path <- tempfile(fileext = ".json")
write_sc_color_map(cell_map, path)
restored_map <- read_sc_color_map(path)
stopifnot(identical(as_named_colors(restored_map), as_named_colors(cell_map)))
```

JSON and CSV preserve the complete mapping contract, including
provenance, hierarchy, focus, aliases, locks, history, context, and seed
metadata. The installed [Draft 2020-12 JSON
Schema](https://json-schema.org/draft/2020-12) at
`schema/sc-color-map.schema.json` makes map files independently
validatable outside R; unknown future schema versions are rejected
instead of guessed.

## Accessibility auditing

``` r
sc_palette_audit("chromatic", cvd = c("none", "deutan", "protan", "tritan"))
sc_palette_plot("okabe_ito", view = "both", cvd = c("none", "deutan"))
sc_palette_recommend(12, use = "cell_identity", geometry = "point")
```

Audit metrics diagnose color separation and background contrast; they
are not a guarantee that every viewer or plotting geometry can
distinguish every color.

## Palette provenance

`sc_palette_info()` exposes capacity, intended use, source URL, exact
source version and commit or archive hash where known, citation,
license, derivation status, and frozen audit metrics. The full registry
is installed at `extdata/palette-provenance.csv`; `NOTICE` records
applicable third-party license notices.

## Interoperability

`as_named_colors()` returns the ordinary named vectors expected by
Seurat, SingleCellExperiment metadata workflows, ArchR plotting
arguments, and ComplexHeatmap annotations. These frameworks remain
optional. ArchR compatibility vectors are not distributed. The licensed
`scico_*` LUTs are bundled from pinned sources and require no runtime
framework dependency.
