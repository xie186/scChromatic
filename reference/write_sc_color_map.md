# Write a persistent color map

JSON files follow the installed `sc-color-map.schema.json` schema. CSV
files keep transparent `label` and `color` rows and store the same
complete, schema-versioned JSON payload in one metadata row, so neither
format loses hierarchy, focus, provenance, locks, aliases, history,
context, seed, or future JSON-compatible metadata fields.

## Usage

``` r
write_sc_color_map(map, path)
```

## Arguments

- map:

  An `sc_color_map`.

- path:

  Output `.json` or `.csv` path.

## Value

`path`, invisibly.

## Examples

``` r
if (FALSE) { # interactive()
path <- tempfile(fileext = ".csv")
write_sc_color_map(sc_color_map(c("B", "T")), path)
}
```
