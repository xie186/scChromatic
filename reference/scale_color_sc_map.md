# Manual ggplot2 scales from a persistent color map

These scales use the exact named assignments stored in `map`;
assignments are never recomputed from the plotted subset.

## Usage

``` r
scale_color_sc_map(map, ..., drop = TRUE)

scale_colour_sc_map(map, ..., drop = TRUE)

scale_fill_sc_map(map, ..., drop = TRUE)
```

## Arguments

- map:

  An `sc_color_map`.

- ...:

  Passed to
  [`ggplot2::scale_color_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html)
  or
  [`ggplot2::scale_fill_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html).

- drop:

  Drop unused factor levels from the scale.

## Value

A ggplot2 scale.

## Details

Use the color or colour variant for points, lines, text, and geometry
outlines mapped with `color`. Use the fill variant for geometry
interiors mapped with `fill`, such as violins, bars, tiles, and
polygons. The `scale_colour_*()` spelling is an exact alias of
`scale_color_*()`. For a one-off categorical plot that does not require
locked assignments, use the `_sc_d()` family; for numeric gradients, use
`_sc_c()`.

## Examples

``` r
map <- sc_color_map(c("B", "T", "NK"))
ggplot2::ggplot(
  data.frame(x = 1:2, y = 1:2, cell = c("T", "NK")),
  ggplot2::aes(x, y, color = cell)
) + ggplot2::geom_point() + scale_color_sc_map(map)
```
