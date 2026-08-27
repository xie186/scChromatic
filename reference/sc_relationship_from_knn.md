# Derive label relationships from coordinate neighborhoods

Builds an exact Euclidean k-nearest-neighbor graph within each sample,
then converts directed cell-level edges into symmetric label affinities.
For a label pair `i, j`, affinity is the mean of the directed neighbor
probabilities `p(j | i)` and `p(i | j)`. Values therefore lie in
`[0, 1]`.

## Usage

``` r
sc_relationship_from_knn(
  coordinates,
  labels,
  sample = NULL,
  k = 15L,
  aggregate = c("mean", "median"),
  unobserved = c("error", "zero")
)
```

## Arguments

- coordinates:

  Numeric matrix or all-numeric data frame with observations in rows and
  coordinate dimensions in columns.

- labels:

  Character or factor label for every row.

- sample:

  Optional character or factor sample identifier for every row.
  Neighbors are found within samples. `NULL` treats all rows as one
  sample.

- k:

  Requested number of neighbors. It is reduced to `n - 1` within samples
  containing fewer than `k + 1` rows.

- aggregate:

  Equal-sample aggregation, either `"mean"` or `"median"`.

- unobserved:

  How to handle label pairs never observed together in any sample: error
  or explicitly assign zero affinity.

## Value

A symmetric numeric affinity matrix with an `sc_context` attribute
containing construction provenance and pairwise sample support.

## Details

Sample matrices receive equal weight, irrespective of cell count. A pair
is aggregated only across samples containing both labels. By default,
pairs never observed together are reported as an error;
`unobserved = "zero"` explicitly treats them as unrelated. The returned
numeric matrix can be passed directly to
[`sc_relationship_map()`](https://xie186.github.io/scChromatic/reference/sc_relationship_map.md).
Its construction settings and pairwise sample support are carried into
that map's provenance.

Coordinate distance should be scientifically meaningful. PCA, a model
latent space, or spatial coordinates are usually preferable to UMAP when
quantitative distances matter. The resulting affinities depend on label
prevalence, local density, coordinate scaling, and `k`; they are context
summaries rather than direct evidence of biological similarity. Raw
coordinates, row names, and sample identifiers are not stored in the
returned provenance; only fingerprints and aggregate summaries are
retained.

## Examples

``` r
coordinates <- matrix(c(0, .1, .2, .3, 2, 2.1, 4, 4.1), ncol = 1)
labels <- rep(c("A", "B"), 4)
samples <- rep(c("s1", "s2"), each = 4)
relationship <- sc_relationship_from_knn(
  coordinates, labels, samples, k = 1
)
sc_relationship_map(relationship, seed = 1)
#> <sc_color_map[2]> type: derived; palette: derived:relationship-v1; background: light; schema: v1
#>   A: #25638B
#>   B: #005CC0
```
