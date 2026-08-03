test_that("d3_rainbow reproduces CELLXGENE category colors", {
  expected <- c(
    "#6E40AA", "#D23EA7", "#FF5E63", "#EFA72F",
    "#AFF05B", "#40F373", "#1AC7C2", "#417DE0"
  )

  expect_identical(sc_palette("d3_rainbow", 8), expected)
  expect_identical(sc_pal("d3_rainbow")(8), expected)
})

test_that("d3_rainbow follows category-count-dependent D3 sampling", {
  eight <- sc_palette("d3_rainbow", 8)
  twelve <- sc_palette("d3_rainbow", 12)

  expect_false(identical(eight, twelve[seq_along(eight)]))
  expect_identical(eight[[1L]], twelve[[1L]])
})

test_that("d3_cool preserves exact source and CELLXGENE data direction", {
  expect_identical(
    .sc_d3_cool(c(0, 0.25, 0.5, 0.75, 0.99, 1)),
    c("#6E40AA", "#417DE0", "#1AC7C2", "#40F373", "#AAF059", "#AFF05B")
  )

  source <- sc_palette("d3_cool", 100, selection = "source")
  priority <- sc_palette("d3_cool", 100, selection = "priority")
  expect_identical(source, .sc_d3_cool((0:99) / 100))
  expect_identical(priority, rev(source))
  expect_identical(priority[c(1L, 100L)], c("#AAF059", "#6E40AA"))

  scale <- scale_color_sc_c("d3_cool")
  expect_identical(scale$palette(c(0, 1)), c("#AAF059", "#6E40AA"))
})

test_that("cyclic d3_rainbow is not a persistent mapping palette", {
  expect_identical(sc_palette_info("d3_rainbow")$palette_type, "cyclic")
  expect_error(
    sc_color_map(c("B", "T"), palette = "d3_rainbow"),
    "Persistent mappings require a qualitative palette"
  )
})
