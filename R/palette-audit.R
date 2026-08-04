.sc_audit_colors <- function(x) {
  if (inherits(x, "sc_color_map")) {
    resolved <- list(
      colors = as_named_colors(x), palette_type = "qualitative",
      palette_id = x$palette
    )
  } else if (is.character(x) && length(x) == 1L && !.sc_is_color(x)) {
    row <- .sc_palette_row(x)
    resolved <- list(
      colors = sc_palette(row$palette_id[[1L]], row$max_n[[1L]], extend = "generate"),
      palette_type = row$palette_type[[1L]],
      palette_id = row$palette_id[[1L]]
    )
  } else {
    if (!is.character(x)) {
      .sc_abort("{.arg x} must be a palette ID, color vector, or sc_color_map.")
    }
    resolved <- list(colors = x, palette_type = NA_character_, palette_id = NA_character_)
  }

  colors <- resolved$colors
  if (!length(colors)) {
    .sc_abort("{.arg x} must contain at least one color.")
  }
  labels <- names(colors)
  if (!is.null(labels)) {
    if (anyNA(labels) || any(!nzchar(trimws(labels)))) {
      .sc_abort("Named colors in {.arg x} must have a non-missing label for every color.")
    }
    if (anyDuplicated(labels)) {
      .sc_abort("Named colors in {.arg x} contain duplicate labels.")
    }
  }
  resolved
}

.sc_distance_summary <- function(colors, mode) {
  labels <- names(colors)
  viewed <- .sc_cvd(unname(colors), mode)
  distance <- .sc_pairwise_distance(viewed)
  if (length(colors) < 2L) {
    return(data.frame(
      vision = mode, min_distance = NA_real_, median_distance = NA_real_,
      worst_pair = NA_character_, worst_label_1 = NA_character_,
      worst_label_2 = NA_character_, worst_color_1 = NA_character_,
      worst_color_2 = NA_character_, stringsAsFactors = FALSE
    ))
  }
  upper <- upper.tri(distance)
  values <- distance[upper]
  pairs <- which(upper, arr.ind = TRUE)
  worst <- pairs[which.min(values), , drop = FALSE]
  index <- unname(worst[1L, ])
  pair_colors <- unname(colors[index])
  pair_labels <- if (is.null(labels)) pair_colors else labels[index]
  data.frame(
    vision = mode,
    min_distance = min(values, na.rm = TRUE),
    median_distance = stats::median(values, na.rm = TRUE),
    worst_pair = paste(pair_labels, collapse = " / "),
    worst_label_1 = if (is.null(labels)) NA_character_ else pair_labels[[1L]],
    worst_label_2 = if (is.null(labels)) NA_character_ else pair_labels[[2L]],
    worst_color_1 = pair_colors[[1L]],
    worst_color_2 = pair_colors[[2L]],
    stringsAsFactors = FALSE
  )
}

#' Audit palette separation and background contrast
#'
#' Contrast values are diagnostic for plotted marks and are not treated as
#' definitive WCAG pass/fail thresholds for small points. Fully named color
#' vectors retain their labels in the worst-pair diagnostics. Exact duplicate
#' assignments remain in the distance calculation and therefore produce a
#' zero-distance collision rather than being discarded.
#'
#' @param x Palette ID, color vector, or `sc_color_map`.
#' @param background Background color.
#' @param cvd Vision simulations to include.
#' @param method Color-distance method; currently `"cie2000"`.
#' @return An object of class `sc_palette_audit`. Its `vision` table includes
#'   the display-ready `worst_pair` plus separate label and color columns for
#'   the pair. Label columns are `NA` for unnamed color vectors.
#' @export
#' @examples
#' sc_palette_audit("okabe_ito", cvd = c("none", "deutan"))
sc_palette_audit <- function(x, background = "#FFFFFF",
                             cvd = c("none", "deutan", "protan", "tritan"),
                             method = "cie2000") {
  if (!identical(method, "cie2000")) {
    .sc_abort("{.arg method} currently supports only {.val cie2000}.")
  }
  modes <- unique(c("none", cvd))
  allowed <- c("none", "deutan", "protan", "tritan")
  if (!is.character(modes) || any(!modes %in% allowed)) {
    .sc_abort(
      "{.arg cvd} must contain values from {paste(allowed, collapse = ', ')}."
    )
  }
  .sc_validate_colors(background, "background")
  if (length(background) != 1L) {
    .sc_abort("{.arg background} must be one color.")
  }
  resolved <- .sc_audit_colors(x)
  colors <- resolved$colors
  valid <- vapply(colors, function(z) !is.na(z) && .sc_is_color(z), logical(1))
  normalized <- .sc_hex(colors[valid])
  if (!is.null(names(colors))) {
    names(normalized) <- names(colors)[valid]
  }
  duplicate_count <- sum(duplicated(normalized))
  vision <- do.call(rbind, lapply(modes, function(mode) {
    .sc_distance_summary(normalized, mode)
  }))
  contrast <- if (length(normalized)) {
    as.numeric(colorspace::contrast_ratio(normalized, background))
  } else {
    numeric()
  }
  lightness <- if (length(normalized)) {
    farver::decode_colour(normalized, to = "lab")[, "l"]
  } else {
    numeric()
  }
  monotonic <- if (identical(resolved$palette_type, "sequential") &&
                   length(lightness) > 1L) {
    all(diff(lightness) >= 0) || all(diff(lightness) <= 0)
  } else {
    NA
  }
  diverging_distinct <- if (identical(resolved$palette_type, "diverging") &&
                            length(normalized) >= 3L) {
    center <- normalized[[ceiling(length(normalized) / 2)]]
    endpoints <- normalized[c(1L, length(normalized))]
    all(.sc_pairwise_distance(center, endpoints) > 5) &&
      .sc_pairwise_distance(endpoints)[1L, 2L] > 5
  } else {
    NA
  }
  summary <- data.frame(
    n_colors = length(colors),
    invalid_color_count = sum(!valid),
    duplicate_count = duplicate_count,
    min_distance = vision$min_distance[vision$vision == "none"],
    median_distance = vision$median_distance[vision$vision == "none"],
    worst_pair = vision$worst_pair[vision$vision == "none"],
    min_contrast = if (length(contrast)) min(contrast, na.rm = TRUE) else NA_real_,
    median_contrast = if (length(contrast)) stats::median(contrast, na.rm = TRUE) else NA_real_,
    lightness_monotonic = monotonic,
    diverging_center_distinct = diverging_distinct,
    stringsAsFactors = FALSE
  )
  flags <- c(
    if (sum(!valid)) "invalid_colors",
    if (duplicate_count) "duplicate_colors",
    if (identical(monotonic, FALSE)) "non_monotonic_lightness",
    if (identical(diverging_distinct, FALSE)) "weak_diverging_structure",
    if (identical(resolved$palette_type, "qualitative") && length(colors) > 20L) {
      "high_cardinality_needs_redundant_encoding"
    }
  )
  contrast_names <- if (is.null(names(normalized))) unname(normalized) else names(normalized)
  structure(
    list(
      palette_id = resolved$palette_id,
      palette_type = resolved$palette_type,
      background = .sc_hex(background),
      method = method,
      summary = summary,
      vision = vision,
      contrast = stats::setNames(contrast, contrast_names),
      flags = flags
    ),
    class = "sc_palette_audit"
  )
}

#' @export
print.sc_palette_audit <- function(x, ...) {
  id <- if (is.na(x$palette_id)) "custom colors" else x$palette_id
  cat(sprintf("<sc_palette_audit> %s\n", id))
  print(x$summary, row.names = FALSE)
  if (length(x$flags)) {
    cat("Flags:", paste(x$flags, collapse = ", "), "\n")
  }
  invisible(x)
}

#' @export
as.data.frame.sc_palette_audit <- function(x, row.names = NULL, optional = FALSE, ...) {
  merge(x$vision, x$summary, by = NULL, suffixes = c("_vision", "_normal"))
}
