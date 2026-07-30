.sc_scale_c <- function(aesthetics, palette, alpha, reverse, midpoint,
                        limits, oob, na.value, ...) {
  row <- .sc_palette_row(palette)
  if (row$palette_type[[1L]] == "qualitative") {
    .sc_abort("Continuous scales require a sequential, diverging, or cyclic palette.")
  }
  colors <- sc_palette(palette, n = 256, alpha = alpha, reverse = reverse)
  rescaler <- if (is.null(midpoint)) {
    scales::rescale
  } else {
    if (!is.numeric(midpoint) || length(midpoint) != 1L || !is.finite(midpoint)) {
      .sc_abort("{.arg midpoint} must be NULL or one finite number.")
    }
    function(x, to = c(0, 1), from = range(x, na.rm = TRUE)) {
      scales::rescale_mid(x, to = to, from = from, mid = midpoint)
    }
  }
  scale_function <- if (identical(aesthetics, "colour")) {
    ggplot2::scale_color_gradientn
  } else {
    ggplot2::scale_fill_gradientn
  }
  scale_function(
    colours = colors, limits = limits, oob = oob, na.value = na.value,
    rescaler = rescaler, ...
  )
}

#' Continuous scChromatic color scale
#'
#' A non-`NULL` midpoint uses [scales::rescale_mid()] so the data value at the
#' midpoint maps to the center of the gradient.
#'
#' @param palette Sequential, diverging, or cyclic palette ID.
#' @param alpha Opacity in `(0, 1]`.
#' @param reverse Reverse the color sequence.
#' @param midpoint Optional data midpoint.
#' @param limits Scale limits.
#' @param oob Out-of-bounds handler.
#' @param na.value Missing-value color.
#' @param ... Passed to [ggplot2::scale_color_gradientn()] or its fill variant.
#' @return A ggplot2 continuous scale.
#' @export
#' @examples
#' ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = disp)) +
#'   ggplot2::geom_point() + scale_color_sc_c("viridis")
scale_color_sc_c <- function(palette = "viridis", alpha = 1, reverse = FALSE,
                             midpoint = NULL, limits = NULL,
                             oob = scales::squish, na.value = "grey85", ...) {
  .sc_scale_c(
    "colour", palette, alpha, reverse, midpoint, limits, oob, na.value, ...
  )
}

#' @rdname scale_color_sc_c
#' @export
scale_colour_sc_c <- scale_color_sc_c

#' @rdname scale_color_sc_c
#' @export
scale_fill_sc_c <- function(palette = "viridis", alpha = 1, reverse = FALSE,
                            midpoint = NULL, limits = NULL,
                            oob = scales::squish, na.value = "grey85", ...) {
  .sc_scale_c("fill", palette, alpha, reverse, midpoint, limits, oob, na.value, ...)
}
