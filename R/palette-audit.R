.sc_audit_colors <- function(x) {
  if (inherits(x, "sc_color_map")) {
    return(list(colors = as_named_colors(x), palette_type = "qualitative", palette_id = x$palette))
  }
  if (is.character(x) && length(x) == 1L && !.sc_is_color(x)) {
    row <- .sc_palette_row(x)
    return(list(
      colors = sc_palette(row$palette_id[[1L]], row$max_n[[1L]], extend = "generate"),
      palette_type = row$palette_type[[1L]],
      palette_id = row$palette_id[[1L]]
    ))
  }
  if (!is.character(x)) {
    .sc_abort("{.arg x} must be a palette ID, color vector, or sc_color_map.")
  }
  list(colors = x, palette_type = NA_character_, palette_id = NA_character_)
}

.sc_distance_summary <- function(colors, mode) {
  viewed <- .sc_cvd(colors, mode)
  distance <- .sc_pairwise_distance(viewed)
  if (length(colors) < 2L) {
    return(data.frame(
      vision = mode, min_distance = NA_real_, median_distance = NA_real_,
      worst_pair = NA_character_, stringsAsFactors = FALSE
    ))
  }
  upper <- upper.tri(distance)
  values <- distance[upper]
  pairs <- which(upper, arr.ind = TRUE)
  worst <- pairs[which.min(values), , drop = FALSE]
  label <- paste(colors[worst[1L, 1L]], colors[worst[1L, 2L]], sep = " / ")
  data.frame(
    vision = mode,
    min_distance = min(values, na.rm = TRUE),
    median_distance = stats::median(values, na.rm = TRUE),
    worst_pair = label,
    stringsAsFactors = FALSE
  )
}

#' Audit palette separation and background contrast
#'
#' Contrast values are diagnostic for plotted marks and are not treated as
#' definitive WCAG pass/fail thresholds for small points.
#'
#' @param x Palette ID, color vector, or `sc_color_map`.
#' @param background Background color.
#' @param cvd Vision simulations to include.
#' @param method Color-distance method; currently `"cie2000"`.
#' @return An object of class `sc_palette_audit`.
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
  duplicate_count <- sum(duplicated(normalized))
  unique_colors <- unique(normalized)
  vision <- do.call(rbind, lapply(modes, function(mode) {
    .sc_distance_summary(unique_colors, mode)
  }))
  contrast <- if (length(unique_colors)) {
    as.numeric(colorspace::contrast_ratio(unique_colors, background))
  } else {
    numeric()
  }
  lightness <- if (length(unique_colors)) {
    farver::decode_colour(unique_colors, to = "lab")[, "l"]
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
                            length(unique_colors) >= 3L) {
    center <- unique_colors[[ceiling(length(unique_colors) / 2)]]
    endpoints <- unique_colors[c(1L, length(unique_colors))]
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
    if (length(unique_colors) > 20L) "high_cardinality_needs_redundant_encoding"
  )
  structure(
    list(
      palette_id = resolved$palette_id,
      palette_type = resolved$palette_type,
      background = .sc_hex(background),
      method = method,
      summary = summary,
      vision = vision,
      contrast = stats::setNames(contrast, unique_colors),
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
