# Audit palette separation and background contrast

Contrast values are diagnostic for plotted marks and are not treated as
definitive WCAG pass/fail thresholds for small points. Fully named color
vectors retain their labels in the worst-pair diagnostics. Exact
duplicate assignments remain in the distance calculation and therefore
produce a zero-distance collision rather than being discarded.

## Usage

``` r
sc_palette_audit(
  x,
  background = "#FFFFFF",
  cvd = c("none", "deutan", "protan", "tritan"),
  method = "cie2000"
)
```

## Arguments

- x:

  Palette ID, color vector, or `sc_color_map`.

- background:

  Background color.

- cvd:

  Vision simulations to include.

- method:

  Color-distance method; currently `"cie2000"`.

## Value

An object of class `sc_palette_audit`. Its `vision` table includes the
display-ready `worst_pair` plus separate label and color columns for the
pair. Label columns are `NA` for unnamed color vectors.

## Examples

``` r
sc_palette_audit("okabe_ito", cvd = c("none", "deutan"))
#> <sc_palette_audit> okabe_ito
#>  n_colors invalid_color_count duplicate_count min_distance median_distance
#>         8                   0               0     21.72367        49.49019
#>         worst_pair min_contrast median_contrast lightness_monotonic
#>  #E69F00 / #F0E442     1.322328        3.241087                  NA
#>  diverging_center_distinct
#>                         NA
```
