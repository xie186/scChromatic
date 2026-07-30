# List registered palette IDs

List registered palette IDs

## Usage

``` r
sc_palette_names(type = NULL, use = NULL, source = NULL, status = NULL)
```

## Arguments

- type:

  Optional palette type.

- use:

  Optional intended-use string.

- source:

  Optional source.

- status:

  Optional status.

## Value

A character vector of palette IDs.

## Examples

``` r
sc_palette_names(type = "qualitative")
#>  [1] "archr_stallion"      "archr_stallion2"     "archr_calm"         
#>  [4] "archr_kelly"         "archr_bear"          "archr_iron_man"     
#>  [7] "archr_circus"        "archr_paired"        "archr_grove"        
#> [10] "archr_summer_night"  "archr_zissou"        "archr_darjeeling"   
#> [13] "archr_rushmore"      "archr_captain"       "okabe_ito"          
#> [16] "tol_bright"          "tol_vibrant"         "tol_muted"          
#> [19] "tol_medium_contrast" "glasbey32"           "polychrome36"       
#> [22] "ditto40"             "chromatic"          
```
