# Discrete scChromatic color scale

Use the color or colour variant for variables mapped to the `color`
aesthetic, and the fill variant for variables mapped to `fill`. These
scales assign colors from the discrete levels supplied to the plot. Use
[`scale_color_sc_map()`](https://xie186.github.io/scChromatic/reference/scale_color_sc_map.md)
or
[`scale_fill_sc_map()`](https://xie186.github.io/scChromatic/reference/scale_color_sc_map.md)
instead when exact category assignments must remain stable across plots
and subsets; use the `_sc_c()` family for numeric gradients.

## Usage

``` r
scale_color_sc_d(
  palette = "auto",
  alpha = 1,
  reverse = FALSE,
  selection = c("priority", "source"),
  extend = c("error", "generate"),
  background = c("light", "dark"),
  ...
)

scale_colour_sc_d(
  palette = "auto",
  alpha = 1,
  reverse = FALSE,
  selection = c("priority", "source"),
  extend = c("error", "generate"),
  background = c("light", "dark"),
  ...
)

scale_fill_sc_d(
  palette = "auto",
  alpha = 1,
  reverse = FALSE,
  selection = c("priority", "source"),
  extend = c("error", "generate"),
  background = c("light", "dark"),
  ...
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

- ...:

  Passed to
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html).

## Examples

``` r
ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), mpg, color = factor(cyl))) +
  ggplot2::geom_point() + scale_color_sc_d()
```
