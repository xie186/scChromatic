# Create a scales-compatible scChromatic palette

Create a scales-compatible scChromatic palette

## Usage

``` r
sc_pal(
  palette = "chromatic",
  alpha = 1,
  reverse = FALSE,
  selection = c("priority", "source"),
  extend = c("error", "generate"),
  background = c("light", "dark")
)
```

## Arguments

- palette:

  Palette ID. See
  [`sc_palette_names()`](https://xie186.github.io/scChromatic/reference/sc_palette_names.md).

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

## Value

A closure accepting the number of colors.

## Examples

``` r
pal <- sc_pal("chromatic")
pal(5)
#> [1] "#475D8F" "#E3B54E" "#00DADF" "#765A11" "#009685"
```
