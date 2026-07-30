.sc_pairwise_distance <- function(x, y = x) {
  xr <- farver::decode_colour(x, to = "rgb")
  yr <- farver::decode_colour(y, to = "rgb")
  farver::compare_colour(xr, yr, from_space = "rgb", method = "cie2000")
}

.sc_candidate_colors <- function(background) {
  lightness <- if (background == "light") c(40, 52, 64, 76) else c(48, 60, 72, 84)
  grid <- expand.grid(
    H = seq(0, 345, by = 15),
    C = c(45, 60, 75, 90),
    L = lightness,
    KEEP.OUT.ATTRS = FALSE
  )
  colors <- colorspace::hex(
    colorspace::polarLUV(L = grid$L, C = grid$C, H = grid$H),
    fix = TRUE
  )
  unique(toupper(colors[!is.na(colors)]))
}

.sc_extend_colors <- function(colors, n, background = "light") {
  if (length(colors) >= n) {
    return(colors[seq_len(n)])
  }
  selected <- toupper(.sc_hex(colors))
  candidates <- setdiff(.sc_candidate_colors(background), selected)
  bg <- if (background == "light") "#FFFFFF" else "#1A1A1A"

  while (length(selected) < n) {
    if (!length(candidates)) {
      .sc_abort("The deterministic candidate grid was exhausted at {length(selected)} colors.")
    }
    contrast <- as.numeric(colorspace::contrast_ratio(candidates, bg))
    if (!length(selected)) {
      score <- contrast
    } else {
      modes <- c("none", "deutan", "protan", "tritan")
      scores <- rep(Inf, length(candidates))
      for (mode in modes) {
        candidate_view <- .sc_cvd(candidates, mode)
        selected_view <- .sc_cvd(selected, mode)
        distance <- .sc_pairwise_distance(candidate_view, selected_view)
        scores <- pmin(scores, apply(distance, 1L, min, na.rm = TRUE))
      }
      score <- scores + pmin(contrast, 7) / 50
    }
    best <- which.max(score)
    selected <- c(selected, candidates[[best]])
    candidates <- candidates[-best]
  }
  unname(selected)
}

#' Generate a deterministic qualitative color sequence
#'
#' Extends an optional fixed set without changing its colors. Candidates are
#' ranked by their worst CIE2000 separation under normal, deutan, protan, and
#' tritan simulations. The result is diagnostic and is not a guarantee of
#' universal color-vision-deficiency safety.
#'
#' @param n Number of colors.
#' @param seed_colors Optional colors that must remain at the start.
#' @param background Background for candidate scoring, `"light"` or `"dark"`.
#' @return A hexadecimal color vector.
#' @export
#' @examples
#' sc_palette_generate(6, seed_colors = c("#0072B2", "#D55E00"))
sc_palette_generate <- function(n, seed_colors = character(),
                                background = c("light", "dark")) {
  n <- .sc_validate_n(n, allow_null = FALSE)
  background <- match.arg(background)
  .sc_validate_colors(seed_colors, "seed_colors")
  .sc_extend_colors(unique(.sc_hex(seed_colors)), n, background)
}
