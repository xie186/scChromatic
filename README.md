# scChromatic

Reproducible, provenance-aware color systems for single-cell data visualization.

## Why single-cell analyses need persistent color mappings

Palette calls assign colors by position. After a subset or factor reorder, the
same cell type can silently receive a different color. `sc_color_map()` stores a
named label-to-color contract once, so every downstream figure reuses the same
assignments.

## Installation

```r
# install.packages("pak")
pak::pak("TODO/scChromatic")
```

The repository metadata contains TODO author and URL placeholders that must be
replaced before release.

## Quick start

```r
library(scChromatic)
library(ggplot2)

cell_types <- c("B", "T", "NK", "Mono")
cell_map <- sc_color_map(cell_types, palette = "chromatic")
as_named_colors(cell_map)

umap <- data.frame(
  UMAP1 = cos(seq(0, 12, length.out = 400)) + rnorm(400, sd = 0.25),
  UMAP2 = sin(seq(0, 12, length.out = 400)) + rnorm(400, sd = 0.25),
  cell_type = rep(cell_types, each = 100)
)
ggplot(umap, aes(UMAP1, UMAP2, color = cell_type)) +
  geom_point(size = 0.7) +
  scale_color_sc_map(cell_map)
```

## Stable colors across subsets

```r
full_colors <- as_named_colors(cell_map)[cell_types]
subset_colors <- as_named_colors(cell_map)[c("T", "NK")]
stopifnot(identical(subset_colors, full_colors[c("T", "NK")]))

cell_map <- update_sc_color_map(cell_map, c(cell_types, "DC"))
```

## ArchR palettes

Thirty palettes are frozen from ArchR commit
`6feec354ad6c8052ddbc4626a2ca2d858ed465bf`. Literal upstream order and the
separate nested priority order are both available.

```r
sc_palette("archr_stallion", 8, selection = "source")
pal_archr("stallion")(8)
```

## Continuous expression and signed scores

```r
ggplot(umap, aes(UMAP1, UMAP2, color = UMAP1)) +
  geom_point() +
  scale_color_sc_c("viridis")

ggplot(umap, aes(UMAP1, UMAP2, color = UMAP1 * UMAP2)) +
  geom_point() +
  scale_color_sc_c("archr_coolwarm", midpoint = 0)
```

## Accessibility auditing

```r
sc_palette_audit("chromatic", cvd = c("none", "deutan", "protan", "tritan"))
sc_palette_plot("okabe_ito", view = "both", cvd = c("none", "deutan"))
sc_palette_recommend(12, use = "cell_identity", geometry = "point")
```

Audit metrics diagnose color separation and background contrast; they are not a
guarantee that every viewer or plotting geometry can distinguish every color.

## Palette provenance

`sc_palette_info()` exposes capacity, intended use, source URL, exact source
commit where known, citation, license, derivation status, and frozen audit
metrics. The full registry is installed at `extdata/palette-provenance.csv`;
`NOTICE` records borrowed-palette disclosures and unresolved review items.

## Interoperability

`as_named_colors()` returns the ordinary named vectors expected by Seurat,
SingleCellExperiment metadata workflows, ArchR plotting arguments, and
ComplexHeatmap annotations. These frameworks remain optional. scico palettes
are also optional and produce an installation hint only when requested.
