# Create a scales-compatible ArchR palette

ArchR colors are frozen from commit
`6feec354ad6c8052ddbc4626a2ca2d858ed465bf`.

## Usage

``` r
pal_archr(
  palette = "stallion",
  alpha = 1,
  reverse = FALSE,
  selection = c("priority", "source")
)
```

## Arguments

- palette:

  Original ArchR palette name.

- alpha:

  Opacity in `(0, 1]`.

- reverse:

  Reverse the color order.

- selection:

  Use audited priority order or literal source order.

## Value

A closure accepting the number of colors.

## Examples

``` r
pal_archr("stallion")(5)
#> [1] "#D51F26" "#272E6A" "#208A42" "#89288F" "#F47D2B"
```
