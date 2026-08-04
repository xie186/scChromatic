relationship_fixture <- function(labels) {
  out <- matrix(
    0, nrow = length(labels), ncol = length(labels),
    dimnames = list(labels, labels)
  )
  diag(out) <- 1
  out
}

test_that("relationship matrices have an explicit affinity contract", {
  good <- relationship_fixture(c("A", "B", "C"))

  expect_error(sc_relationship_map(unname(good)), "row and column names")
  expect_error(sc_relationship_map(good[-1, ]), "square numeric matrix")

  asymmetric <- good
  asymmetric[1, 2] <- 0.5
  expect_error(sc_relationship_map(asymmetric), "symmetric")

  outside <- good
  outside[1, 2] <- outside[2, 1] <- 1.1
  expect_error(sc_relationship_map(outside), "interval")

  missing <- good
  missing[1, 2] <- missing[2, 1] <- NA_real_
  expect_error(sc_relationship_map(missing), "finite")

  ignored_diagonal <- good
  diag(ignored_diagonal) <- NA_real_
  expect_s3_class(sc_relationship_map(ignored_diagonal, seed = 2), "sc_color_map")

  expect_error(
    sc_relationship_map(good, canonical = c(D = "#000000")),
    "absent"
  )
  expect_error(sc_relationship_map(good, stability_budget = 1), "requires")
  expect_error(sc_relationship_map(good, stability_budget = 0.5), "whole number")
  expect_error(sc_relationship_map(good, seed = -1), "non-negative")
  expect_error(sc_relationship_map(good, cvd = "unsupported"), "must contain")
  expect_error(
    sc_relationship_map(good, canonical = c(A = "#000000"), locked = "B"),
    "non-canonical"
  )
})

test_that("seeded optimization is deterministic, order invariant, and RNG neutral", {
  affinity <- relationship_fixture(c("B", "CD8 T", "Mono", "CD4 T"))
  affinity["CD4 T", "CD8 T"] <- affinity["CD8 T", "CD4 T"] <- 0.95
  affinity["CD4 T", "B"] <- affinity["B", "CD4 T"] <- 0.15
  affinity["CD8 T", "B"] <- affinity["B", "CD8 T"] <- 0.1

  set.seed(927)
  state <- .Random.seed
  kind <- RNGkind()
  first <- sc_relationship_map(affinity, seed = 19)
  expect_identical(.Random.seed, state)
  expect_identical(RNGkind(), kind)

  second <- sc_relationship_map(affinity, seed = 19)
  permutation <- c("Mono", "CD4 T", "B", "CD8 T")
  reordered <- sc_relationship_map(
    affinity[permutation, permutation], seed = 19
  )
  expect_identical(as_named_colors(first), as_named_colors(second))
  expect_identical(as_named_colors(first), as_named_colors(reordered))
  expect_identical(first$seed, 19)
})

test_that("affinity controls worst-case CVD-aware color proximity", {
  affinity <- relationship_fixture(c("Anchor", "Related", "Unrelated"))
  affinity["Anchor", "Related"] <- affinity["Related", "Anchor"] <- 1
  canonical <- c(Anchor = "#0072B2")

  map <- sc_relationship_map(
    affinity, canonical = canonical, locked = "Anchor", seed = 7
  )
  colors <- as_named_colors(map)
  normal <- .sc_pairwise_distance(unname(colors))
  dimnames(normal) <- list(names(colors), names(colors))
  robust <- .sc_relationship_distances(
    unname(colors), c("none", "deutan", "protan", "tritan")
  )
  dimnames(robust) <- list(names(colors), names(colors))

  expect_lt(normal["Anchor", "Related"], normal["Anchor", "Unrelated"])
  expect_lt(normal["Anchor", "Related"], normal["Related", "Unrelated"])
  expect_gte(robust["Anchor", "Related"], 7)
})

test_that("hard locks and the stability budget are separate invariants", {
  affinity <- relationship_fixture(c("A", "B", "C"))
  canonical <- c(A = "#FF0000", B = "#FF0101", C = "#FF0202")

  frozen <- sc_relationship_map(
    affinity, canonical = canonical, locked = "A",
    stability_budget = 0, seed = 3
  )
  expect_identical(as_named_colors(frozen), canonical)

  budgeted <- sc_relationship_map(
    affinity, canonical = canonical, locked = "A",
    stability_budget = 1, seed = 3
  )
  changed <- names(canonical)[as_named_colors(budgeted) != canonical]
  expect_identical(as_named_colors(budgeted)[["A"]], canonical[["A"]])
  expect_lte(length(changed), 1L)
  expect_identical(budgeted$context$stability_budget_used, as.integer(length(changed)))

  canonical_map <- sc_color_map(c("A", "B", "C"))
  canonical_map$locks <- c(A = TRUE, B = FALSE, C = FALSE)
  inherited <- sc_relationship_map(
    affinity, canonical = canonical_map, locked = "B",
    stability_budget = 2, seed = 4
  )
  expect_identical(
    as_named_colors(inherited)[c("A", "B")],
    as_named_colors(canonical_map)[c("A", "B")]
  )
  expect_true(inherited$locks[["A"]])
  expect_true(inherited$locks[["B"]])
  expect_false(inherited$locks[["C"]])
  expect_identical(
    head(inherited$provenance, -1L), canonical_map$provenance
  )
})

test_that("relationship construction provenance survives JSON and CSV", {
  affinity <- relationship_fixture(c("A", "B", "C"))
  affinity["A", "B"] <- affinity["B", "A"] <- 0.12345678901234566
  affinity["A", "C"] <- affinity["C", "A"] <- 0.8
  canonical <- c(A = "#0072B2", B = "#D55E00")
  map <- sc_relationship_map(
    affinity, canonical = canonical, locked = "A",
    stability_budget = 1, seed = 42
  )

  expect_identical(map$map_type, "derived")
  expect_identical(map$palette, "derived:relationship-v1")
  expect_identical(map$context$method, "relationship-v1")
  expect_identical(map$context$optimizer, "seeded-greedy-coordinate")
  expect_identical(map$context$distance, "CIEDE2000")
  expect_identical(map$context$scope, "construction")
  expect_identical(map$context$objective, "normal_fit_plus_worst_cvd_shortfall")
  expect_identical(map$context$target_formula, "8 + 32 * (1 - affinity)")
  expect_identical(map$context$cvd, c("none", "deutan", "protan", "tritan"))
  expect_match(map$context$colorspace_version, "^[0-9]+[.]")
  expect_match(map$context$farver_version, "^[0-9]+[.]")
  expect_identical(map$context$candidate_grid, "hcl-grid-v1")
  expect_identical(tail(map$provenance, 1L)[[1L]]$source_palette, "relationship-v1")
  expect_identical(
    map$metadata$relationship_input$pairs$affinity,
    as.numeric(affinity[upper.tri(affinity)])
  )
  expect_identical(
    map$metadata$canonical_baseline$assignments$label,
    names(canonical)
  )

  for (extension in c(".json", ".csv")) {
    path <- tempfile(fileext = extension)
    write_sc_color_map(map, path)
    restored <- read_sc_color_map(path)
    for (field in names(map)) {
      expect_identical(restored[[field]], map[[field]], info = field)
    }
  }

  subset <- map[c("A", "B")]
  expect_identical(subset$context$scope, "construction")
  expect_identical(
    subset$metadata$relationship_input$labels,
    map$metadata$relationship_input$labels
  )
})

test_that("whole-valued construction metadata round trips exactly", {
  affinity <- relationship_fixture(c("A", "B"))
  canonical <- c(A = "#000000", B = "#000000")
  map <- sc_relationship_map(affinity, canonical = canonical, seed = 5)
  expect_type(map$metadata$relationship_input$pairs$affinity, "integer")
  expect_type(map$context$minimum_worst_case_cie2000, "integer")

  for (extension in c(".json", ".csv")) {
    path <- tempfile(fileext = extension)
    write_sc_color_map(map, path)
    restored <- read_sc_color_map(path)
    expect_identical(restored$context, map$context)
    expect_identical(restored$history, map$history)
    expect_identical(restored$metadata, map$metadata)
  }
})

test_that("relationship maps cannot be extended without a new matrix", {
  affinity <- relationship_fixture(c("A", "B"))
  map <- sc_relationship_map(affinity, seed = 1)
  expect_error(
    update_sc_color_map(map, c("A", "B", "C")),
    "expanded matrix"
  )
})
