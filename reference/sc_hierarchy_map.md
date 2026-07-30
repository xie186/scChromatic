# Create a hierarchy-aware color map

Child labels receive controlled lightness and chroma variants of
distinct parent anchor hues.

## Usage

``` r
sc_hierarchy_map(
  parent,
  child,
  parent_palette = "tol_muted",
  separation = c("balanced", "between_lineage", "within_lineage"),
  background = c("light", "dark"),
  na.value = "#BDBDBD"
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

## Value

An `sc_color_map` with a named `parent` field.

## Examples

``` r
sc_hierarchy_map(
  parent = c("Lymphoid", "Lymphoid", "Myeloid"),
  child = c("B", "T", "Mono")
)
#> <sc_color_map[3]> palette: hierarchy:tol_muted; background: light
#>   B: #833744
#>   T: #FF9FB1
#>   Mono: #332288
```
