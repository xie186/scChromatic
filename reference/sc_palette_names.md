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
#> [1] "okabe_ito"           "tol_bright"          "tol_vibrant"        
#> [4] "tol_muted"           "tol_medium_contrast" "glasbey32"          
#> [7] "polychrome36"        "ditto40"             "chromatic"          
```
