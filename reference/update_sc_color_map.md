# Update a persistent color map

Existing assignments and all map metadata are preserved. Registered maps
reuse their qualitative palette; external and derived maps are extended
from their stored colors and therefore do not need a palette-registry
entry. Hierarchy maps must instead be extended with
[`sc_hierarchy_map()`](https://xie186.github.io/scChromatic/reference/sc_hierarchy_map.md)
so every new child has a parent.

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

  Generate or error when capacity is exceeded.

## Value

An updated `sc_color_map` using the same schema and metadata.

## Examples

``` r
map <- sc_color_map(c("B", "T"))
update_sc_color_map(map, c("B", "T", "NK"))
#> <sc_color_map[3]> type: registered; palette: chromatic; background: light; schema: v1
#>   B: #475D8F
#>   T: #E3B54E
#>   NK: #00DADF
```
