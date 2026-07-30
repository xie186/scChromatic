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

An `sc_color_map`.

## Examples

``` r
sc_highlight_map(c("B", "T", "NK"), focus = c("B", "NK"))
#> <sc_color_map[3]> palette: highlight:okabe_ito; background: light
#>   B: #E69F00
#>   NK: #56B4E9
#>   T: #D9D9D9
```
