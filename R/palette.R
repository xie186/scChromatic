#' Retrieve colors from a registered palette
#'
#' Fixed qualitative palettes are truncated but never interpolated. Use
#' `extend = "generate"` to deterministically append colors while preserving
#' all selected registered colors. Continuous palettes are interpolated in Lab
#' space.
#'
#' @param palette Palette ID. See [sc_palette_names()].
#' @param n Number of colors; defaults to the registered palette capacity.
#' @param alpha Opacity in `(0, 1]`.
#' @param reverse Reverse the final color sequence.
#' @param selection Use audited `"priority"` order or exact upstream `"source"`
#'   order.
#' @param extend For qualitative oversubscription, error or generate colors.
#' @param background Background used by deterministic extension.
#' @param keep_names Preserve registered color names when possible.
#' @return A character vector of hexadecimal colors.
#' @export
#' @examples
#' sc_palette("okabe_ito", 4)
#' sc_palette("archr_stallion", 6, selection = "source")
sc_palette <- function(palette, n = NULL, alpha = 1, reverse = FALSE,
                       selection = c("priority", "source"),
                       extend = c("error", "generate"),
                       background = c("light", "dark"),
                       keep_names = FALSE) {
  selection <- match.arg(selection)
  extend <- match.arg(extend)
  background <- match.arg(background)
  alpha <- .sc_validate_alpha(alpha)
  reverse <- .sc_validate_flag(reverse, "reverse")
  keep_names <- .sc_validate_flag(keep_names, "keep_names")
  row <- .sc_palette_row(palette)
  id <- row$palette_id[[1L]]
  type <- row$palette_type[[1L]]
  n <- .sc_validate_n(n)
  if (is.null(n)) {
    n <- row$max_n[[1L]]
  }

  if (startsWith(id, "scico_")) {
    if (!requireNamespace("scico", quietly = TRUE)) {
      .sc_abort(c(
        "Palette {.val {id}} requires the optional {.pkg scico} package.",
        "i" = "Install it with {.code install.packages(\"scico\")}."
      ))
    }
    colors <- scico::scico(n, palette = sub("^scico_", "", id))
  } else if (id %in% c("viridis", "cividis", "magma")) {
    colors <- switch(
      id,
      viridis = viridisLite::viridis(n),
      cividis = viridisLite::cividis(n),
      magma = viridisLite::magma(n)
    )
  } else {
    colors <- .sc_palette_colors(id, selection)
    if (type == "qualitative") {
      if (n > length(colors)) {
        if (extend == "error") {
          .sc_abort(c(
            "Requested {n} colors from {.val {id}}, which has capacity {length(colors)}.",
            "i" = "Use {.code extend = \"generate\"} to append deterministic colors."
          ))
        }
        colors <- .sc_extend_colors(colors, n, background)
      } else {
        colors <- colors[seq_len(n)]
      }
    } else {
      colors <- grDevices::colorRampPalette(colors, space = "Lab")(n)
    }
  }

  if (reverse) {
    colors <- rev(colors)
  }
  original_names <- names(colors)
  colors <- .sc_hex(unname(colors), alpha)
  if (keep_names && length(original_names) == length(colors)) {
    names(colors) <- original_names
  }
  colors
}

#' Create a scales-compatible scChromatic palette
#'
#' @inheritParams sc_palette
#' @return A closure accepting the number of colors.
#' @export
#' @examples
#' pal <- sc_pal("chromatic")
#' pal(5)
sc_pal <- function(palette = "chromatic", alpha = 1, reverse = FALSE,
                   selection = c("priority", "source"),
                   extend = c("error", "generate"),
                   background = c("light", "dark")) {
  selection <- match.arg(selection)
  extend <- match.arg(extend)
  background <- match.arg(background)
  force(palette)
  function(n) {
    sc_palette(
      palette, n = n, alpha = alpha, reverse = reverse,
      selection = selection, extend = extend, background = background
    )
  }
}

#' List registered palette IDs
#'
#' @param type Optional palette type.
#' @param use Optional intended-use string.
#' @param source Optional source.
#' @param status Optional status.
#' @return A character vector of palette IDs.
#' @export
#' @examples
#' sc_palette_names(type = "qualitative")
sc_palette_names <- function(type = NULL, use = NULL, source = NULL, status = NULL) {
  meta <- .sc_db()$meta
  if (!is.null(type)) meta <- meta[meta$palette_type %in% type, , drop = FALSE]
  if (!is.null(use)) {
    meta <- meta[grepl(paste(use, collapse = "|"), meta$intended_use), , drop = FALSE]
  }
  if (!is.null(source)) meta <- meta[meta$source %in% source, , drop = FALSE]
  if (!is.null(status)) meta <- meta[meta$status %in% status, , drop = FALSE]
  meta$palette_id
}

#' Inspect palette metadata and provenance
#'
#' @param palette Palette ID.
#' @return A one-row data frame with registry and audit metadata.
#' @export
#' @examples
#' sc_palette_info("archr_stallion")
sc_palette_info <- function(palette) {
  .sc_palette_row(palette)
}
