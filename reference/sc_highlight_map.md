# Create a focus-versus-other color map

Create a focus-versus-other color map

## Usage

``` r
sc_highlight_map(
  labels,
  focus,
  focus_palette = "okabe_ito",
  other = "grey85",
  background = c("light", "dark")
)
```

## Arguments

- labels:

  All labels.

- focus:

  Labels to highlight.

- focus_palette:

  Qualitative palette for focused labels.

- other:

  Muted color for nonfocused labels.

- background:

  Light or dark background.

## Value

An `sc_color_map` whose focus and muted-color metadata are retained by
JSON and CSV serialization.

## Examples

``` r
sc_highlight_map(c("B", "T", "NK"), focus = c("B", "NK"))
#> <sc_color_map[3]> type: highlight; palette: highlight:okabe_ito; background: light; schema: v1
#>   B: #E69F00
#>   NK: #56B4E9
#>   T: #D9D9D9
```
