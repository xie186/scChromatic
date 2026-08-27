# Optimize a persistent color map from label relationships

Treats `relationship` as a symmetric affinity matrix: `1` asks related
labels to use perceptually closer (but still distinct) colors, while `0`
asks unrelated labels to be farther apart. The diagonal is ignored.
Off-diagonal entries must contain finite values in `[0, 1]`; row and
column labels must be identical.

## Usage

``` r
sc_relationship_map(
  relationship,
  canonical = NULL,
  locked = character(),
  stability_budget = 0L,
  seed = 1L,
  cvd = c("deutan", "protan", "tritan"),
  background = c("light", "dark"),
  na.value = "#BDBDBD"
)
```

## Arguments

- relationship:

  Symmetric numeric affinity matrix whose off-diagonal entries lie in
  `[0, 1]`, with the same unique, non-empty row and column names.
  Diagonal values are ignored.

- canonical:

  Optional `sc_color_map` or fully named color vector. Its labels must
  be a subset of the matrix labels.

- locked:

  Additional canonical labels that may never change, supplied as names
  or a named logical vector. These are combined with locks already in a
  canonical `sc_color_map`.

- stability_budget:

  Maximum number of non-locked canonical colors that may change. The
  default preserves every canonical assignment.

- seed:

  Non-negative integer controlling label and candidate search order.

- cvd:

  Vision simulations used with normal vision. Values may come from
  `"none"`, `"deutan"`, `"protan"`, and `"tritan"`.

- background:

  Background used for candidate generation and initialization.

- na.value:

  Color used for missing labels.

## Value

A derived `sc_color_map` with locks, stability accounting, optimizer
context, effective relationship input, canonical baseline, and
provenance.

## Details

The method fits normal-vision CIE2000 distance to the affinity-derived
target `8 + 32 * (1 - affinity)`. A separate penalty applies when the
worst distance across normal vision and requested CVD simulations falls
below that target. Distances above 40 are treated as equivalent. This is
a deterministic, seeded heuristic and a diagnostic accessibility aid,
not a guarantee of universal CVD safety.

Canonical colors form the baseline. Hard-locked colors never change;
`stability_budget` is the maximum number of other canonical assignments
that may change when doing so strictly improves the objective. New
labels do not consume the budget. The normalized effective relationship
input, baseline, method settings, outcome, seed, and provenance are
stored in the returned map. Construction provenance remains immutable
when a map is subset; rerun this function to calculate metrics for a
different label set. Matrices returned by
[`sc_relationship_from_knn()`](https://xie186.github.io/scChromatic/reference/sc_relationship_from_knn.md)
also carry their coordinate-construction settings and pairwise sample
support into the map.

## Examples

``` r
affinity <- matrix(
  c(1, .9, .1, .9, 1, .2, .1, .2, 1), nrow = 3,
  dimnames = list(c("CD4 T", "CD8 T", "B"), c("CD4 T", "CD8 T", "B"))
)
canonical <- sc_color_map(c("CD4 T", "B"))
map <- sc_relationship_map(affinity, canonical, locked = "B", seed = 42)
as_named_colors(map)
#>         B     CD4 T     CD8 T 
#> "#475D8F" "#E3B54E" "#B49762" 
```
