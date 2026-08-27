.sc_scale_d <- function(aesthetics, palette, alpha, reverse, selection,
                        extend, background, ...) {
  ggplot2::discrete_scale(
    aesthetics = aesthetics,
    palette = sc_pal(
      palette, alpha = alpha, reverse = reverse, selection = selection,
      extend = extend, background = background
    ),
    ...
  )
}

#' Discrete scChromatic color scale
#'
#' Use the color or colour variant for variables mapped to the `color`
#' aesthetic, and the fill variant for variables mapped to `fill`. These scales
#' assign colors from the discrete levels supplied to the plot. Use
#' [scale_color_sc_map()] or [scale_fill_sc_map()] instead when exact category
#' assignments must remain stable across plots and subsets; use the `_sc_c()`
#' family for numeric gradients.
#'
#' @inheritParams sc_palette
#' @param ... Passed to [ggplot2::discrete_scale()].
#' @export
#' @examples
#' ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), mpg, color = factor(cyl))) +
#'   ggplot2::geom_point() + scale_color_sc_d()
scale_color_sc_d <- function(palette = "auto", alpha = 1, reverse = FALSE,
                             selection = c("priority", "source"),
                             extend = c("error", "generate"),
                             background = c("light", "dark"), ...) {
  .sc_scale_d(
    "colour", palette, alpha, reverse, match.arg(selection), match.arg(extend),
    match.arg(background), ...
  )
}

#' @rdname scale_color_sc_d
#' @export
scale_colour_sc_d <- scale_color_sc_d

#' @rdname scale_color_sc_d
#' @export
scale_fill_sc_d <- function(palette = "auto", alpha = 1, reverse = FALSE,
                            selection = c("priority", "source"),
                            extend = c("error", "generate"),
                            background = c("light", "dark"), ...) {
  .sc_scale_d(
    "fill", palette, alpha, reverse, match.arg(selection), match.arg(extend),
    match.arg(background), ...
  )
}

.sc_scale_map <- function(aesthetics, map, ..., drop = TRUE) {
  if (!inherits(map, "sc_color_map")) {
    .sc_abort("{.arg map} must be an sc_color_map.")
  }
  values <- as_named_colors(map)
  if (identical(aesthetics, "colour")) {
    ggplot2::scale_color_manual(
      values = values, na.value = map$na.value, drop = drop, ...
    )
  } else {
    ggplot2::scale_fill_manual(
      values = values, na.value = map$na.value, drop = drop, ...
    )
  }
}

#' Manual ggplot2 scales from a persistent color map
#'
#' These scales use the exact named assignments stored in `map`; assignments
#' are never recomputed from the plotted subset.
#'
#' Use the color or colour variant for points, lines, text, and geometry
#' outlines mapped with `color`. Use the fill variant for geometry interiors
#' mapped with `fill`, such as violins, bars, tiles, and polygons. The
#' `scale_colour_*()` spelling is an exact alias of `scale_color_*()`. For a
#' one-off categorical plot that does not require locked assignments, use the
#' `_sc_d()` family; for numeric gradients, use `_sc_c()`.
#'
#' @param map An `sc_color_map`.
#' @param ... Passed to [ggplot2::scale_color_manual()] or
#'   [ggplot2::scale_fill_manual()].
#' @param drop Drop unused factor levels from the scale.
#' @return A ggplot2 scale.
#' @export
#' @examples
#' map <- sc_color_map(c("B", "T", "NK"))
#' ggplot2::ggplot(
#'   data.frame(x = 1:2, y = 1:2, cell = c("T", "NK")),
#'   ggplot2::aes(x, y, color = cell)
#' ) + ggplot2::geom_point() + scale_color_sc_map(map)
scale_color_sc_map <- function(map, ..., drop = TRUE) {
  .sc_scale_map("colour", map, ..., drop = drop)
}

#' @rdname scale_color_sc_map
#' @export
scale_colour_sc_map <- scale_color_sc_map

#' @rdname scale_color_sc_map
#' @export
scale_fill_sc_map <- function(map, ..., drop = TRUE) {
  .sc_scale_map("fill", map, ..., drop = drop)
}
