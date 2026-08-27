# Plot a persistent color map

Displays each mapped label alongside its color swatch and hexadecimal
code.

## Usage

``` r
sc_color_map_plot(x)
```

## Arguments

- x:

  An `sc_color_map`.

## Value

A ggplot object.

## Examples

``` r
cell_map <- sc_color_map(c("B", "T", "NK"))
sc_color_map_plot(cell_map)
```
