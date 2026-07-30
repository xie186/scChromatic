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
})

test_that("a child cannot belong to multiple parents", {
  expect_error(
    sc_hierarchy_map(c("Lymphoid", "Myeloid"), c("DC", "DC")),
    "one non-missing parent"
  )
})
