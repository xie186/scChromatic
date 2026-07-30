# Generate a deterministic qualitative color sequence

Extends an optional fixed set without changing its colors. Candidates
are ranked by their worst CIE2000 separation under normal, deutan,
protan, and tritan simulations. The result is diagnostic and is not a
guarantee of universal color-vision-deficiency safety.

## Usage

``` r
sc_palette_generate(
  n,
  seed_colors = character(),
  background = c("light", "dark")
)
```

## Arguments

- n:

  Number of colors.

- seed_colors:

  Optional colors that must remain at the start.

- background:

  Background for candidate scoring, `"light"` or `"dark"`.

## Value

A hexadecimal color vector.

## Examples

``` r
sc_palette_generate(6, seed_colors = c("#0072B2", "#D55E00"))
#> [1] "#0072B2" "#D55E00" "#00DCC6" "#8B4D49" "#FFA270" "#BCADFF"
```
