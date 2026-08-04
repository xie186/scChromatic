test_that("registry entries and colors are valid", {
  ids <- sc_palette_names()
  expect_identical(anyDuplicated(ids), 0L)
  expect_true(length(ids) >= 19)

  for (id in ids) {
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

test_that("frozen provider LUTs reproduce pinned package outputs", {
  expected <- list(
    viridis = c("#440154", "#3B528B", "#21908C", "#5DC863", "#FDE725"),
    cividis = c("#00204D", "#414D6B", "#7C7B78", "#BCAF6F", "#FFEA46"),
    magma = c("#000004", "#51127C", "#B63679", "#FB8861", "#FCFDBF"),
    scico_batlow = c("#001959", "#215F61", "#818231", "#F19D6B", "#F9CCF9"),
    scico_lajolla = c("#191900", "#663329", "#D85F4D", "#ECAC54", "#FFFECB"),
    scico_vik = c("#001260", "#2F7CA5", "#EBE5E0", "#C27142", "#590007"),
    scico_broc = c("#2C194C", "#5A81A8", "#EAEDEB", "#9A9A61", "#262600")
  )
  for (id in names(expected)) {
    expect_length(sc_palette(id, 256, selection = "source"), 256L)
    expect_identical(sc_palette(id, 5), expected[[id]], info = id)
  }
})

test_that("chromatic is frozen and nested", {
  expected <- c(
    "#475D8F", "#E3B54E", "#00DADF", "#765A11", "#009685", "#9C8CFB",
    "#D14D70", "#8C7D00", "#EA74A9", "#007C4D", "#7D73BD", "#A99C5D",
    "#89CA98", "#C69400", "#8F4667", "#00AFB3", "#98BAFF", "#B30089",
    "#5F4AC2", "#5A8849", "#A5679C", "#ECA7D1", "#C484D1", "#5AD27C",
    "#1D6C36", "#CE8795", "#68A977", "#A03F37", "#BE52B1", "#2A8C65",
    "#3E7ADB", "#FEA67F", "#D4BC00", "#3085A2", "#E4814A", "#B96637",
    "#006C7C", "#AE6876", "#00B86B", "#A019B0"
  )
  expect_identical(sc_palette("chromatic", 40), expected)
  p8 <- sc_palette("chromatic", 8)
  expect_identical(p8, sc_palette("chromatic", 20)[seq_len(8)])
  expect_identical(p8, sc_palette("chromatic", 40)[seq_len(8)])
})

test_that("package-owned palettes reproduce from their generators", {
  expect_identical(
    sc_palette_generate(40),
    sc_palette("chromatic", 40, selection = "source")
  )
  expect_identical(
    toupper(colorspace::diverging_hcl(
      11, h = c(250, 10), c = 75, l = c(35, 95), power = 1.1
    )),
    sc_palette("chromatic_balance", 11, selection = "source")
  )
})

test_that("unknown palettes provide a useful suggestion", {
  expect_error(sc_palette("okabe_it"), "okabe_ito")
})
