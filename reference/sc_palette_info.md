# Inspect palette metadata and provenance

Inspect palette metadata and provenance

## Usage

``` r
sc_palette_info(palette)
```

## Arguments

- palette:

  Palette ID.

## Value

A one-row data frame with registry and audit metadata.

## Examples

``` r
sc_palette_info("chromatic_balance")
#>           palette_id      source    source_palette palette_type max_n
#> 10 chromatic_balance scChromatic chromatic_balance    diverging   256
#>    intended_use recommended_geometry recommended_background      status
#> 10 signed_score      point,fill,line             light,dark recommended
#>                                         source_order       priority_order
#> 10 literal vector order in internal palette database same as source order
#>                               source_url source_commit
#> 10 https://github.com/xie186/scChromatic          <NA>
#>                                                       citation    license
#> 10 Zeileis et al. (2020), Journal of Statistical Software 96:1 GPL (>= 3)
#>    derived                                                     source_cvd_claim
#> 10    TRUE Audited under common CVD simulations; no universal CVD-safety claim.
#>                                                                                                                           notes
#> 10 Frozen HCL-derived anchors generated with colorspace::diverging_hcl; blue is negative, neutral is zero, and red is positive.
#>    audit_min_cie2000 audit_min_contrast_light audit_min_contrast_dark
#> 10           9.24862                 1.129491                2.237338
#>    audit_date
#> 10 2026-07-30
```
