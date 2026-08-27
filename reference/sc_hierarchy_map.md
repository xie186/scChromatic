# Create or extend a hierarchy-aware color map

Child labels receive controlled lightness and chroma variants of
distinct parent anchor hues. Pass a prior hierarchy map through
`existing` when the taxonomy grows: its parent anchors and every
established child assignment are retained exactly, while only new
parents and children receive colors.

## Usage

``` r
sc_hierarchy_map(
  parent,
  child,
  parent_palette = "tol_muted",
  separation = c("balanced", "between_lineage", "within_lineage"),
  background = c("light", "dark"),
  na.value = "#BDBDBD",
  existing = NULL
)
```

## Arguments

- parent:

  Parent lineage labels.

- child:

  Child subtype labels.

- parent_palette:

  Qualitative palette for parent anchors.

- separation:

  Emphasize balanced, between-lineage, or within-lineage separation.

- background:

  Light or dark background.

- na.value:

  Missing-value color.

- existing:

  Optional `sc_color_map` previously returned by `sc_hierarchy_map()`.
  Existing parents, anchors, children, colors, and map metadata are
  retained.

## Value

An `sc_color_map` with named `parent` and `parent_anchors` fields.

## Details

Each child has one canonical parent in this lightweight hierarchy model.
Alternative names or identifiers can be retained in the map's optional
`aliases` metadata and survive serialization, but multiple-parent
ontology graphs are outside this constructor's scope.

## Examples

``` r
map <- sc_hierarchy_map(
  parent = c("Lymphoid", "Lymphoid", "Myeloid"),
  child = c("B", "T", "Mono")
)
sc_hierarchy_map("Lymphoid", "NK", existing = map)
#> Warning: Some hierarchy colors have weak CIE2000 separation (2.4).
#> <sc_color_map[4]> type: hierarchy; palette: hierarchy:tol_muted; background: light; schema: v1
#>   B: #833744
#>   T: #FF9FB1
#>   Mono: #332288
#>   NK: #8B3E4B
```
