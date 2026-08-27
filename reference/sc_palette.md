# Retrieve colors from a registered palette

Fixed qualitative palettes are truncated but never interpolated. Use
`extend = "generate"` to deterministically append colors while
preserving all selected registered colors. Continuous palettes preserve
their registered anchors at the native length and otherwise interpolate
in Lab space. The cyclic `d3_rainbow` compatibility palette is sampled
directly at `i / n`, so its colors intentionally change when `n`
changes.

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
sc_palette("chromatic_balance", 9)
#> [1] "#0054A3" "#547BB4" "#8FA3C8" "#C3CBDD" "#F1F1F1" "#E0C5C5" "#CB9596"
#> [8] "#B16466" "#932D33"
```
