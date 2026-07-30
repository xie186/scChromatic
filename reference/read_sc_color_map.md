# Read a persistent color map

Read a persistent color map

## Usage

``` r
read_sc_color_map(path)
```

## Arguments

- path:

  JSON or CSV path written by
  [`write_sc_color_map()`](https://xie186.github.io/scChromatic/reference/write_sc_color_map.md).

## Value

An `sc_color_map`.

## Examples

``` r
if (FALSE) { # interactive()
path <- tempfile(fileext = ".csv")
write_sc_color_map(sc_color_map(c("B", "T")), path)
read_sc_color_map(path)
}
```
