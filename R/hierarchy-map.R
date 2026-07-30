.sc_child_variants <- function(anchor, n, separation, background) {
  if (n == 1L) {
    return(anchor)
  }
  rgb <- t(grDevices::col2rgb(anchor) / 255)
  luv <- grDevices::convertColor(rgb, from = "sRGB", to = "Luv")[1L, ]
  coords <- c(
    L = luv[["L"]],
    C = sqrt(luv[["u"]] ^ 2 + luv[["v"]] ^ 2),
    H = (atan2(luv[["v"]], luv[["u"]]) * 180 / pi) %% 360
  )
  span <- switch(
    separation,
    balanced = 22,
    between_lineage = 14,
    within_lineage = 32
  )
  l_center <- coords[["L"]]
  lightness <- pmax(30, pmin(if (background == "dark") 90 else 82,
                            l_center + seq(-span, span, length.out = n)))
  chroma <- pmax(25, coords[["C"]] * seq(0.72, 1.08, length.out = n))
  colorspace::hex(
    colorspace::polarLUV(L = lightness, C = chroma, H = coords[["H"]]),
    fix = TRUE
  )
}

#' Create a hierarchy-aware color map
#'
#' Child labels receive controlled lightness and chroma variants of distinct
#' parent anchor hues.
#'
#' @param parent Parent lineage labels.
#' @param child Child subtype labels.
#' @param parent_palette Qualitative palette for parent anchors.
#' @param separation Emphasize balanced, between-lineage, or within-lineage
#'   separation.
#' @param background Light or dark background.
#' @param na.value Missing-value color.
#' @return An `sc_color_map` with a named `parent` field.
#' @export
#' @examples
#' sc_hierarchy_map(
#'   parent = c("Lymphoid", "Lymphoid", "Myeloid"),
#'   child = c("B", "T", "Mono")
#' )
sc_hierarchy_map <- function(parent, child, parent_palette = "tol_muted",
                             separation = c(
                               "balanced", "between_lineage", "within_lineage"
                             ),
                             background = c("light", "dark"),
                             na.value = "#BDBDBD") {
  if (length(parent) != length(child)) {
    .sc_abort("{.arg parent} and {.arg child} must have the same length.")
  }
  separation <- match.arg(separation)
  background <- match.arg(background)
  parent <- as.character(parent)
  child <- as.character(child)
  pairs <- unique(data.frame(parent = parent, child = child, stringsAsFactors = FALSE))
  pairs <- pairs[!is.na(pairs$child) & !is.na(pairs$parent), , drop = FALSE]
  if (!nrow(pairs)) {
    .sc_abort("{.arg parent} and {.arg child} must contain a non-missing pair.")
  }
  counts <- table(pairs$child)
  if (any(counts > 1L)) {
    bad <- names(counts)[counts > 1L]
    .sc_abort("Each child must map to one non-missing parent; conflict{?s}: {.val {bad}}.")
  }
  pairs <- pairs[.sc_natural_order(pairs$parent), , drop = FALSE]
  parents <- unique(pairs$parent)
  anchors <- sc_palette(
    parent_palette, length(parents), extend = "generate", background = background
  )
  names(anchors) <- parents
  colors <- character()
  parent_lookup <- character()
  for (lineage in parents) {
    children <- pairs$child[pairs$parent == lineage]
    children <- children[.sc_natural_order(children)]
    variants <- .sc_child_variants(
      anchors[[lineage]], length(children), separation, background
    )
    names(variants) <- children
    colors <- c(colors, variants)
    parent_lookup <- c(parent_lookup, stats::setNames(rep(lineage, length(children)), children))
  }
  if (length(colors) > 1L) {
    audit <- sc_palette_audit(colors, cvd = "none")
    if (is.finite(audit$summary$min_distance[[1L]]) &&
        audit$summary$min_distance[[1L]] < 8) {
      .sc_warn(
        "Some hierarchy colors have weak CIE2000 separation ({round(audit$summary$min_distance[[1L]], 1)})."
      )
    }
  }
  row <- .sc_palette_row(parent_palette)
  .sc_new_map(
    colors, paste0("hierarchy:", .sc_palette_id(parent_palette)), background, na.value,
    provenance = row[, c(
      "source", "source_palette", "source_url", "source_commit",
      "citation", "license"
    ), drop = FALSE],
    parent = parent_lookup,
    parent_anchors = anchors,
    separation = separation
  )
}
