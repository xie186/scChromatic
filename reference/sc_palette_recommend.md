# Recommend palettes from transparent registry rules

Ranking uses palette type, intended-use metadata, capacity, status,
background guidance, and measured CIE2000 separation. Registered
`recommended` palettes are preferred as a group; compatibility
collections are considered only when no recommended palette meets the
qualitative separation screen. No learned model is involved. The screen
is a pragmatic diagnostic, not a universal perceptual pass/fail
threshold.

## Usage

``` r
sc_palette_recommend(
  n,
  use = c("cell_identity", "sample", "condition", "lineage", "expression",
    "signed_score", "pseudotime", "qc", "heatmap_annotation", "highlight"),
  geometry = c("point", "fill", "line"),
  background = c("light", "dark"),
  cvd = TRUE,
  top = 5,
  min_cie2000 = 0
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

- min_cie2000:

  Minimum worst-vision CIE2000 separation required for a qualitative
  recommendation. The default `0` requests a best-effort ranking without
  imposing an unvalidated perceptual pass/fail cutoff. This screen is
  not applied to continuous palettes, where neighboring gradient anchors
  are intentionally similar.

## Value

A data frame of ranked palettes and reasons.

## Examples

``` r
sc_palette_recommend(8, use = "cell_identity")
#>   palette_id
#> 6  chromatic
#> 2  tol_muted
#> 5    ditto40
#> 1  okabe_ito
#>                                                                         reason
#> 6 qualitative; registered for this use; recommended; sufficient fixed capacity
#> 2 qualitative; registered for this use; recommended; sufficient fixed capacity
#> 5 qualitative; registered for this use; recommended; sufficient fixed capacity
#> 1 qualitative; registered for this use; recommended; sufficient fixed capacity
#>   capacity      status min_cie2000    score
#> 6       40 recommended    12.38083 83.38083
#> 2        9 recommended    11.82594 82.82594
#> 5       40 recommended    11.13303 82.13303
#> 1        8 recommended    11.13303 82.13303
```
