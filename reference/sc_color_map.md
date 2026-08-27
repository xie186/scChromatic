# Create a persistent label-to-color mapping

Character labels use natural ordering by default. For factors,
`order = "factor"` includes all declared levels, including unused
levels. Existing assignments are retained exactly and new labels receive
unused colors deterministically. Supplying an existing map with
`palette = "auto"` also preserves its schema metadata and does not
require its palette to be registered.

## Usage

``` r
sc_color_map(
  labels,
  palette = "auto",
  existing = NULL,
  order = c("factor", "natural", "appearance"),
  extend = c("generate", "error"),
  background = c("light", "dark"),
  na.value = "#BDBDBD"
)
```

## Arguments

- labels:

  One or more non-missing, non-empty character or factor labels.

- palette:

  Registered qualitative palette ID or `"auto"`.

- existing:

  Existing named colors or an `sc_color_map`.

- order:

  Factor-level, natural, or first-appearance ordering.

- extend:

  Generate colors or error when capacity is exceeded.

- background:

  Light or dark background.

- na.value:

  Color used for missing labels.

## Value

An object of class `sc_color_map` using the current versioned map
schema.

## Examples

``` r
map <- sc_color_map(c("B", "T", "NK", "Mono"))
as_named_colors(map)
#>         B      Mono        NK         T 
#> "#475D8F" "#E3B54E" "#00DADF" "#765A11" 
```
