# Retrieve colors from a registered palette

Fixed qualitative palettes are truncated but never interpolated. Use
`extend = "generate"` to deterministically append colors while
preserving all selected registered colors. Continuous palettes are
interpolated in Lab space.

## Usage

``` r
sc_palette(
  palette,
  n = NULL,
  alpha = 1,
  reverse = FALSE,
  selection = c("priority", "source"),
  extend = c("error", "generate"),
  background = c("light", "dark"),
  keep_names = FALSE
)
```

## Arguments

- palette:

  Palette ID. See
  [`sc_palette_names()`](https://xie186.github.io/scChromatic/reference/sc_palette_names.md).

- n:

  Number of colors; defaults to the registered palette capacity.

- alpha:

  Opacity in `(0, 1]`.

- reverse:

  Reverse the final color sequence.

- selection:

  Use audited `"priority"` order or exact upstream `"source"` order.

- extend:

  For qualitative oversubscription, error or generate colors.

- background:

  Background used by deterministic extension.

- keep_names:

  Preserve registered color names when possible.

## Value

A character vector of hexadecimal colors.

## Examples

``` r
sc_palette("okabe_ito", 4)
#> [1] "#E69F00" "#56B4E9" "#009E73" "#F0E442"
sc_palette("archr_stallion", 6, selection = "source")
#> [1] "#D51F26" "#272E6A" "#208A42" "#89288F" "#F47D2B" "#FEE500"
```
