test_that("audit includes every requested vision mode", {
  modes <- c("none", "deutan", "protan", "tritan")
  audit <- sc_palette_audit("okabe_ito", cvd = modes)
  expect_s3_class(audit, "sc_palette_audit")
  expect_setequal(audit$vision$vision, modes)
  expect_true(all(c(
    "min_distance", "median_distance", "worst_pair"
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

test_that("invalid CVD modes fail clearly", {
  expect_error(sc_palette_audit("#000000", cvd = "unknown"), "cvd")
  expect_error(sc_palette_plot("#000000", cvd = "unknown"), "cvd")
})
