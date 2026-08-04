#' Create a focus-versus-other color map
#'
#' @param labels All labels.
#' @param focus Labels to highlight.
#' @param focus_palette Qualitative palette for focused labels.
#' @param other Muted color for nonfocused labels.
#' @param background Light or dark background.
#' @return An `sc_color_map` whose focus and muted-color metadata are retained
#'   by JSON and CSV serialization.
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
    map_type = "highlight",
    provenance = .sc_map_provenance(row),
    focus = focus,
    focus_palette = .sc_palette_id(focus_palette),
    other = .sc_hex(other)
  )
}
