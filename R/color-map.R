.sc_existing_colors <- function(existing) {
  if (is.null(existing)) {
    return(character())
  }
  if (inherits(existing, "sc_color_map")) {
    return(as_named_colors(existing))
  }
  if (!is.character(existing) || is.null(names(existing)) || any(!nzchar(names(existing)))) {
    .sc_abort("{.arg existing} must be an sc_color_map or a fully named color vector.")
  }
  if (anyDuplicated(names(existing))) {
    .sc_abort("{.arg existing} contains duplicate label names.")
  }
  .sc_validate_colors(existing, "existing")
  existing
}

.sc_new_map <- function(colors, palette, background, na.value, provenance = NULL, ...) {
  structure(
    c(list(
      labels = names(colors),
      colors = unname(.sc_hex(colors)),
      palette = palette,
      background = background,
      package_version = as.character(utils::packageVersion("scChromatic")),
      provenance = provenance,
      na.value = .sc_hex(na.value)
    ), list(...)),
    class = "sc_color_map"
  )
}

#' Create a persistent label-to-color mapping
#'
#' Character labels use natural ordering by default. For factors,
#' `order = "factor"` includes all declared levels, including unused levels.
#' Existing assignments are retained exactly and new labels receive unused
#' colors deterministically.
#'
#' @param labels Character or factor labels.
#' @param palette Registered qualitative palette ID or `"auto"`.
#' @param existing Existing named colors or an `sc_color_map`.
#' @param order Factor-level, natural, or first-appearance ordering.
#' @param extend Generate colors or error when capacity is exceeded.
#' @param background Light or dark background.
#' @param na.value Color used for missing labels.
#' @return An object of class `sc_color_map`.
#' @export
#' @examples
#' map <- sc_color_map(c("B", "T", "NK", "Mono"))
#' as_named_colors(map)
sc_color_map <- function(labels, palette = "auto", existing = NULL,
                         order = c("factor", "natural", "appearance"),
                         extend = c("generate", "error"),
                         background = c("light", "dark"),
                         na.value = "#BDBDBD") {
  if (!is.character(labels) && !is.factor(labels)) {
    .sc_abort("{.arg labels} must be a character vector or factor.")
  }
  order <- match.arg(order)
  extend <- match.arg(extend)
  background <- match.arg(background)
  .sc_validate_colors(na.value, "na.value")
  if (length(na.value) != 1L) {
    .sc_abort("{.arg na.value} must be one color.")
  }
  ordered <- .sc_order_labels(labels, order)
  existing_colors <- .sc_existing_colors(existing)
  wanted <- unique(c(names(existing_colors), ordered))
  new_labels <- setdiff(wanted, names(existing_colors))
  id <- if (inherits(existing, "sc_color_map") && identical(palette, "auto")) {
    existing$palette
  } else {
    .sc_palette_id(palette)
  }
  row <- .sc_palette_row(id)
  if (row$palette_type[[1L]] != "qualitative") {
    .sc_abort("Persistent mappings require a qualitative palette, not {.val {id}}.")
  }

  assigned <- existing_colors
  if (length(new_labels)) {
    target <- max(length(wanted), row$max_n[[1L]])
    repeat {
      pool <- sc_palette(
        id, n = target, extend = extend, background = background,
        selection = "priority"
      )
      pool <- pool[!toupper(pool) %in% toupper(unname(assigned))]
      if (length(pool) >= length(new_labels)) break
      if (extend == "error") {
        .sc_abort("Palette {.val {id}} has no unused colors for all new labels.")
      }
      target <- target + length(new_labels) - length(pool)
    }
    additions <- pool[seq_along(new_labels)]
    names(additions) <- new_labels
    assigned <- c(assigned, additions)
  }
  assigned <- assigned[wanted]
  .sc_new_map(
    assigned, id, background, na.value,
    provenance = row[, c(
      "source", "source_palette", "source_url", "source_commit",
      "citation", "license"
    ), drop = FALSE]
  )
}

#' Extract named colors from a persistent map
#'
#' @param x An `sc_color_map`.
#' @return A named hexadecimal character vector.
#' @export
#' @examples
#' as_named_colors(sc_color_map(c("B", "T")))
as_named_colors <- function(x) {
  if (!inherits(x, "sc_color_map")) {
    .sc_abort("{.arg x} must be an sc_color_map.")
  }
  stats::setNames(x$colors, x$labels)
}

#' Update a persistent color map
#'
#' @param map An `sc_color_map`.
#' @param labels Labels to add; prior assignments are never changed.
#' @param extend Generate or error when palette capacity is exceeded.
#' @return An updated `sc_color_map`.
#' @export
#' @examples
#' map <- sc_color_map(c("B", "T"))
#' update_sc_color_map(map, c("B", "T", "NK"))
update_sc_color_map <- function(map, labels, extend = c("generate", "error")) {
  if (!inherits(map, "sc_color_map")) {
    .sc_abort("{.arg map} must be an sc_color_map.")
  }
  extend <- match.arg(extend)
  sc_color_map(
    labels,
    palette = map$palette,
    existing = map,
    order = "natural",
    extend = extend,
    background = map$background,
    na.value = map$na.value
  )
}

#' Write a persistent color map
#'
#' JSON is used for a `.json` path when jsonlite is installed; otherwise a
#' transparent two-column CSV is written.
#'
#' @param map An `sc_color_map`.
#' @param path Output path.
#' @return `path`, invisibly.
#' @export
#' @examplesIf interactive()
#' path <- tempfile(fileext = ".csv")
#' write_sc_color_map(sc_color_map(c("B", "T")), path)
write_sc_color_map <- function(map, path) {
  if (!inherits(map, "sc_color_map")) {
    .sc_abort("{.arg map} must be an sc_color_map.")
  }
  if (!is.character(path) || length(path) != 1L || is.na(path)) {
    .sc_abort("{.arg path} must be one file path.")
  }
  table <- data.frame(label = map$labels, color = map$colors, stringsAsFactors = FALSE)
  if (grepl("\\.json$", path, ignore.case = TRUE) &&
      requireNamespace("jsonlite", quietly = TRUE)) {
    payload <- list(
      palette = map$palette,
      background = map$background,
      package_version = map$package_version,
      na.value = map$na.value,
      mapping = table
    )
    jsonlite::write_json(payload, path, auto_unbox = TRUE, pretty = TRUE)
  } else {
    utils::write.csv(table, path, row.names = FALSE, quote = TRUE)
  }
  invisible(path)
}

#' Read a persistent color map
#'
#' @param path JSON or CSV path written by [write_sc_color_map()].
#' @return An `sc_color_map`.
#' @export
#' @examplesIf interactive()
#' path <- tempfile(fileext = ".csv")
#' write_sc_color_map(sc_color_map(c("B", "T")), path)
#' read_sc_color_map(path)
read_sc_color_map <- function(path) {
  if (!file.exists(path)) {
    .sc_abort("Color-map file does not exist: {.file {path}}.")
  }
  first <- readChar(path, nchars = 1L, useBytes = TRUE)
  if (identical(first, "{")) {
    if (!requireNamespace("jsonlite", quietly = TRUE)) {
      .sc_abort("Reading JSON maps requires {.pkg jsonlite}; install it or use CSV.")
    }
    payload <- jsonlite::read_json(path, simplifyVector = TRUE)
    table <- payload$mapping
    colors <- stats::setNames(as.character(table$color), as.character(table$label))
    row <- .sc_palette_row(payload$palette)
    return(.sc_new_map(
      colors, payload$palette, payload$background, payload$na.value,
      provenance = row[, c(
        "source", "source_palette", "source_url", "source_commit",
        "citation", "license"
      ), drop = FALSE]
    ))
  }
  table <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  if (!identical(names(table), c("label", "color"))) {
    .sc_abort("CSV color maps must contain exactly {.field label} and {.field color} columns.")
  }
  colors <- stats::setNames(table$color, table$label)
  .sc_new_map(colors, "external", "light", "#BDBDBD", provenance = NULL)
}

#' @export
print.sc_color_map <- function(x, ...) {
  cat(format(x), sep = "\n")
  invisible(x)
}

#' @export
format.sc_color_map <- function(x, ...) {
  header <- sprintf(
    "<sc_color_map[%d]> palette: %s; background: %s",
    length(x$labels), x$palette, x$background
  )
  entries <- sprintf("  %s: %s", x$labels, x$colors)
  c(header, entries)
}

#' @export
as.data.frame.sc_color_map <- function(x, row.names = NULL, optional = FALSE, ...) {
  out <- data.frame(label = x$labels, color = x$colors, stringsAsFactors = FALSE)
  if (!is.null(x$parent)) {
    out$parent <- unname(x$parent[x$labels])
  }
  out
}

#' @export
`[.sc_color_map` <- function(x, i, ...) {
  colors <- as_named_colors(x)[i]
  colors <- colors[!is.na(colors)]
  extra <- if (!is.null(x$parent)) list(parent = x$parent[names(colors)]) else list()
  do.call(
    .sc_new_map,
    c(list(
      colors = colors,
      palette = x$palette,
      background = x$background,
      na.value = x$na.value,
      provenance = x$provenance
    ), extra)
  )
}
