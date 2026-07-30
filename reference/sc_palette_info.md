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
sc_palette_info("archr_stallion")
#>       palette_id source source_palette palette_type max_n
#> 1 archr_stallion  ArchR       stallion  qualitative    20
#>                                                intended_use
#> 1 cell_identity,sample,condition,lineage,heatmap_annotation
#>   recommended_geometry recommended_background        status
#> 1      point,fill,line             light,dark compatibility
#>                                        source_order
#> 1 literal vector order in internal palette database
#>                                                  priority_order
#> 1 ascending numeric source labels used by ArchR paletteDiscrete
#>                                                                                                        source_url
#> 1 https://raw.githubusercontent.com/GreenleafLab/ArchR/6feec354ad6c8052ddbc4626a2ca2d858ed465bf/R/ColorPalettes.R
#>                              source_commit
#> 1 6feec354ad6c8052ddbc4626a2ca2d858ed465bf
#>                                                            citation
#> 1 Granja et al. (2021), Nature Genetics 53:403-411; ArchR software.
#>                                                          license derived
#> 1 MIT (ArchR code); individual borrowed-palette terms may differ   FALSE
#>   source_cvd_claim
#> 1             <NA>
#>                                                                          notes
#> 1 ArchR describes its collection as containing original and borrowed palettes.
#>   audit_min_cie2000 audit_min_contrast_light audit_min_contrast_dark audit_date
#> 1          8.347344                 1.278781                1.396645 2026-07-30
```
