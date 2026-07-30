# Write a persistent color map

JSON is used for a `.json` path when jsonlite is installed; otherwise a
transparent two-column CSV is written.

## Usage

``` r
write_sc_color_map(map, path)
```

## Arguments

- map:

  An `sc_color_map`.

- path:

  Output path.

## Value

`path`, invisibly.

## Examples

``` r
if (FALSE) { # interactive()
path <- tempfile(fileext = ".csv")
write_sc_color_map(sc_color_map(c("B", "T")), path)
}
```
