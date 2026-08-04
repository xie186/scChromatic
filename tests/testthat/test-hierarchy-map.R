test_that("hierarchy maps are deterministic and retain parent metadata", {
  parent <- c("Lymphoid", "Lymphoid", "Lymphoid", "Myeloid", "Myeloid")
  child <- c("B", "T", "NK", "Mono", "DC")
  first <- suppressWarnings(sc_hierarchy_map(parent, child))
  second <- suppressWarnings(sc_hierarchy_map(parent, child))
  expect_identical(as_named_colors(first), as_named_colors(second))
  expect_identical(
    unname(first$parent[c("B", "T", "NK")]),
    rep("Lymphoid", 3)
  )
  expect_identical(unname(first$parent[c("DC", "Mono")]), rep("Myeloid", 2))

  reordered <- suppressWarnings(sc_hierarchy_map(rev(parent), rev(child)))
  expect_identical(as_named_colors(reordered), as_named_colors(first))
  expect_identical(reordered$parent_anchors, first$parent_anchors)
})

test_that("a child cannot belong to multiple parents", {
  expect_error(
    sc_hierarchy_map(c("Lymphoid", "Myeloid"), c("DC", "DC")),
    "one non-missing parent"
  )
})

test_that("hierarchy extension never recolors established children or anchors", {
  initial <- suppressWarnings(sc_hierarchy_map(
    c("Lymphoid", "Myeloid"), c("B", "Mono"), separation = "within_lineage"
  ))
  initial$aliases <- c("B cell" = "B")
  extended <- suppressWarnings(sc_hierarchy_map(
    c("Epithelial", "Lymphoid", "Myeloid", "Stromal"),
    c("Epithelial cell", "T", "DC", "Fibroblast"),
    existing = initial
  ))

  expect_identical(
    as_named_colors(extended)[names(as_named_colors(initial))],
    as_named_colors(initial)
  )
  expect_identical(
    extended$parent_anchors[names(initial$parent_anchors)],
    initial$parent_anchors
  )
  expect_identical(extended$separation, "within_lineage")
  expect_identical(extended$aliases, initial$aliases)
  expect_identical(unname(extended$parent[["T"]]), "Lymphoid")
  expect_identical(unname(extended$parent[["Fibroblast"]]), "Stromal")
  expect_false(any(
    unname(as_named_colors(extended)[c("T", "DC", "Fibroblast", "Epithelial cell")]) %in%
      unname(extended$parent_anchors)
  ))
  expect_false(
    extended$parent_anchors[["Epithelial"]] %in%
      c(unname(initial$parent_anchors), unname(as_named_colors(initial)))
  )

  for (extension in c(".json", ".csv")) {
    path <- tempfile(fileext = extension)
    write_sc_color_map(extended, path)
    restored <- read_sc_color_map(path)
    expect_identical(as_named_colors(restored), as_named_colors(extended))
    expect_identical(restored$parent, extended$parent)
    expect_identical(restored$parent_anchors, extended$parent_anchors)
    expect_identical(restored$aliases, extended$aliases)

    restored_extended <- suppressWarnings(sc_hierarchy_map(
      "Lymphoid", "NK", existing = restored
    ))
    expect_identical(
      as_named_colors(restored_extended)[names(as_named_colors(restored))],
      as_named_colors(restored)
    )
    expect_identical(
      restored_extended$parent_anchors[names(restored$parent_anchors)],
      restored$parent_anchors
    )
  }
})

test_that("hierarchy extension requires parents and rejects relationship changes", {
  map <- suppressWarnings(sc_hierarchy_map("Lymphoid", "B"))
  expect_error(
    update_sc_color_map(map, c("B", "T")),
    "require a parent"
  )
  expect_error(
    sc_hierarchy_map("Myeloid", "B", existing = map),
    "one non-missing parent"
  )
  expect_error(
    sc_hierarchy_map("Lymphoid", "T", separation = "within_lineage", existing = map),
    "cannot change"
  )
})
