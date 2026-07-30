# Extract named colors from a persistent map

Extract named colors from a persistent map

## Usage

``` r
as_named_colors(x)
```

## Arguments

- x:

  An `sc_color_map`.

## Value

A named hexadecimal character vector.

## Examples

``` r
as_named_colors(sc_color_map(c("B", "T")))
#>         B         T 
#> "#475D8F" "#E3B54E" 
```
