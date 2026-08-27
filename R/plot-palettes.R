.sc_plot_colors <- function(x, n, background) {
  if (inherits(x, "sc_color_map")) {
    return(as_named_colors(x))
  }
  if (is.character(x) && length(x) == 1L && !.sc_is_color(x)) {
    return(sc_palette(x, n = n, extend = "generate", background = background))
  }
  .sc_validate_colors(x)
  if (!length(x)) {
    .sc_abort("{.arg x} must contain at least one color.")
  }
  x
}

.sc_one_palette_plot <- function(colors, view, background, mode, labels, codes) {
  viewed <- .sc_cvd(colors, mode)
  names(viewed) <- if (is.null(names(colors))) seq_along(colors) else names(colors)
  background_color <- if (background == "light") "#FFFFFF" else "#1A1A1A"
  foreground <- if (background == "light") "#222222" else "#F2F2F2"
  base <- ggplot2::ggplot() +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = background_color, color = NA),
      panel.background = ggplot2::element_rect(fill = background_color, color = NA),
      plot.title = ggplot2::element_text(color = foreground, hjust = 0.5)
    ) +
    ggplot2::ggtitle(mode)
  if (view %in% c("swatch", "both")) {
    swatches <- data.frame(
      x = seq_along(viewed), color = unname(viewed), label = names(viewed)
    )
    base <- base +
      ggplot2::geom_tile(
        data = swatches,
        ggplot2::aes(x = x, y = 1, fill = color),
        width = 0.96, height = 0.75
      ) +
      ggplot2::scale_fill_identity()
    if (labels || codes) {
      swatches$label <- if (labels && codes) {
        paste(swatches$label, swatches$color, sep = "\n")
      } else if (labels) {
        swatches$label
      } else {
        swatches$color
      }
      base <- base + ggplot2::geom_text(
        data = swatches,
        ggplot2::aes(x = x, y = 0.48, label = label),
        color = foreground, angle = 45, hjust = 1, size = 3
      ) +
        ggplot2::coord_cartesian(clip = "off") +
        ggplot2::theme(
          plot.margin = ggplot2::margin(
            5.5, 5.5, if (codes) 70 else 45, 5.5
          )
        )
    }
  }
  if (view %in% c("points", "both")) {
    count <- max(600L, 80L * length(viewed))
    index <- seq_len(count)
    group <- (index - 1L) %% length(viewed) + 1L
    angle <- index * 2.399963
    radius <- sqrt(index / count)
    points <- data.frame(
      x = cos(angle) * radius * 1.7,
      y = sin(angle) * radius + if (view == "both") 2.3 else 0,
      color = unname(viewed[group])
    )
    base <- base +
      ggplot2::geom_point(
        data = points,
        ggplot2::aes(x = x, y = y, color = color),
        size = 0.75, alpha = 0.8
      ) +
      ggplot2::scale_color_identity()
  }
  base
}

#' Plot palette swatches or dense point previews
#'
#' @param x Palette ID, color vector, or `sc_color_map`.
#' @param n Optional number of colors for a palette ID.
#' @param view Swatches, points, or both.
#' @param background Light or dark background.
#' @param cvd One or more vision simulations.
#' @param labels Label swatches.
#' @param codes Label swatches with their hexadecimal color codes.
#' @return A ggplot object for one CVD view, otherwise a named list of plots.
#' @export
#' @examples
#' sc_palette_plot("okabe_ito", view = "both")
sc_palette_plot <- function(x, n = NULL, view = c("swatch", "points", "both"),
                            background = c("light", "dark"),
                            cvd = c("none", "deutan", "protan", "tritan"),
                            labels = TRUE, codes = FALSE) {
  view <- match.arg(view)
  background <- match.arg(background)
  labels <- .sc_validate_flag(labels, "labels")
  codes <- .sc_validate_flag(codes, "codes")
  modes <- unique(cvd)
  allowed <- c("none", "deutan", "protan", "tritan")
  if (!length(modes) || any(!modes %in% allowed)) {
    .sc_abort(
      "{.arg cvd} must contain values from {paste(allowed, collapse = ', ')}."
    )
  }
  colors <- .sc_plot_colors(x, .sc_validate_n(n), background)
  plots <- lapply(modes, function(mode) {
    .sc_one_palette_plot(colors, view, background, mode, labels, codes)
  })
  names(plots) <- modes
  if (length(plots) == 1L) plots[[1L]] else plots
}

#' Plot a persistent color map
#'
#' Displays each mapped label alongside its color swatch and hexadecimal code.
#'
#' @param x An `sc_color_map`.
#' @return A ggplot object.
#' @export
#' @examples
#' cell_map <- sc_color_map(c("B", "T", "NK"))
#' sc_color_map_plot(cell_map)
sc_color_map_plot <- function(x) {
  .sc_validate_map(x)
  sc_palette_plot(
    x, view = "swatch", background = x$background, cvd = "none",
    labels = TRUE, codes = TRUE
  ) + ggplot2::labs(title = NULL)
}
