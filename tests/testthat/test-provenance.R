test_that("provenance registry includes required fields", {
  required <- c(
    "palette_id", "source", "source_palette", "palette_type", "max_n",
    "intended_use", "recommended_geometry", "recommended_background", "status",
    "source_order", "priority_order", "source_url", "source_commit", "citation",
    "license", "derived", "source_cvd_claim", "notes",
    "audit_min_cie2000", "audit_min_contrast_light", "audit_min_contrast_dark"
  )
  for (id in sc_palette_names()) {
    expect_true(all(required %in% names(sc_palette_info(id))), info = id)
  }
  expect_identical(
    sc_palette_info("archr_stallion")$source_commit,
    "6feec354ad6c8052ddbc4626a2ca2d858ed465bf"
  )
  expect_identical(
    sc_palette_info("chromatic")$source_url,
    "https://github.com/xie186/scChromatic"
  )
})

test_that("optional single-cell frameworks are not runtime dependencies", {
  imports <- names(getNamespaceImports("scChromatic"))
  expect_false(any(c(
    "ArchR", "Seurat", "SeuratObject", "SingleCellExperiment",
    "ComplexHeatmap", "scico"
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
