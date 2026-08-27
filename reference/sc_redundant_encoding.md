# Allocate redundant shapes or patterns for confusable colors

Finds label pairs whose worst CIE2000 distance across normal and
requested CVD simulations is below `min_cie2000`, then assigns auxiliary
encoding groups with a deterministic DSATUR heuristic so every such pair
differs. Colors are returned unchanged. Shapes are ggplot2-compatible
integers. Default pattern names are compatible with ggpattern;
`texture_group` can also be used as a grouping variable for other
texture systems such as scatterHatch.

## Usage

``` r
sc_redundant_encoding(
  x,
  channel = c("shape", "pattern", "both"),
  min_cie2000 = 8,
  cvd = c("deutan", "protan", "tritan"),
  shapes = c(16L, 17L, 15L, 18L, 8L, 3L),
  patterns = c("none", "stripe", "crosshatch", "circle", "wave", "weave")
)
```

## Arguments

- x:

  An `sc_color_map` or fully named color vector.

- channel:

  Allocate `"shape"`, `"pattern"`, or joint shape-pattern combinations
  with `"both"`. A conflicting pair differs in at least one enabled
  aesthetic.

- min_cie2000:

  Pairs below this worst-vision CIE2000 distance must receive different
  auxiliary encodings.

- cvd:

  Vision simulations used with normal vision.

- shapes:

  Unique integer plotting shapes.

- patterns:

  Unique non-empty pattern names.

## Value

A data frame containing label, unchanged color, encoding group, texture
group, shape, pattern, and number of confusable neighbors, with
`sc_encoding` settings and `conflicts` records as attributes.

## Details

Allocation is deterministic for one full label set, but graph priorities
can change when labels are added or removed. Allocate once for the full
label universe and reuse or subset the returned table across figures.
The `sc_encoding` and `conflicts` attributes record the method,
settings, pools, and conflicting pairs; save the object as RDS if those
attributes must persist, because ordinary data-frame CSV export does not
retain them.

## Examples

``` r
colors <- c(A = "#0072B2", B = "#0072B2", C = "#D55E00")
sc_redundant_encoding(colors, channel = "shape")
#>   label   color encoding_group texture_group shape pattern conflict_count
#> 1     A #0072B2              1             1    16    none              1
#> 2     B #0072B2              2             2    17    none              1
#> 3     C #D55E00              1             1    16    none              0
```
