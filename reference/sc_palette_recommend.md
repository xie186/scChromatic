# Recommend palettes from transparent registry rules

Ranking uses palette type, intended-use metadata, capacity, status,
background guidance, and measured CIE2000 separation. Registered
`recommended` palettes are preferred as a group; compatibility
collections are considered only when no recommended palette fits. No
learned model is involved.

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
#>   palette_id
#> 4  chromatic
#> 2  tol_muted
#> 3    ditto40
#> 1  okabe_ito
#>                                                                         reason
#> 4 qualitative; registered for this use; recommended; sufficient fixed capacity
#> 2 qualitative; registered for this use; recommended; sufficient fixed capacity
#> 3 qualitative; registered for this use; recommended; sufficient fixed capacity
#> 1 qualitative; registered for this use; recommended; sufficient fixed capacity
#>   capacity      status min_cie2000    score
#> 4       40 recommended    12.38083 83.38083
#> 2        9 recommended    11.82594 82.82594
#> 3       40 recommended    11.13303 82.13303
#> 1        8 recommended    11.13303 82.13303
```
