test_that("example data cover the documented single-cell semantics", {
  expect_s3_class(sc_example, "data.frame")
  expect_identical(dim(sc_example), c(720L, 12L))
  expect_identical(
    names(sc_example),
    c(
      "cell_id", "UMAP1", "UMAP2", "cell_type", "lineage", "sample",
      "condition", "MS4A1", "signed_score", "pseudotime", "percent_mito",
      "n_counts"
    )
  )
  expect_false(anyNA(sc_example))
  expect_identical(length(unique(sc_example$cell_id)), nrow(sc_example))
  expect_true(all(sc_example$pseudotime >= 0 & sc_example$pseudotime <= 1))
})

test_that("example subsets retain their full-data color assignments", {
  map <- sc_color_map(sc_example$cell_type, palette = "chromatic")
  subset <- sc_example[
    sc_example$condition == "Stimulated" &
      sc_example$cell_type %in% c("CD4 T", "NK", "Monocyte"),
    ,
    drop = FALSE
  ]
  labels <- levels(droplevels(subset$cell_type))
  expect_identical(
    as_named_colors(map)[labels],
    as_named_colors(map)[c("CD4 T", "NK", "Monocyte")]
  )
})
