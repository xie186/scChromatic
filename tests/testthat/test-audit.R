test_that("audit includes every requested vision mode", {
  modes <- c("none", "deutan", "protan", "tritan")
  audit <- sc_palette_audit("okabe_ito", cvd = modes)
  expect_s3_class(audit, "sc_palette_audit")
  expect_setequal(audit$vision$vision, modes)
  expect_true(all(c(
    "min_distance", "median_distance", "worst_pair", "worst_label_1",
    "worst_label_2", "worst_color_1", "worst_color_2"
  ) %in% names(audit$vision)))
  expect_true(all(c(
    "min_contrast", "median_contrast", "lightness_monotonic",
    "diverging_center_distinct"
  ) %in% names(audit$summary)))
})

test_that("invalid and duplicate colors are reported", {
  audit <- sc_palette_audit(c("#000000", "#000000", "not-a-color"), cvd = "none")
  expect_identical(audit$summary$invalid_color_count, 1L)
  expect_identical(audit$summary$duplicate_count, 1L)
  expect_identical(audit$summary$min_distance, 0)
})

test_that("worst pairs retain biological labels and their colors", {
  colors <- c(B_cell = "#000000", T_cell = "#000000", NK_cell = "#FFFFFF")
  audit <- sc_palette_audit(colors, cvd = "none")

  expect_identical(audit$vision$worst_pair, "B_cell / T_cell")
  expect_identical(audit$vision$worst_label_1, "B_cell")
  expect_identical(audit$vision$worst_label_2, "T_cell")
  expect_identical(audit$vision$worst_color_1, "#000000")
  expect_identical(audit$vision$worst_color_2, "#000000")
  expect_named(audit$contrast, names(colors))
})

test_that("named audit inputs require complete unique labels", {
  expect_error(
    sc_palette_audit(c(B = "#000000", "#FFFFFF")),
    "non-missing label"
  )
  expect_error(
    sc_palette_audit(c(B = "#000000", B = "#FFFFFF")),
    "duplicate labels"
  )
  expect_error(sc_palette_audit(character()), "at least one color")
})

test_that("only qualitative palettes receive categorical cardinality flags", {
  continuous <- c("viridis", "chromatic_balance", "d3_cool")
  for (id in continuous) {
    expect_false(
      "high_cardinality_needs_redundant_encoding" %in% sc_palette_audit(id)$flags,
      info = id
    )
  }

  map <- sc_color_map(sprintf("cell_type_%02d", seq_len(21)))
  expect_true(
    "high_cardinality_needs_redundant_encoding" %in% sc_palette_audit(map)$flags
  )
})

test_that("palette previews render on light and dark backgrounds", {
  grDevices::pdf(NULL)
  device <- grDevices::dev.cur()
  on.exit({
    if (device %in% grDevices::dev.list()) grDevices::dev.off(device)
  }, add = TRUE)
  for (background in c("light", "dark")) {
    plot <- sc_palette_plot(
      "okabe_ito", n = 4, view = "both", background = background, cvd = "none"
    )
    expect_s3_class(plot, "ggplot")
    expect_s3_class(ggplot2::ggplotGrob(plot), "gtable")
  }
})

test_that("color-map plots display labels and color codes", {
  map <- sc_color_map(c("B", "T", "NK"))
  colors <- as_named_colors(map)
  plot <- sc_color_map_plot(map)

  expect_s3_class(plot, "ggplot")
  expect_identical(
    plot$layers[[2L]]$data$label,
    paste(names(colors), unname(colors), sep = "\n")
  )
})

test_that("invalid CVD modes fail clearly", {
  expect_error(sc_palette_audit("#000000", cvd = "unknown"), "cvd")
  expect_error(sc_palette_plot("#000000", cvd = "unknown"), "cvd")
})
