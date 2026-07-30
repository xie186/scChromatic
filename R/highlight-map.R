#' Create a focus-versus-other color map
#'
#' @param labels All labels.
#' @param focus Labels to highlight.
#' @param focus_palette Qualitative palette for focused labels.
#' @param other Muted color for nonfocused labels.
#' @param background Light or dark background.
#' @return An `sc_color_map`.
#' @export
#' @examples
#' sc_highlight_map(c("B", "T", "NK"), focus = c("B", "NK"))
sc_highlight_map <- function(labels, focus, focus_palette = "okabe_ito",
                             other = "grey85",
                             background = c("light", "dark")) {
  background <- match.arg(background)
  ordered <- .sc_order_labels(labels, "natural")
  focus <- intersect(.sc_order_labels(focus, "natural"), ordered)
  .sc_validate_colors(other, "other")
  focus_colors <- if (length(focus)) {
    sc_palette(
      focus_palette, length(focus), extend = "generate", background = background
    )
  } else {
    character()
  }
  colors <- stats::setNames(rep(.sc_hex(other), length(ordered)), ordered)
  colors[focus] <- focus_colors
  row <- .sc_palette_row(focus_palette)
  .sc_new_map(
    colors, paste0("highlight:", .sc_palette_id(focus_palette)), background, other,
    provenance = row[, c(
      "source", "source_palette", "source_url", "source_commit",
      "citation", "license"
    ), drop = FALSE],
    focus = focus
  )
}
