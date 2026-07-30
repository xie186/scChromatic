# Recommend palettes from transparent registry rules

Ranking uses palette type, intended-use metadata, capacity, status,
background guidance, and measured CIE2000 separation. No learned model
is involved.

## Usage

``` r
sc_palette_recommend(
  n,
  use = c("cell_identity", "sample", "condition", "lineage", "expression",
    "signed_score", "pseudotime", "qc", "heatmap_annotation", "highlight"),
  geometry = c("point", "fill", "line"),
  background = c("light", "dark"),
  cvd = TRUE,
  top = 5
)
```

## Arguments

- n:

  Number of categories or gradient anchors needed.

- use:

  Single-cell visualization purpose.

- geometry:

  Point, fill, or line geometry.

- background:

  Light or dark background.

- cvd:

  Include normal/CVD minimum separation in ranking.

- top:

  Maximum rows to return.

## Value

A data frame of ranked palettes and reasons.

## Examples

``` r
sc_palette_recommend(8, use = "cell_identity")
#>        palette_id
#> 15      chromatic
#> 11      tol_muted
#> 14        ditto40
#> 10      okabe_ito
#> 1  archr_stallion
#>                                                                            reason
#> 15   qualitative; registered for this use; recommended; sufficient fixed capacity
#> 11   qualitative; registered for this use; recommended; sufficient fixed capacity
#> 14   qualitative; registered for this use; recommended; sufficient fixed capacity
#> 10   qualitative; registered for this use; recommended; sufficient fixed capacity
#> 1  qualitative; registered for this use; compatibility; sufficient fixed capacity
#>    capacity        status min_cie2000    score
#> 15       40   recommended   12.380832 83.38083
#> 11        9   recommended   11.825943 82.82594
#> 14       40   recommended   11.133033 82.13303
#> 10        8   recommended   11.133033 82.13303
#> 1        20 compatibility    7.688475 63.68848
```
