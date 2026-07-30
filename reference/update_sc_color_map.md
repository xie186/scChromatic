# Update a persistent color map

Update a persistent color map

## Usage

``` r
update_sc_color_map(map, labels, extend = c("generate", "error"))
```

## Arguments

- map:

  An `sc_color_map`.

- labels:

  Labels to add; prior assignments are never changed.

- extend:

  Generate or error when palette capacity is exceeded.

## Value

An updated `sc_color_map`.

## Examples

``` r
map <- sc_color_map(c("B", "T"))
update_sc_color_map(map, c("B", "T", "NK"))
#> <sc_color_map[3]> palette: chromatic; background: light
#>   B: #475D8F
#>   T: #E3B54E
#>   NK: #00DADF
```
