test_that("provenance registry includes required fields", {
  required <- c(
    "palette_id", "source", "source_palette", "palette_type", "max_n",
    "intended_use", "recommended_geometry", "recommended_background", "status",
    "source_order", "priority_order", "source_url", "source_version",
    "source_commit", "source_sha256", "citation", "license", "derived",
    "source_cvd_claim", "notes", "audit_min_cie2000",
    "audit_min_cie2000_deutan", "audit_min_cie2000_protan",
    "audit_min_cie2000_tritan", "audit_min_contrast_light",
    "audit_min_contrast_dark", "audit_n", "audit_basis", "audit_method",
    "audit_date"
  )
  for (id in sc_palette_names()) {
    expect_true(all(required %in% names(sc_palette_info(id))), info = id)
  }
  expect_false(any(startsWith(sc_palette_names(), "archr_")))
  expect_identical(
    sc_palette_info("chromatic")$source_url,
    "https://github.com/xie186/scChromatic"
  )
  expect_identical(
    sc_palette_info("chromatic_balance")$source,
    "scChromatic"
  )
  rainbow <- sc_palette_info("d3_rainbow")
  cool <- sc_palette_info("d3_cool")
  expect_identical(rainbow$source_palette, "interpolateRainbow")
  expect_identical(cool$source_palette, "interpolateCool")
  expect_identical(rainbow$palette_type, "cyclic")
  expect_identical(cool$palette_type, "sequential")
  expect_identical(rainbow$max_n, 200L)
  expect_identical(cool$max_n, 100L)
  expect_identical(rainbow$status, "compatibility")
  expect_identical(cool$status, "compatibility")
  expect_true(rainbow$derived)
  expect_true(cool$derived)
  expect_identical(
    rainbow$source_commit,
    "05e76dafaa89059153e177a4f57d9af985ba49a8"
  )
  expect_match(rainbow$notes, "76a39fcf92da57c9e4fd59831ad805a3b007da8c")
  expect_match(cool$notes, "76a39fcf92da57c9e4fd59831ad805a3b007da8c")
  expect_match(rainbow$license, "BSD-3-Clause")
  expect_match(cool$priority_order, "reverse source order")
  expect_false(any(vapply(sc_palette_names(), function(id) {
    identical(sc_palette_info(id)$status, "provenance_review")
  }, logical(1))))
})

test_that("third-party palette sources are pinned and licensed", {
  expected <- c(
    okabe_ito = "40ba0f49e19710453fce918d1e036c4fcb6c7d3a70186236b8ad6b9f777c180f",
    tol_bright = "40ba0f49e19710453fce918d1e036c4fcb6c7d3a70186236b8ad6b9f777c180f",
    glasbey32 = "4213cfb6247b58153d3668ea09a2691e99939cb2618ba322c80f95894acac58c",
    polychrome36 = "4213cfb6247b58153d3668ea09a2691e99939cb2618ba322c80f95894acac58c",
    ditto40 = "5c08274913e93158a9660507d50f5e79d4facbe01ab745e4fee0cd703e13454e",
    viridis = "433be9bde66234dc76301fb4ffbbc9fc74bab5c14f4548d8ef2fc0065e121ef5",
    scico_batlow = "647121b3f64118b162a35f9709a301f696239e9a707a04559c0368617c01c9b0"
  )
  for (id in names(expected)) {
    info <- sc_palette_info(id)
    expect_identical(info$source_sha256, unname(expected[[id]]), info = id)
    expect_match(info$source_version, "[0-9]+\\.[0-9]+", info = id)
    expect_match(info$license, "GPL|Apache|MIT|CC BY", info = id)
  }

  third_party <- setdiff(sc_palette_names(), c("chromatic", "chromatic_balance"))
  for (id in third_party) {
    info <- sc_palette_info(id)
    has_commit <- !is.na(info$source_commit) && nzchar(info$source_commit)
    has_archive <- !is.na(info$source_sha256) && nzchar(info$source_sha256)
    expect_true(has_commit || has_archive, info = id)
    expect_true(!is.na(info$source_url) && nzchar(info$source_url), info = id)
    expect_true(!is.na(info$citation) && nzchar(info$citation), info = id)
    expect_true(!is.na(info$license) && nzchar(info$license), info = id)
  }
})

test_that("registry audits cover normal and common CVD simulations", {
  fields <- c(
    "audit_min_cie2000", "audit_min_cie2000_deutan",
    "audit_min_cie2000_protan", "audit_min_cie2000_tritan",
    "audit_min_contrast_light", "audit_min_contrast_dark"
  )
  for (id in sc_palette_names()) {
    info <- sc_palette_info(id)
    expect_true(all(is.finite(unlist(info[fields], use.names = FALSE))), info = id)
    expect_true(is.numeric(info$audit_n) && info$audit_n >= 2L, info = id)
    expect_true(is.character(info$audit_basis) && nzchar(info$audit_basis), info = id)
  }
})

test_that("source and priority reorderings are explicit", {
  okabe_source <- sc_palette("okabe_ito", selection = "source")
  expect_identical(okabe_source[[1L]], "#000000")
  expect_identical(sc_palette("okabe_ito")[[8L]], "#000000")

  glasbey_source <- sc_palette("glasbey32", selection = "source")
  expect_identical(glasbey_source[[1L]], "#FFFFFF")
  expect_identical(sc_palette("glasbey32")[[32L]], "#FFFFFF")

  expect_identical(
    sc_palette("tol_medium_contrast"),
    c("#6699CC", "#004488", "#EECC66", "#994455", "#997700", "#EE99AA")
  )
})

test_that("frameworks and palette providers are not runtime dependencies", {
  imports <- names(getNamespaceImports("scChromatic"))
  expect_false(any(c(
    "ArchR", "Seurat", "SeuratObject", "SingleCellExperiment",
    "ComplexHeatmap", "scico", "viridisLite"
  ) %in% imports))
})

test_that("runtime functions contain no network access", {
  namespace <- asNamespace("scChromatic")
  functions <- Filter(is.function, mget(ls(namespace, all.names = TRUE), namespace))
  code <- paste(vapply(functions, function(fn) {
    paste(deparse(body(fn)), collapse = "\n")
  }, character(1)), collapse = "\n")
  expect_false(grepl(
    "download\\.file|url\\s*\\(|curl::|httr::|httr2::|GET\\s*\\(",
    code
  ))
})
