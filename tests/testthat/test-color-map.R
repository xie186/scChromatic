test_that("mapping is independent of character label order", {
  a <- sc_color_map(c("B", "T", "NK", "Mono"))
  b <- sc_color_map(c("Mono", "NK", "T", "B"))
  expect_identical(as_named_colors(a), as_named_colors(b))
})

test_that("factors use declared levels including unused levels", {
  labels <- factor(c("T", "B"), levels = c("B", "T", "NK"))
  map <- sc_color_map(labels, order = "factor")
  expect_identical(names(as_named_colors(map)), c("B", "T", "NK"))
})

test_that("subsets and updates preserve assignments", {
  labels_full <- c("B", "T", "NK", "Mono")
  map <- sc_color_map(labels_full, palette = "archr_stallion")

  labels_subset <- c("T", "NK")
  subset_colors <- as_named_colors(map)[labels_subset]
  expect_identical(
    subset_colors,
    as_named_colors(map)[c("T", "NK")]
  )

  updated <- update_sc_color_map(map, c(labels_full, "DC"))
  expect_identical(
    as_named_colors(updated)[names(as_named_colors(map))],
    as_named_colors(map)
  )
})

test_that("existing mappings require unique names", {
  expect_error(sc_color_map("B", existing = "#000000"), "fully named")
  duplicate <- c(B = "#000000", B = "#FFFFFF")
  expect_error(sc_color_map("B", existing = duplicate), "duplicate")
})

test_that("JSON and CSV round trips preserve names and hex values", {
  map <- sc_color_map(c("B", "T", "NK"))
  for (extension in c(".json", ".csv")) {
    path <- tempfile(fileext = extension)
    write_sc_color_map(map, path)
    restored <- read_sc_color_map(path)
    expect_identical(as_named_colors(restored), as_named_colors(map))
  }
})

test_that("map subsetting retains class and exact assignments", {
  map <- sc_color_map(c("B", "T", "NK"))
  subset <- map[c("T", "NK")]
  expect_s3_class(subset, "sc_color_map")
  expect_identical(as_named_colors(subset), as_named_colors(map)[c("T", "NK")])
})
