.sc_abort <- function(message, ..., call = NULL) {
  cli::cli_abort(message, ..., call = call, .envir = parent.frame())
}

.sc_warn <- function(message, ..., call = NULL) {
  cli::cli_warn(message, ..., call = call, .envir = parent.frame())
}

.sc_arg_match <- function(arg, choices, arg_name = deparse(substitute(arg))) {
  if (length(arg) > 1L) {
    arg <- arg[[1L]]
  }
  if (!is.character(arg) || length(arg) != 1L || is.na(arg) || !arg %in% choices) {
    .sc_abort(
      "{.arg {arg_name}} must be one of {paste(choices, collapse = ', ')}."
    )
  }
  arg
}

.sc_validate_flag <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    .sc_abort("{.arg {name}} must be a single TRUE or FALSE.")
  }
  x
}

.sc_validate_alpha <- function(alpha) {
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) ||
      alpha <= 0 || alpha > 1) {
    .sc_abort("{.arg alpha} must be a finite scalar in (0, 1].")
  }
  alpha
}

.sc_validate_n <- function(n, allow_null = TRUE) {
  if (allow_null && is.null(n)) {
    return(NULL)
  }
  if (!is.numeric(n) || length(n) != 1L || !is.finite(n) || n < 1 ||
      n != as.integer(n)) {
    .sc_abort("{.arg n} must be a positive whole number.")
  }
  as.integer(n)
}

.sc_hex <- function(x, alpha = 1) {
  valid <- !is.na(x) & vapply(x, .sc_is_color, logical(1))
  out <- rep(NA_character_, length(x))
  if (any(valid)) {
    rgb <- grDevices::col2rgb(x[valid], alpha = TRUE)
    out[valid] <- grDevices::rgb(
      rgb[1L, ], rgb[2L, ], rgb[3L, ],
      alpha = round(rgb[4L, ] * alpha),
      maxColorValue = 255
    )
    if (alpha == 1 && all(rgb[4L, ] == 255)) {
      out[valid] <- substr(out[valid], 1L, 7L)
    }
  }
  toupper(out)
}

.sc_is_color <- function(x) {
  tryCatch({
    grDevices::col2rgb(x)
    TRUE
  }, error = function(e) FALSE)
}

.sc_validate_colors <- function(x, name = "x", allow_na = FALSE) {
  if (!is.character(x)) {
    .sc_abort("{.arg {name}} must be a character vector of colors.")
  }
  ok <- vapply(x, function(z) {
    if (is.na(z)) {
      return(allow_na)
    }
    .sc_is_color(z)
  }, logical(1))
  if (!all(ok)) {
    .sc_abort("{.arg {name}} contains invalid colors at position{?s} {which(!ok)}.")
  }
  invisible(x)
}

.sc_natural_order <- function(x) {
  key <- vapply(tolower(x), function(z) {
    parts <- regmatches(z, gregexpr("[0-9]+|[^0-9]+", z, perl = TRUE))[[1L]]
    paste(vapply(parts, function(p) {
      if (grepl("^[0-9]+$", p)) sprintf("%020.0f", as.numeric(p)) else p
    }, character(1)), collapse = "")
  }, character(1))
  order(key, x, method = "radix", na.last = TRUE)
}

.sc_order_labels <- function(labels, order) {
  order <- .sc_arg_match(order, c("factor", "natural", "appearance"), "order")
  if (is.factor(labels) && order == "factor") {
    return(levels(labels))
  }
  labels <- as.character(labels)
  labels <- labels[!is.na(labels)]
  labels <- unique(labels)
  if (order == "natural" || order == "factor") {
    labels[.sc_natural_order(labels)]
  } else {
    labels
  }
}

.sc_cvd <- function(colors, mode) {
  switch(
    mode,
    none = colors,
    deutan = colorspace::deutan(colors),
    protan = colorspace::protan(colors),
    tritan = colorspace::tritan(colors)
  )
}

.sc_palette_id <- function(palette) {
  if (!is.character(palette) || length(palette) != 1L || is.na(palette)) {
    .sc_abort("{.arg palette} must be a single palette ID.")
  }
  if (palette == "auto") {
    return("chromatic")
  }
  id <- tolower(gsub("([a-z0-9])([A-Z])", "\\1_\\2", palette))
  id <- gsub("[^a-z0-9]+", "_", id)
  id <- gsub("^_|_$", "", id)
  id
}
