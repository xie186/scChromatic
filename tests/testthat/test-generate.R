test_that("direct generation is deterministic and preserves seed colors", {
  seed <- c("#0072B2", "#D55E00")
  first <- sc_palette_generate(10, seed)
  second <- sc_palette_generate(10, seed)
  expect_identical(first, second)
  expect_identical(first[seq_along(seed)], seed)
  expect_identical(anyDuplicated(first), 0L)
})
