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

.sc_unused_child_variants <- function(anchor, n, used, separation, background) {
  if (!n) return(character())
  target <- max(16L, length(used) + n + 8L)
  repeat {
    candidates <- unique(.sc_hex(
      .sc_child_variants(anchor, target, separation, background)
    ))
    candidates <- candidates[
      !toupper(candidates) %in% toupper(used) & !is.na(candidates)
    ]
    if (length(candidates) >= n) {
      return(candidates[seq_len(n)])
    }
    if (target >= 2048L) {
      .sc_abort("Could not generate enough distinct child variants for one parent.")
    }
    target <- target * 2L
  }
}

.sc_hierarchy_palette <- function(map) {
  if (!is.null(map$parent_palette)) {
    return(map$parent_palette)
  }
  sub("^hierarchy:", "", map$palette)
}

#' Create or extend a hierarchy-aware color map
#'
#' Child labels receive controlled lightness and chroma variants of distinct
#' parent anchor hues. Pass a prior hierarchy map through `existing` when the
#' taxonomy grows: its parent anchors and every established child assignment
#' are retained exactly, while only new parents and children receive colors.
#'
#' Each child has one canonical parent in this lightweight hierarchy model.
#' Alternative names or identifiers can be retained in the map's optional
#' `aliases` metadata and survive serialization, but multiple-parent ontology
#' graphs are outside this constructor's scope.
#'
#' @param parent Parent lineage labels.
#' @param child Child subtype labels.
#' @param parent_palette Qualitative palette for parent anchors.
#' @param separation Emphasize balanced, between-lineage, or within-lineage
#'   separation.
#' @param background Light or dark background.
#' @param na.value Missing-value color.
#' @param existing Optional `sc_color_map` previously returned by
#'   `sc_hierarchy_map()`. Existing parents, anchors, children, colors, and map
#'   metadata are retained.
#' @return An `sc_color_map` with named `parent` and `parent_anchors` fields.
#' @export
#' @examples
#' map <- sc_hierarchy_map(
#'   parent = c("Lymphoid", "Lymphoid", "Myeloid"),
#'   child = c("B", "T", "Mono")
#' )
#' sc_hierarchy_map("Lymphoid", "NK", existing = map)
sc_hierarchy_map <- function(parent, child, parent_palette = "tol_muted",
                             separation = c(
                               "balanced", "between_lineage", "within_lineage"
                             ),
                             background = c("light", "dark"),
                             na.value = "#BDBDBD", existing = NULL) {
  palette_missing <- missing(parent_palette)
  separation_missing <- missing(separation)
  background_missing <- missing(background)
  na_missing <- missing(na.value)
  if (length(parent) != length(child)) {
    .sc_abort("{.arg parent} and {.arg child} must have the same length.")
  }
  if (!is.null(existing)) {
    .sc_validate_map(existing)
    if (!identical(existing$map_type, "hierarchy") || is.null(existing$parent)) {
      .sc_abort("{.arg existing} must be a hierarchy map with parent metadata.")
    }
    stored_palette <- .sc_hierarchy_palette(existing)
    if (palette_missing) {
      parent_palette <- stored_palette
    } else if (!identical(.sc_palette_id(parent_palette), .sc_palette_id(stored_palette))) {
      .sc_abort("{.arg parent_palette} cannot change when extending a hierarchy map.")
    }
    if (separation_missing) {
      separation <- existing$separation
    } else if (!identical(match.arg(separation), existing$separation)) {
      .sc_abort("{.arg separation} cannot change when extending a hierarchy map.")
    }
    if (background_missing) {
      background <- existing$background
    } else if (!identical(match.arg(background), existing$background)) {
      .sc_abort("{.arg background} cannot change when extending a hierarchy map.")
    }
    if (na_missing) na.value <- existing$na.value
  }
  separation <- match.arg(separation)
  background <- match.arg(background)
  .sc_validate_colors(na.value, "na.value")
  if (length(na.value) != 1L) {
    .sc_abort("{.arg na.value} must be one color.")
  }
  parent <- as.character(parent)
  child <- as.character(child)
  incoming <- unique(data.frame(parent = parent, child = child, stringsAsFactors = FALSE))
  incoming <- incoming[
    !is.na(incoming$child) & !is.na(incoming$parent), , drop = FALSE
  ]
  if (any(!nzchar(trimws(incoming$parent))) || any(!nzchar(trimws(incoming$child)))) {
    .sc_abort("{.arg parent} and {.arg child} must not contain empty labels.")
  }
  prior <- if (is.null(existing)) {
    data.frame(parent = character(), child = character(), stringsAsFactors = FALSE)
  } else {
    data.frame(
      parent = unname(existing$parent[existing$labels]),
      child = existing$labels,
      stringsAsFactors = FALSE
    )
  }
  pairs <- unique(rbind(prior, incoming))
  if (!nrow(pairs)) {
    .sc_abort("{.arg parent} and {.arg child} must contain a non-missing pair.")
  }
  counts <- table(pairs$child)
  if (any(counts > 1L)) {
    bad <- names(counts)[counts > 1L]
    .sc_abort("Each child must map to one non-missing parent; conflict{?s}: {.val {bad}}.")
  }

  parents <- unique(pairs$parent[.sc_natural_order(pairs$parent)])
  row <- .sc_palette_row(parent_palette)
  if (row$palette_type[[1L]] != "qualitative") {
    .sc_abort("Parent anchors require a qualitative palette.")
  }
  colors <- if (is.null(existing)) character() else as_named_colors(existing)
  anchors <- if (is.null(existing$parent_anchors)) character() else
    existing$parent_anchors
  new_parents <- setdiff(parents, names(anchors))
  if (length(new_parents)) {
    target <- max(length(parents), row$max_n[[1L]])
    repeat {
      pool <- sc_palette(
        parent_palette, target, extend = "generate", background = background
      )
      used <- c(unname(anchors), unname(colors))
      pool <- pool[!toupper(pool) %in% toupper(used)]
      if (length(pool) >= length(new_parents)) break
      target <- target + length(new_parents) - length(pool)
    }
    additions <- pool[seq_along(new_parents)]
    names(additions) <- new_parents
    anchors <- c(anchors, additions)
  }
  anchors <- anchors[unique(c(names(anchors), parents))]

  for (lineage in parents) {
    children <- unique(pairs$child[pairs$parent == lineage])
    children <- children[.sc_natural_order(children)]
    new_children <- setdiff(children, names(colors))
    if (!length(new_children)) next
    variants <- if (is.null(existing)) {
      .sc_child_variants(
        anchors[[lineage]], length(new_children), separation, background
      )
    } else {
      .sc_unused_child_variants(
        anchors[[lineage]], length(new_children),
        c(unname(colors), unname(anchors)),
        separation, background
      )
    }
    names(variants) <- new_children
    colors <- c(colors, variants)
  }
  parent_lookup <- stats::setNames(pairs$parent[match(names(colors), pairs$child)], names(colors))

  if (length(colors) > 1L) {
    audit <- sc_palette_audit(colors, cvd = "none")
    if (is.finite(audit$summary$min_distance[[1L]]) &&
        audit$summary$min_distance[[1L]] < 8) {
      .sc_warn(
        "Some hierarchy colors have weak CIE2000 separation ({round(audit$summary$min_distance[[1L]], 1)})."
      )
    }
  }
  if (is.null(existing)) {
    return(.sc_new_map(
      colors, paste0("hierarchy:", .sc_palette_id(parent_palette)),
      background, na.value, map_type = "hierarchy",
      provenance = .sc_map_provenance(row),
      parent = parent_lookup,
      parent_anchors = anchors,
      parent_palette = .sc_palette_id(parent_palette),
      separation = separation
    ))
  }

  existing$labels <- names(colors)
  existing$colors <- unname(.sc_hex(colors))
  existing$palette <- paste0("hierarchy:", .sc_palette_id(parent_palette))
  existing$background <- background
  existing$na.value <- .sc_hex(na.value)
  existing$parent <- parent_lookup
  existing$parent_anchors <- anchors
  existing$parent_palette <- .sc_palette_id(parent_palette)
  existing$separation <- separation
  .sc_validate_map(existing)
  existing
}
