test_that("registry entries and colors are valid", {
  ids <- sc_palette_names()
  expect_identical(anyDuplicated(ids), 0L)
  expect_true(length(ids) >= 38)

  for (id in ids[!startsWith(ids, "scico_")]) {
    info <- sc_palette_info(id)
    expect_true(info$palette_type %in% c(
      "qualitative", "sequential", "diverging", "cyclic"
    ))
    expect_true(is.numeric(info$max_n) && info$max_n >= 1)
    n <- if (info$palette_type == "qualitative") info$max_n else 9L
    colors <- sc_palette(id, n)
    expect_length(colors, n)
    expect_true(all(grepl("^#[0-9A-F]{6}([0-9A-F]{2})?$", colors)), info = id)
  }
})

test_that("alpha and reverse handling are exact", {
  colors <- sc_palette("okabe_ito", 3)
  expect_identical(sc_palette("okabe_ito", 3, reverse = TRUE), rev(colors))
  expect_identical(
    sc_palette("okabe_ito", 1, alpha = 0.5),
    "#E69F0080"
  )
  expect_error(sc_palette("okabe_ito", alpha = 0), "alpha")
  expect_error(sc_palette("okabe_ito", alpha = Inf), "alpha")
})

test_that("qualitative extension is explicit, deterministic, and preserving", {
  source <- sc_palette("okabe_ito")
  expect_error(
    sc_palette("okabe_ito", 9),
    "Requested 9 colors.*capacity 8.*extend = \"generate\""
  )
  first <- sc_palette("okabe_ito", 14, extend = "generate")
  second <- sc_palette("okabe_ito", 14, extend = "generate")
  expect_identical(first, second)
  expect_identical(first[seq_along(source)], source)
  expect_identical(anyDuplicated(first), 0L)
})

test_that("continuous palettes interpolate to exactly n colors", {
  expect_length(sc_palette("viridis", 17), 17)
  expect_length(sc_palette("chromatic_balance", 101), 101)
})

test_that("continuous palettes preserve their registered anchors", {
  expect_identical(
    sc_palette("chromatic_balance", 11),
    c(
      "#0055A3", "#4674B0", "#7A94C0", "#A5B4D1", "#CDD4E2", "#F1F1F1",
      "#E4CFCF", "#D4A9AA", "#C28284", "#AC5A5D", "#942E34"
    )
  )
})

test_that("chromatic is frozen and nested", {
  p8 <- sc_palette("chromatic", 8)
  expect_identical(p8, sc_palette("chromatic", 20)[seq_len(8)])
  expect_identical(p8, sc_palette("chromatic", 40)[seq_len(8)])
})

test_that("unknown palettes provide a useful suggestion", {
  expect_error(sc_palette("okabe_it"), "okabe_ito")
})
