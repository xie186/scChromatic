# Package index

## Palette discovery and access

Retrieve registered colors, metadata, and scales-compatible closures.

- [`sc_palette()`](https://xie186.github.io/scChromatic/reference/sc_palette.md)
  : Retrieve colors from a registered palette
- [`sc_pal()`](https://xie186.github.io/scChromatic/reference/sc_pal.md)
  : Create a scales-compatible scChromatic palette
- [`sc_palette_names()`](https://xie186.github.io/scChromatic/reference/sc_palette_names.md)
  : List registered palette IDs
- [`sc_palette_info()`](https://xie186.github.io/scChromatic/reference/sc_palette_info.md)
  : Inspect palette metadata and provenance
- [`sc_palette_generate()`](https://xie186.github.io/scChromatic/reference/sc_palette_generate.md)
  : Generate a deterministic qualitative color sequence

## Persistent mappings

Keep labels stable across subsets, reorderings, and related lineages.

- [`sc_color_map()`](https://xie186.github.io/scChromatic/reference/sc_color_map.md)
  : Create a persistent label-to-color mapping
- [`sc_relationship_from_knn()`](https://xie186.github.io/scChromatic/reference/sc_relationship_from_knn.md)
  : Derive label relationships from coordinate neighborhoods
- [`sc_relationship_map()`](https://xie186.github.io/scChromatic/reference/sc_relationship_map.md)
  : Optimize a persistent color map from label relationships
- [`update_sc_color_map()`](https://xie186.github.io/scChromatic/reference/update_sc_color_map.md)
  : Update a persistent color map
- [`as_named_colors()`](https://xie186.github.io/scChromatic/reference/as_named_colors.md)
  : Extract named colors from a persistent map
- [`sc_color_map_plot()`](https://xie186.github.io/scChromatic/reference/sc_color_map_plot.md)
  : Plot a persistent color map
- [`write_sc_color_map()`](https://xie186.github.io/scChromatic/reference/write_sc_color_map.md)
  : Write a persistent color map
- [`read_sc_color_map()`](https://xie186.github.io/scChromatic/reference/read_sc_color_map.md)
  : Read a persistent color map
- [`sc_hierarchy_map()`](https://xie186.github.io/scChromatic/reference/sc_hierarchy_map.md)
  : Create or extend a hierarchy-aware color map
- [`sc_highlight_map()`](https://xie186.github.io/scChromatic/reference/sc_highlight_map.md)
  : Create a focus-versus-other color map

## ggplot2 scales

- [`scale_color_sc_d()`](https://xie186.github.io/scChromatic/reference/scale_color_sc_d.md)
  [`scale_colour_sc_d()`](https://xie186.github.io/scChromatic/reference/scale_color_sc_d.md)
  [`scale_fill_sc_d()`](https://xie186.github.io/scChromatic/reference/scale_color_sc_d.md)
  : Discrete scChromatic color scale
- [`scale_color_sc_c()`](https://xie186.github.io/scChromatic/reference/scale_color_sc_c.md)
  [`scale_colour_sc_c()`](https://xie186.github.io/scChromatic/reference/scale_color_sc_c.md)
  [`scale_fill_sc_c()`](https://xie186.github.io/scChromatic/reference/scale_color_sc_c.md)
  : Continuous scChromatic color scale
- [`scale_color_sc_map()`](https://xie186.github.io/scChromatic/reference/scale_color_sc_map.md)
  [`scale_colour_sc_map()`](https://xie186.github.io/scChromatic/reference/scale_color_sc_map.md)
  [`scale_fill_sc_map()`](https://xie186.github.io/scChromatic/reference/scale_color_sc_map.md)
  : Manual ggplot2 scales from a persistent color map

## Diagnostics and recommendations

- [`sc_palette_audit()`](https://xie186.github.io/scChromatic/reference/sc_palette_audit.md)
  : Audit palette separation and background contrast
- [`sc_palette_recommend()`](https://xie186.github.io/scChromatic/reference/sc_palette_recommend.md)
  : Recommend palettes from transparent registry rules
- [`sc_palette_plot()`](https://xie186.github.io/scChromatic/reference/sc_palette_plot.md)
  : Plot palette swatches or dense point previews
- [`sc_redundant_encoding()`](https://xie186.github.io/scChromatic/reference/sc_redundant_encoding.md)
  : Allocate redundant shapes or patterns for confusable colors

## Example data

- [`sc_example`](https://xie186.github.io/scChromatic/reference/sc_example.md)
  : Synthetic PBMC-like single-cell example data
