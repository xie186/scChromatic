test_that("coordinate kNN affinities are exact, tie-stable, and order invariant", {
  coordinates <- matrix(c(-1, 0, 1), ncol = 1)
  labels <- c("A", "B", "C")

  affinity <- sc_relationship_from_knn(coordinates, labels, k = 1)
  expected <- matrix(
    c(1, .75, 0, .75, 1, .75, 0, .75, 1), nrow = 3,
    dimnames = list(c("A", "B", "C"), c("A", "B", "C"))
  )
  expect_equal(affinity[, ], expected)

  permutation <- c(3, 1, 2)
  reordered <- sc_relationship_from_knn(
    coordinates[permutation, , drop = FALSE], labels[permutation], k = 1
  )
  translated <- sc_relationship_from_knn(coordinates + 1e9, labels, k = 1)
  expect_identical(affinity[, ], reordered[, ])
  expect_identical(affinity[, ], translated[, ])

  decimal_coordinates <- matrix(c(-.3, 0, .3), ncol = 1)
  decimal <- sc_relationship_from_knn(decimal_coordinates, labels, k = 1)
  decimal_reordered <- sc_relationship_from_knn(
    decimal_coordinates[permutation, , drop = FALSE],
    labels[permutation], k = 1
  )
  expect_identical(decimal[, ], decimal_reordered[, ])
  expect_identical(
    attr(affinity, "sc_context")$tie_rule,
    "include_all_neighbors_at_kth_distance"
  )
})

test_that("multi-sample aggregation gives samples equal weight", {
  coordinates <- matrix(c(
    0, .1, .2, .3,
    0, .1, .2, .3, 10, 10.1, 10.2, 10.3,
    0, 10, .1, 10.1
  ), ncol = 1, dimnames = list(NULL, "latent1"))
  labels <- c(
    "A", "B", "A", "B",
    rep("A", 4), rep("B", 4),
    "A", "B", "A", "B"
  )
  sample <- c(rep("s1", 4), rep("s2", 8), rep("s3", 4))

  mean_affinity <- sc_relationship_from_knn(
    coordinates, labels, sample, k = 1, aggregate = "mean"
  )
  median_affinity <- sc_relationship_from_knn(
    coordinates, labels, sample, k = 1, aggregate = "median"
  )

  expect_equal(mean_affinity["A", "B"], 1 / 3)
  expect_identical(median_affinity["A", "B"], 0)
  context <- attr(mean_affinity, "sc_context")
  expect_identical(context$method, "coordinate-knn-v1")
  expect_identical(context$sample_weighting, "equal")
  expect_identical(context$coordinate_names, "latent1")
  expect_identical(
    context$sample_cell_count_summary,
    list(min = 4L, median = 4L, max = 8L)
  )
  expect_identical(
    context$effective_k_summary,
    list(min = 1L, median = 1L, max = 1L)
  )
  expect_identical(context$sample_identifiers, "not_stored")
  expect_identical(context$pair_support$sample_count, 3L)
  expect_match(context$input_md5, "^[0-9a-f]{32}$")
  expect_match(context$matrix_md5, "^[0-9a-f]{32}$")
  expect_match(context$context_md5, "^[0-9a-f]{32}$")
  expect_null(context$coordinates)
  expect_false(grepl("s1|s2|s3", jsonlite::toJSON(context)))
})

test_that("unobserved label pairs require an explicit policy", {
  coordinates <- matrix(c(0, 1, 0, 1), ncol = 1)
  labels <- c("A", "B", "B", "C")
  sample <- c("s1", "s1", "s2", "s2")

  expect_error(
    sc_relationship_from_knn(coordinates, labels, sample, k = 1),
    "No sample jointly observes"
  )
  affinity <- sc_relationship_from_knn(
    coordinates, labels, sample, k = 1, unobserved = "zero"
  )
  expect_identical(affinity["A", "C"], 0)
  context <- attr(affinity, "sc_context")
  expect_identical(context$unobserved, "zero")
  expect_identical(context$zero_filled_pairs$label1, "A")
  expect_identical(context$zero_filled_pairs$label2, "C")
  expect_identical(
    context$pair_support$sample_count,
    c(1L, 0L, 1L)
  )
})

test_that("coordinate relationship inputs are validated", {
  expect_error(
    sc_relationship_from_knn(data.frame(x = 1:2, id = letters[1:2]), c("A", "B")),
    "Every column"
  )
  expect_error(
    sc_relationship_from_knn(matrix(1:4, ncol = 1), rep("A", 4)),
    "at least two observed labels"
  )
  expect_error(
    sc_relationship_from_knn(matrix(1:4, ncol = 1), c("A", "B")),
    "one character or factor value per row"
  )
  expect_error(
    sc_relationship_from_knn(
      matrix(1:4, ncol = 1), c("A", "B", "A", "B"),
      sample = c("s1", "s1", NA, "s2")
    ),
    "must not contain missing"
  )
  expect_error(
    sc_relationship_from_knn(
      matrix(1:4, ncol = 1), c("A", "B", "A", "B"), k = 0
    ),
    "positive whole number"
  )
  expect_error(
    sc_relationship_from_knn(
      matrix(1:4, ncol = 1), c("A", "B", "A", "B"),
      k = .Machine$integer.max + 1
    ),
    "positive whole number"
  )
  expect_error(
    sc_relationship_from_knn(
      matrix(c(-1e308, 1e308), ncol = 1), c("A", "B"), k = 1
    ),
    "overflowed.*rescale"
  )
})

test_that("coordinate derivation provenance survives relationship maps", {
  affinity <- sc_relationship_from_knn(
    matrix(c(-1, 0, 1), ncol = 1), c("A", "B", "C"), k = 1
  )
  derivation <- attr(affinity, "sc_context")
  map <- sc_relationship_map(affinity, seed = 17)

  expect_identical(map$context$relationship_source, "coordinate-knn-v1")
  expect_identical(map$metadata$relationship_input$derivation, derivation)
  expect_true(any(vapply(
    map$provenance,
    function(x) identical(x$source_palette, "coordinate-knn-v1"),
    logical(1)
  )))

  ignored_diagonal <- affinity
  diag(ignored_diagonal) <- NA_real_
  expect_s3_class(
    sc_relationship_map(ignored_diagonal, seed = 17), "sc_color_map"
  )

  for (extension in c(".json", ".csv")) {
    path <- tempfile(fileext = extension)
    write_sc_color_map(map, path)
    restored <- read_sc_color_map(path)
    expect_identical(restored$context, map$context)
    expect_identical(restored$metadata, map$metadata)
    expect_identical(restored$provenance, map$provenance)
  }

  tampered <- affinity
  tampered["A", "C"] <- tampered["C", "A"] <- .25
  expect_error(
    sc_relationship_map(tampered, seed = 17),
    "provenance|fingerprint|modified"
  )

  tampered_context <- affinity
  attr(tampered_context, "sc_context")$aggregation <- "median"
  expect_error(
    sc_relationship_map(tampered_context, seed = 17),
    "context metadata.*modified"
  )
})

test_that("redundant encodings preserve colors and separate conflicts", {
  colors <- c(C = "#D55E00", A = "#0072B2", B = "#0072B2")

  shape <- sc_redundant_encoding(
    colors, channel = "shape", min_cie2000 = 1, cvd = "none"
  )
  expect_identical(
    names(shape),
    c(
      "label", "color", "encoding_group", "texture_group", "shape",
      "pattern", "conflict_count"
    )
  )
  expect_identical(shape$label, c("A", "B", "C"))
  expect_identical(shape$color, unname(colors[c("A", "B", "C")]))
  expect_false(shape$shape[shape$label == "A"] == shape$shape[shape$label == "B"])
  expect_true(all(shape$pattern == "none"))
  expect_identical(shape$conflict_count, c(1L, 1L, 0L))
  metadata <- attr(shape, "sc_encoding")
  expect_identical(metadata$method, "cvd-conflict-dsatur-v1")
  expect_identical(metadata$cvd, "none")
  expect_identical(metadata$conflict_count, 1L)
  expect_match(metadata$input_md5, "^[0-9a-f]{32}$")
  conflicts <- attr(shape, "conflicts")
  expect_identical(conflicts$label1, "A")
  expect_identical(conflicts$label2, "B")
  expect_identical(
    sc_redundant_encoding(
      colors, channel = "shape", min_cie2000 = 1, cvd = "none"
    ),
    shape
  )

  pattern <- sc_redundant_encoding(
    colors, channel = "pattern", min_cie2000 = 1, cvd = "none"
  )
  expect_false(
    pattern$pattern[pattern$label == "A"] ==
      pattern$pattern[pattern$label == "B"]
  )
  expect_true(length(unique(pattern$shape)) == 1L)

  combined <- sc_redundant_encoding(
    c(A = "#000000", B = "#000000", C = "#000000"),
    channel = "both", min_cie2000 = 1, cvd = "none",
    shapes = c(16L, 17L), patterns = c("none", "stripe")
  )
  expect_identical(length(unique(combined$encoding_group)), 3L)
})

test_that("redundant encoding validates labels, colors, and capacity", {
  expect_error(
    sc_redundant_encoding(c("#000000", "#FFFFFF"), cvd = "none"),
    "unique, non-empty label"
  )
  expect_error(
    sc_redundant_encoding(c(A = "not-a-color", B = "#FFFFFF"), cvd = "none"),
    "invalid colors"
  )
  expect_error(
    sc_redundant_encoding(
      c(A = "#000000", B = "#000000", C = "#000000"),
      channel = "shape", cvd = "none", shapes = c(16L, 17L)
    ),
    "require.*3.*provides.*2"
  )
  expect_error(
    sc_redundant_encoding(
      c(A = "#000000", B = "#FFFFFF"), cvd = "none", shapes = c(16, 26)
    ),
    "plotting shapes"
  )

  no_conflicts <- sc_redundant_encoding(
    c(A = "#000000", B = "#FFFFFF"),
    min_cie2000 = 0, cvd = "none"
  )
  expect_identical(no_conflicts$encoding_group, c(1L, 1L))
})
