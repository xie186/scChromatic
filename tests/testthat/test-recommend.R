test_that("recommendations enforce purpose-specific palette types", {
  signed <- sc_palette_recommend(9, use = "signed_score", top = 20)
  expression <- sc_palette_recommend(9, use = "expression", top = 20)
  identity <- sc_palette_recommend(8, use = "cell_identity", top = 20)

  expect_true(all(vapply(signed$palette_id, function(id) {
    sc_palette_info(id)$palette_type == "diverging"
  }, logical(1))))
  expect_true(all(vapply(expression$palette_id, function(id) {
    sc_palette_info(id)$palette_type == "sequential"
  }, logical(1))))
  expect_true(all(vapply(identity$palette_id, function(id) {
    sc_palette_info(id)$palette_type == "qualitative"
  }, logical(1))))
  expect_identical(signed$palette_id[[1L]], "chromatic_balance")
  expect_false(any(startsWith(identity$palette_id, "archr_")))
  expect_false(any(startsWith(expression$palette_id, "archr_")))
})

test_that("highlight maps preserve a named mapping", {
  map <- sc_highlight_map(
    c("B", "T", "NK", "Mono"), focus = c("B", "NK"), other = "grey85"
  )
  colors <- as_named_colors(map)
  expect_identical(colors[c("Mono", "T")], c(Mono = "#D9D9D9", T = "#D9D9D9"))
  expect_false(colors[["B"]] == colors[["NK"]])

  none <- sc_highlight_map(c("B", "T"), focus = character())
  expect_identical(length(unique(as_named_colors(none))), 1L)
})
