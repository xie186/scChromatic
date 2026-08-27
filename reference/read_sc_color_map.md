# Read a persistent color map

Versioned JSON and CSV files are validated before object construction.
Unversioned JSON files and legacy two-column CSV files written by
scChromatic 0.1.0 remain readable and are migrated to schema version 1.
Unknown future schema versions are rejected rather than guessed.

## Usage

``` r
read_sc_color_map(path)
```

## Arguments

- path:

  JSON or CSV path written by
  [`write_sc_color_map()`](https://xie186.github.io/scChromatic/reference/write_sc_color_map.md).

## Value

A validated `sc_color_map` using the current schema version.

## Examples

``` r
if (FALSE) { # interactive()
path <- tempfile(fileext = ".csv")
write_sc_color_map(sc_color_map(c("B", "T")), path)
read_sc_color_map(path)
}
```
