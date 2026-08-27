.sc_color_map_schema_name <- "scChromatic.color-map"
.sc_color_map_schema_version <- 1L

.sc_one_string <- function(x, name) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(trimws(x))) {
    .sc_abort("{.field {name}} must be one non-empty string.")
  }
  x
}

.sc_map_type <- function(palette) {
  if (startsWith(palette, "hierarchy:")) {
    "hierarchy"
  } else if (startsWith(palette, "highlight:")) {
    "highlight"
  } else if (identical(palette, "external")) {
    "external"
  } else if (startsWith(palette, "derived:")) {
    "derived"
  } else {
    "registered"
  }
}

.sc_package_version <- function() {
  tryCatch(
    as.character(utils::packageVersion("scChromatic")),
    error = function(e) "development"
  )
}

.sc_map_provenance <- function(row) {
  fields <- c(
    "source", "source_palette", "source_url", "source_version",
    "source_sha256", "source_commit", "citation", "license", "derived",
    "source_cvd_claim"
  )
  row <- row[, intersect(fields, names(row)), drop = FALSE]
  unname(lapply(seq_len(nrow(row)), function(i) {
    record <- lapply(row, function(x) unname(x[[i]]))
    keep <- !vapply(record, function(x) {
      is.na(x) || (is.character(x) && !nzchar(x))
    }, logical(1))
    record[keep]
  }))
}

.sc_validate_map <- function(map) {
  if (!inherits(map, "sc_color_map")) {
    .sc_abort("{.arg map} must be an sc_color_map.")
  }
  required <- c(
    "schema", "schema_version", "map_type", "labels", "colors", "palette",
    "background", "package_version", "na.value"
  )
  missing <- setdiff(required, names(map))
  if (length(missing)) {
    .sc_abort("Color map is missing required field{?s}: {.field {missing}}.")
  }
  if (!identical(map$schema, .sc_color_map_schema_name)) {
    .sc_abort("Unsupported color-map schema {.val {map$schema}}.")
  }
  version <- map$schema_version
  if (!is.numeric(version) || length(version) != 1L || is.na(version) ||
      version != as.integer(version)) {
    .sc_abort("Color-map {.field schema_version} must be a whole number.")
  }
  if (as.integer(version) != .sc_color_map_schema_version) {
    supported <- .sc_color_map_schema_version
    .sc_abort(
      "Unsupported color-map schema version {version}; this package supports version {.val {supported}}."
    )
  }
  .sc_one_string(map$map_type, "map_type")
  map_types <- c("registered", "external", "derived", "hierarchy", "highlight")
  if (!map$map_type %in% map_types) {
    .sc_abort("Color-map {.field map_type} must be one of {paste(map_types, collapse = ', ')}.")
  }
  .sc_one_string(map$palette, "palette")
  .sc_one_string(map$package_version, "package_version")
  if (!is.character(map$labels) || !length(map$labels) || anyNA(map$labels) ||
      any(!nzchar(trimws(map$labels)))) {
    .sc_abort("Color-map labels must contain at least one non-empty string.")
  }
  if (anyDuplicated(map$labels)) {
    .sc_abort("Color-map labels must be unique.")
  }
  if (!is.character(map$colors) || length(map$colors) != length(map$labels)) {
    .sc_abort("Color-map colors must be a character vector aligned with labels.")
  }
  .sc_validate_colors(map$colors, "map colors")
  if (!is.character(map$background) || length(map$background) != 1L ||
      is.na(map$background) || !map$background %in% c("light", "dark")) {
    .sc_abort("Color-map {.field background} must be {.val light} or {.val dark}.")
  }
  .sc_validate_colors(map$na.value, "map na.value")
  if (length(map$na.value) != 1L) {
    .sc_abort("Color-map {.field na.value} must be one color.")
  }

  if (!is.null(map$parent)) {
    parent <- map$parent
    if (!is.character(parent) || is.null(names(parent)) || anyNA(names(parent)) ||
        any(!nzchar(trimws(names(parent)))) || anyDuplicated(names(parent)) ||
        anyNA(parent) || any(!nzchar(trimws(parent)))) {
      .sc_abort("Color-map {.field parent} must be a uniquely named character vector.")
    }
    if (!all(names(parent) %in% map$labels)) {
      .sc_abort("Color-map {.field parent} contains labels absent from the mapping.")
    }
  }
  if (!is.null(map$parent_anchors)) {
    anchors <- map$parent_anchors
    if (!is.character(anchors) || is.null(names(anchors)) || anyNA(names(anchors)) ||
        any(!nzchar(trimws(names(anchors)))) || anyDuplicated(names(anchors))) {
      .sc_abort("Color-map {.field parent_anchors} must be a uniquely named color vector.")
    }
    .sc_validate_colors(anchors, "map parent_anchors")
    if (!is.null(map$parent) && !all(unique(map$parent) %in% names(anchors))) {
      .sc_abort("Color-map {.field parent_anchors} must cover every stored parent.")
    }
  }
  if (identical(map$map_type, "hierarchy") &&
      (is.null(map$parent) || !all(map$labels %in% names(map$parent)) ||
       is.null(map$parent_anchors) || is.null(map$parent_palette) ||
       is.null(map$separation))) {
    .sc_abort(
      "Hierarchy maps require parent, parent_anchors, parent_palette, and separation metadata."
    )
  }
  if (!is.null(map$focus)) {
    if (!is.character(map$focus) || anyNA(map$focus) || anyDuplicated(map$focus) ||
        !all(map$focus %in% map$labels)) {
      .sc_abort("Color-map {.field focus} must contain unique mapped labels.")
    }
  }
  if (!is.null(map$locks)) {
    locks <- map$locks
    valid <- if (is.character(locks)) {
      !anyNA(locks) && !anyDuplicated(locks) && all(locks %in% map$labels)
    } else if (is.logical(locks) && !is.null(names(locks))) {
      !anyNA(locks) && !anyNA(names(locks)) &&
        !anyDuplicated(names(locks)) && all(names(locks) %in% map$labels)
    } else {
      FALSE
    }
    if (!valid) {
      .sc_abort(
        "Color-map {.field locks} must be mapped label names or a uniquely named logical vector."
      )
    }
  }
  if (!is.null(map$aliases)) {
    aliases <- map$aliases
    if (!is.character(aliases) || is.null(names(aliases)) || anyNA(aliases) ||
        anyNA(names(aliases)) || any(!nzchar(trimws(names(aliases)))) ||
        anyDuplicated(names(aliases)) || !all(aliases %in% map$labels)) {
      .sc_abort(
        "Color-map {.field aliases} must map unique alias names to stored labels."
      )
    }
  }
  if (!is.null(map$context) && !is.list(map$context)) {
    .sc_abort("Color-map {.field context} must be a list when supplied.")
  }
  if (!is.null(map$history) && !is.list(map$history)) {
    .sc_abort("Color-map {.field history} must be a list or data frame when supplied.")
  }
  if (!is.null(map$metadata) && !is.list(map$metadata)) {
    .sc_abort("Color-map {.field metadata} must be a list when supplied.")
  }
  if (!is.null(map$provenance) && !is.list(map$provenance)) {
    .sc_abort("Color-map {.field provenance} must be a list of records when supplied.")
  }
  if (!is.null(map$parent_palette)) .sc_one_string(map$parent_palette, "parent_palette")
  if (!is.null(map$focus_palette)) .sc_one_string(map$focus_palette, "focus_palette")
  if (!is.null(map$separation) &&
      (!is.character(map$separation) || length(map$separation) != 1L ||
       !map$separation %in% c("balanced", "between_lineage", "within_lineage"))) {
    .sc_abort("Color-map {.field separation} is invalid.")
  }
  if (!is.null(map$other)) {
    .sc_validate_colors(map$other, "map other")
    if (length(map$other) != 1L) .sc_abort("Color-map {.field other} must be one color.")
  }
  if (identical(map$map_type, "highlight") &&
      (is.null(map$focus) || is.null(map$focus_palette) || is.null(map$other))) {
    .sc_abort("Highlight maps require focus, focus_palette, and other metadata.")
  }
  if (!is.null(map$seed) &&
      (!is.numeric(map$seed) || length(map$seed) != 1L || !is.finite(map$seed))) {
    .sc_abort("Color-map {.field seed} must be one finite number when supplied.")
  }
  invisible(map)
}

.sc_existing_colors <- function(existing) {
  if (is.null(existing)) {
    return(character())
  }
  if (inherits(existing, "sc_color_map")) {
    .sc_validate_map(existing)
    return(as_named_colors(existing))
  }
  if (!is.character(existing) || is.null(names(existing)) || anyNA(names(existing)) ||
      any(!nzchar(trimws(names(existing))))) {
    .sc_abort("{.arg existing} must be an sc_color_map or a fully named color vector.")
  }
  if (anyDuplicated(names(existing))) {
    .sc_abort("{.arg existing} contains duplicate label names.")
  }
  .sc_validate_colors(existing, "existing")
  existing
}

.sc_new_map <- function(colors, palette, background, na.value, provenance = NULL,
                        map_type = NULL, package_version = .sc_package_version(), ...) {
  if (!is.character(colors) || (length(colors) && is.null(names(colors))) ||
      anyNA(names(colors)) || any(!nzchar(trimws(names(colors)))) ||
      anyDuplicated(names(colors))) {
    .sc_abort("Map colors must be a uniquely named character vector.")
  }
  .sc_validate_colors(colors, "colors")
  palette <- .sc_one_string(palette, "palette")
  if (is.null(map_type)) {
    map_type <- .sc_map_type(palette)
  }
  extras <- list(...)
  reserved <- intersect(
    names(extras),
    c(
      "schema", "schema_version", "map_type", "labels", "colors", "palette",
      "background", "package_version", "na.value", "provenance"
    )
  )
  if (length(reserved)) {
    .sc_abort("Map metadata cannot replace reserved field{?s}: {.field {reserved}}.")
  }
  map <- structure(
    c(list(
      schema = .sc_color_map_schema_name,
      schema_version = .sc_color_map_schema_version,
      map_type = map_type,
      labels = names(colors),
      colors = unname(.sc_hex(colors)),
      palette = palette,
      background = background,
      package_version = package_version,
      na.value = .sc_hex(na.value),
      provenance = provenance
    ), extras),
    class = "sc_color_map"
  )
  .sc_validate_map(map)
  map
}

.sc_palette_row_or_null <- function(palette) {
  id <- .sc_palette_id(palette)
  hit <- which(.sc_db()$meta$palette_id == id)
  if (!length(hit)) {
    return(NULL)
  }
  .sc_db()$meta[hit[[1L]], , drop = FALSE]
}

.sc_extend_map <- function(map, labels, extend, background = map$background) {
  .sc_validate_map(map)
  ordered <- .sc_order_labels(labels, "natural")
  if (any(!nzchar(trimws(ordered)))) {
    .sc_abort("{.arg labels} must not contain empty strings.")
  }
  assigned <- as_named_colors(map)
  wanted <- unique(c(names(assigned), ordered))
  new_labels <- setdiff(wanted, names(assigned))
  if (!length(new_labels)) {
    return(map)
  }
  if (identical(map$palette, "derived:relationship-v1")) {
    .sc_abort(c(
      "Relationship maps require relationship values for every new label.",
      "i" = "Rerun {.fun sc_relationship_map} with an expanded matrix and {.arg canonical} set to this map."
    ))
  }
  if (identical(map$map_type, "hierarchy")) {
    .sc_abort(c(
      "Hierarchy maps require a parent for every new child.",
      "i" = "Call {.fun sc_hierarchy_map} with {.arg existing} to extend this map."
    ))
  }

  additions <- NULL
  if (identical(map$map_type, "highlight")) {
    additions <- rep(map$other, length(new_labels))
  } else {
    row <- .sc_palette_row_or_null(map$palette)
    registered <- !is.null(row) && identical(row$palette_type[[1L]], "qualitative")
    if (registered) {
      target <- max(length(wanted), row$max_n[[1L]])
      repeat {
        pool <- sc_palette(
          map$palette, n = target, extend = extend, background = background,
          selection = "priority"
        )
        pool <- pool[!toupper(pool) %in% toupper(unname(assigned))]
        if (length(pool) >= length(new_labels)) {
          break
        }
        if (extend == "error") {
          .sc_abort("Palette {.val {map$palette}} has no unused colors for all new labels.")
        }
        target <- target + length(new_labels) - length(pool)
      }
      additions <- pool[seq_along(new_labels)]
    } else {
      if (extend == "error") {
        .sc_abort(c(
          "Map palette {.val {map$palette}} is not a registered qualitative palette.",
          "i" = "Use {.code extend = \"generate\"} to append deterministic colors."
        ))
      }
      generated <- .sc_extend_colors(
        unname(assigned), length(assigned) + length(new_labels), background
      )
      additions <- generated[length(assigned) + seq_along(new_labels)]
    }
  }
  names(additions) <- new_labels
  assigned <- c(assigned, additions)[wanted]
  map$labels <- names(assigned)
  map$colors <- unname(.sc_hex(assigned))
  map$background <- background
  .sc_validate_map(map)
  map
}

#' Create a persistent label-to-color mapping
#'
#' Character labels use natural ordering by default. For factors,
#' `order = "factor"` includes all declared levels, including unused levels.
#' Existing assignments are retained exactly and new labels receive unused
#' colors deterministically. Supplying an existing map with `palette = "auto"`
#' also preserves its schema metadata and does not require its palette to be
#' registered.
#'
#' @param labels One or more non-missing, non-empty character or factor labels.
#' @param palette Registered qualitative palette ID or `"auto"`.
#' @param existing Existing named colors or an `sc_color_map`.
#' @param order Factor-level, natural, or first-appearance ordering.
#' @param extend Generate colors or error when capacity is exceeded.
#' @param background Light or dark background.
#' @param na.value Color used for missing labels.
#' @return An object of class `sc_color_map` using the current versioned map
#'   schema.
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
  ordered <- .sc_order_labels(labels, order)
  if (any(!nzchar(trimws(ordered)))) {
    .sc_abort("{.arg labels} must not contain empty strings.")
  }
  if (inherits(existing, "sc_color_map") && identical(palette, "auto")) {
    background <- if (missing(background)) existing$background else match.arg(background)
    if (!missing(na.value)) {
      .sc_validate_colors(na.value, "na.value")
      if (length(na.value) != 1L) {
        .sc_abort("{.arg na.value} must be one color.")
      }
      existing$na.value <- .sc_hex(na.value)
    }
    return(.sc_extend_map(existing, ordered, extend, background))
  }

  background <- match.arg(background)
  .sc_validate_colors(na.value, "na.value")
  if (length(na.value) != 1L) {
    .sc_abort("{.arg na.value} must be one color.")
  }
  existing_colors <- .sc_existing_colors(existing)
  wanted <- unique(c(names(existing_colors), ordered))
  new_labels <- setdiff(wanted, names(existing_colors))
  id <- .sc_palette_id(palette)
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
    assigned, id, background, na.value, map_type = "registered",
    provenance = .sc_map_provenance(row)
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
  .sc_validate_map(x)
  stats::setNames(x$colors, x$labels)
}

#' Update a persistent color map
#'
#' Existing assignments and all map metadata are preserved. Registered maps
#' reuse their qualitative palette; external and derived maps are extended from
#' their stored colors and therefore do not need a palette-registry entry.
#' Hierarchy maps must instead be extended with [sc_hierarchy_map()] so every
#' new child has a parent.
#'
#' @param map An `sc_color_map`.
#' @param labels Labels to add; prior assignments are never changed.
#' @param extend Generate or error when capacity is exceeded.
#' @return An updated `sc_color_map` using the same schema and metadata.
#' @export
#' @examples
#' map <- sc_color_map(c("B", "T"))
#' update_sc_color_map(map, c("B", "T", "NK"))
update_sc_color_map <- function(map, labels, extend = c("generate", "error")) {
  .sc_validate_map(map)
  if (!is.character(labels) && !is.factor(labels)) {
    .sc_abort("{.arg labels} must be a character vector or factor.")
  }
  extend <- match.arg(extend)
  .sc_extend_map(map, labels, extend)
}

.sc_validate_json_native <- function(x, path = "metadata") {
  if (is.null(x)) return(invisible(x))
  if (is.data.frame(x)) {
    if (anyDuplicated(names(x)) || any(!nzchar(names(x)))) {
      .sc_abort("JSON data-frame field names at {path} must be non-empty and unique.")
    }
    for (i in seq_along(x)) {
      .sc_validate_json_native(x[[i]], paste0(path, "$", names(x)[[i]]))
    }
    return(invisible(x))
  }
  if (is.list(x)) {
    if (!identical(class(x), "list")) {
      .sc_abort("Color-map field {path} has unsupported class {.val {class(x)}}.")
    }
    if (!is.null(names(x)) &&
        (any(!nzchar(names(x))) || anyDuplicated(names(x)))) {
      .sc_abort("JSON object names at {path} must be non-empty and unique.")
    }
    for (i in seq_along(x)) {
      .sc_validate_json_native(x[[i]], paste0(path, "[[", i, "]]"))
    }
    return(invisible(x))
  }
  if (!is.atomic(x) || is.factor(x) || is.object(x) ||
      !typeof(x) %in% c("character", "logical", "integer", "double")) {
    .sc_abort(
      "Color-map field {path} must use JSON-native strings, booleans, finite numbers, arrays, or objects."
    )
  }
  if (anyNA(x) || (is.numeric(x) && any(!is.finite(x)))) {
    .sc_abort("Color-map field {path} contains a missing or non-finite value.")
  }
  attributes <- setdiff(names(attributes(x)), "names")
  if (length(attributes)) {
    .sc_abort("Color-map field {path} has unsupported attribute{?s}: {.field {attributes}}.")
  }
  if (!is.null(names(x)) &&
      (any(!nzchar(names(x))) || anyDuplicated(names(x)))) {
    .sc_abort("JSON object names at {path} must be non-empty and unique.")
  }
  invisible(x)
}

.sc_pair_records <- function(x, key, value) {
  unname(lapply(seq_along(x), function(i) {
    stats::setNames(list(names(x)[[i]], unname(x[[i]])), c(key, value))
  }))
}

.sc_payload_pairs <- function(x, key, value, field) {
  if (is.data.frame(x)) {
    if (!all(c(key, value) %in% names(x))) {
      .sc_abort("Color-map {.field {field}} records require {.field {key}} and {.field {value}}.")
    }
    left <- as.character(x[[key]])
    right <- as.character(x[[value]])
  } else if (is.list(x)) {
    left <- vapply(seq_along(x), function(i) {
      .sc_one_string(x[[i]][[key]], paste0(field, "[[", i, "]]$", key))
    }, character(1))
    right <- vapply(seq_along(x), function(i) {
      .sc_one_string(x[[i]][[value]], paste0(field, "[[", i, "]]$", value))
    }, character(1))
  } else {
    .sc_abort("Color-map {.field {field}} must be an array of records.")
  }
  if (anyNA(left) || anyNA(right) || any(!nzchar(left)) || any(!nzchar(right)) ||
      anyDuplicated(left)) {
    .sc_abort("Color-map {.field {field}} records must have unique non-empty keys and values.")
  }
  stats::setNames(right, left)
}

.sc_map_payload <- function(map) {
  .sc_validate_map(map)
  payload <- list(
    schema = map$schema,
    schema_version = map$schema_version,
    map_type = map$map_type,
    palette = map$palette,
    background = map$background,
    package_version = map$package_version,
    na_value = map$na.value,
    mapping = unname(lapply(seq_along(map$labels), function(i) {
      list(label = map$labels[[i]], color = map$colors[[i]])
    }))
  )
  direct <- c(
    "provenance", "parent_palette", "separation", "focus_palette", "other",
    "history", "context", "seed", "metadata"
  )
  for (field in direct) {
    if (!is.null(map[[field]])) {
      .sc_validate_json_native(map[[field]], field)
      payload[[field]] <- map[[field]]
    }
  }
  if (!is.null(map$parent)) {
    payload$parent <- .sc_pair_records(map$parent, "label", "parent")
  }
  if (!is.null(map$parent_anchors)) {
    payload$parent_anchors <- .sc_pair_records(
      map$parent_anchors, "parent", "color"
    )
  }
  if (!is.null(map$focus)) {
    payload$focus <- as.list(unname(map$focus))
  }
  if (!is.null(map$aliases)) {
    payload$aliases <- .sc_pair_records(map$aliases, "alias", "label")
  }
  if (!is.null(map$locks)) {
    locks <- if (is.character(map$locks)) {
      stats::setNames(rep(TRUE, length(map$locks)), map$locks)
    } else {
      map$locks
    }
    payload$locks <- unname(lapply(seq_along(locks), function(i) {
      list(label = names(locks)[[i]], locked = unname(locks[[i]]))
    }))
  }
  known <- c(
    "schema", "schema_version", "map_type", "labels", "colors", "palette",
    "background", "package_version", "na.value", direct, "parent",
    "parent_anchors", "focus", "aliases", "locks"
  )
  extra_names <- setdiff(names(unclass(map)), known)
  if (length(extra_names)) {
    extensions <- unclass(map)[extra_names]
    .sc_validate_json_native(extensions, "extensions")
    payload$extensions <- extensions
  }
  payload
}

.sc_payload_mapping <- function(mapping) {
  if (is.data.frame(mapping)) {
    if (!all(c("label", "color") %in% names(mapping))) {
      .sc_abort("Color-map mapping records require {.field label} and {.field color}.")
    }
    labels <- as.character(mapping$label)
    colors <- as.character(mapping$color)
  } else if (is.list(mapping)) {
    labels <- vapply(seq_along(mapping), function(i) {
      record <- mapping[[i]]
      if (!is.list(record)) .sc_abort("Color-map mapping record {i} is malformed.")
      .sc_one_string(record$label, paste0("mapping[[", i, "]]$label"))
    }, character(1))
    colors <- vapply(seq_along(mapping), function(i) {
      record <- mapping[[i]]
      .sc_one_string(record$color, paste0("mapping[[", i, "]]$color"))
    }, character(1))
  } else {
    .sc_abort("Color-map {.field mapping} must be an array of label/color records.")
  }
  if (length(labels) != length(colors) || anyNA(labels) ||
      any(!nzchar(trimws(labels))) || anyDuplicated(labels)) {
    .sc_abort("Color-map mapping labels must be non-missing, non-empty, and unique.")
  }
  .sc_validate_colors(colors, "mapping colors")
  stats::setNames(colors, labels)
}

.sc_payload_character_array <- function(x, field) {
  if (is.character(x)) {
    out <- unname(x)
  } else if (is.list(x)) {
    out <- vapply(seq_along(x), function(i) {
      .sc_one_string(x[[i]], paste0(field, "[[", i, "]]"))
    }, character(1))
  } else {
    .sc_abort("Color-map {.field {field}} must be an array of strings.")
  }
  if (anyNA(out) || any(!nzchar(out)) || anyDuplicated(out)) {
    .sc_abort("Color-map {.field {field}} must contain unique non-empty strings.")
  }
  out
}

.sc_payload_locks <- function(x) {
  if (is.data.frame(x)) {
    if (!all(c("label", "locked") %in% names(x))) {
      .sc_abort("Color-map {.field locks} records require label and locked fields.")
    }
    labels <- as.character(x$label)
    locked <- as.logical(x$locked)
  } else if (is.list(x)) {
    labels <- vapply(seq_along(x), function(i) {
      .sc_one_string(x[[i]]$label, paste0("locks[[", i, "]]$label"))
    }, character(1))
    locked <- vapply(seq_along(x), function(i) {
      value <- x[[i]]$locked
      if (!is.logical(value) || length(value) != 1L || is.na(value)) {
        .sc_abort("Color-map {.field locks} values must be true or false.")
      }
      value
    }, logical(1))
  } else {
    .sc_abort("Color-map {.field locks} must be an array of records.")
  }
  if (anyNA(labels) || any(!nzchar(labels)) || anyDuplicated(labels) || anyNA(locked)) {
    .sc_abort("Color-map {.field locks} labels must be non-empty and unique.")
  }
  stats::setNames(locked, labels)
}

.sc_payload_records <- function(x, field) {
  if (is.null(x)) return(NULL)
  if (is.data.frame(x)) {
    return(unname(lapply(seq_len(nrow(x)), function(i) {
      lapply(x, function(column) unname(column[[i]]))
    })))
  }
  if (!is.list(x)) {
    .sc_abort("Color-map {.field {field}} must be an array or object.")
  }
  x
}

.sc_payload_from_json <- function(json) {
  payload <- jsonlite::fromJSON(json, simplifyVector = TRUE)
  records <- jsonlite::fromJSON(
    json, simplifyVector = TRUE, simplifyDataFrame = FALSE
  )
  fields <- intersect(c("provenance", "history"), names(records))
  payload[fields] <- records[fields]
  payload
}

.sc_map_from_payload <- function(payload) {
  if (!is.list(payload)) {
    .sc_abort("Color-map JSON must contain an object.")
  }
  allowed <- c(
    "schema", "schema_version", "map_type", "palette", "background",
    "package_version", "na_value", "mapping", "provenance", "parent",
    "parent_anchors", "parent_palette", "separation", "focus",
    "focus_palette", "other", "aliases", "locks", "history", "context",
    "seed", "metadata", "extensions"
  )
  unknown <- setdiff(names(payload), allowed)
  if (length(unknown)) {
    .sc_abort("Unknown color-map payload field{?s}: {.field {unknown}}.")
  }
  schema <- .sc_one_string(payload$schema, "schema")
  if (!identical(schema, .sc_color_map_schema_name)) {
    .sc_abort("Unsupported color-map schema {.val {schema}}.")
  }
  version <- payload$schema_version
  if (!is.numeric(version) || length(version) != 1L || is.na(version) ||
      version != as.integer(version)) {
    .sc_abort("Color-map {.field schema_version} must be a whole number.")
  }
  if (as.integer(version) != .sc_color_map_schema_version) {
    supported <- .sc_color_map_schema_version
    .sc_abort(
      "Unsupported color-map schema version {version}; this package supports version {.val {supported}}."
    )
  }
  colors <- .sc_payload_mapping(payload$mapping)
  map_type <- .sc_one_string(payload$map_type, "map_type")
  palette <- .sc_one_string(payload$palette, "palette")
  background <- .sc_one_string(payload$background, "background")
  package_version <- .sc_one_string(payload$package_version, "package_version")
  na.value <- .sc_one_string(payload$na_value, "na_value")
  metadata <- list(provenance = .sc_payload_records(payload$provenance, "provenance"))
  if (!is.null(payload$parent)) {
    metadata$parent <- .sc_payload_pairs(payload$parent, "label", "parent", "parent")
  }
  if (!is.null(payload$parent_anchors)) {
    metadata$parent_anchors <- .sc_payload_pairs(
      payload$parent_anchors, "parent", "color", "parent_anchors"
    )
  }
  if (!is.null(payload$focus)) {
    metadata$focus <- .sc_payload_character_array(payload$focus, "focus")
  }
  if (!is.null(payload$aliases)) {
    metadata$aliases <- .sc_payload_pairs(payload$aliases, "alias", "label", "aliases")
  }
  if (!is.null(payload$locks)) {
    metadata$locks <- .sc_payload_locks(payload$locks)
  }
  direct <- c(
    "parent_palette", "separation", "focus_palette", "other", "context",
    "metadata"
  )
  for (field in direct) {
    if (!is.null(payload[[field]])) metadata[[field]] <- payload[[field]]
  }
  if (!is.null(payload$history)) {
    metadata$history <- .sc_payload_records(payload$history, "history")
  }
  if (!is.null(payload$seed)) metadata$seed <- as.numeric(payload$seed)
  if (!is.null(payload$extensions)) {
    extensions <- payload$extensions
    if (!is.list(extensions) || is.null(names(extensions)) ||
        any(!nzchar(names(extensions))) || anyDuplicated(names(extensions))) {
      .sc_abort("Color-map {.field extensions} must be an object with unique field names.")
    }
    reserved <- intersect(names(extensions), c(allowed, "labels", "colors", "na.value"))
    if (length(reserved)) {
      .sc_abort("Color-map extensions cannot replace reserved field{?s}: {.field {reserved}}.")
    }
    metadata <- c(metadata, extensions)
  }
  for (field in names(metadata)) {
    .sc_validate_json_native(metadata[[field]], field)
  }
  map <- structure(c(list(
    schema = schema,
    schema_version = as.integer(version),
    map_type = map_type,
    labels = names(colors),
    colors = unname(.sc_hex(colors)),
    palette = palette,
    background = background,
    package_version = package_version,
    na.value = .sc_hex(na.value)
  ), metadata), class = "sc_color_map")
  .sc_validate_map(map)
  map
}

.sc_legacy_json_map <- function(payload) {
  colors <- .sc_payload_mapping(payload$mapping)
  palette <- .sc_one_string(payload$palette, "palette")
  background <- if (is.null(payload$background)) "light" else
    .sc_one_string(payload$background, "background")
  na.value <- payload$na.value
  if (is.null(na.value)) na.value <- payload$na_value
  if (is.null(na.value)) na.value <- "#BDBDBD"
  package_version <- if (is.null(payload$package_version)) "legacy" else
    .sc_one_string(payload$package_version, "package_version")
  map_type <- .sc_map_type(palette)
  if (map_type %in% c("hierarchy", "highlight") ||
      (identical(map_type, "registered") && is.null(.sc_palette_row_or_null(palette)))) {
    map_type <- "external"
  }
  .sc_new_map(
    colors, palette, background, .sc_one_string(na.value, "na.value"),
    map_type = map_type, package_version = package_version,
    provenance = if (is.null(payload$provenance)) NULL else payload$provenance
  )
}

#' Write a persistent color map
#'
#' JSON files follow the installed `sc-color-map.schema.json` schema. CSV files
#' keep transparent `label` and `color` rows and store the same complete,
#' schema-versioned JSON payload in one metadata row, so neither format loses
#' hierarchy, focus, provenance, locks, aliases, history, context, seed, or
#' future JSON-compatible metadata fields.
#'
#' @param map An `sc_color_map`.
#' @param path Output `.json` or `.csv` path.
#' @return `path`, invisibly.
#' @export
#' @examplesIf interactive()
#' path <- tempfile(fileext = ".csv")
#' write_sc_color_map(sc_color_map(c("B", "T")), path)
write_sc_color_map <- function(map, path) {
  .sc_validate_map(map)
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    .sc_abort("{.arg path} must be one file path.")
  }
  payload <- .sc_map_payload(map)
  if (grepl("\\.json$", path, ignore.case = TRUE)) {
    jsonlite::write_json(
      payload, path, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null",
      dataframe = "rows", keep_vec_names = TRUE, digits = 17
    )
  } else {
    metadata <- as.character(jsonlite::toJSON(
      payload, auto_unbox = TRUE, pretty = FALSE, null = "null", na = "null",
      dataframe = "rows", keep_vec_names = TRUE, digits = 17
    ))
    table <- data.frame(
      record_type = c("metadata", rep("mapping", length(map$labels))),
      label = c("", map$labels),
      color = c("", map$colors),
      metadata = c(metadata, rep("", length(map$labels))),
      stringsAsFactors = FALSE
    )
    utils::write.csv(table, path, row.names = FALSE, quote = TRUE)
  }
  invisible(path)
}

#' Read a persistent color map
#'
#' Versioned JSON and CSV files are validated before object construction.
#' Unversioned JSON files and legacy two-column CSV files written by
#' scChromatic 0.1.0 remain readable and are migrated to schema version 1.
#' Unknown future schema versions are rejected rather than guessed.
#'
#' @param path JSON or CSV path written by [write_sc_color_map()].
#' @return A validated `sc_color_map` using the current schema version.
#' @export
#' @examplesIf interactive()
#' path <- tempfile(fileext = ".csv")
#' write_sc_color_map(sc_color_map(c("B", "T")), path)
#' read_sc_color_map(path)
read_sc_color_map <- function(path) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    .sc_abort("{.arg path} must be one file path.")
  }
  if (!file.exists(path)) {
    .sc_abort("Color-map file does not exist: {.file {path}}.")
  }
  prefix <- readChar(path, nchars = 1024L, useBytes = TRUE)
  is_json <- grepl("^[[:space:]]*\\{", sub("^\\ufeff", "", prefix))
  if (is_json) {
    payload <- tryCatch(
      .sc_payload_from_json(path),
      error = function(e) .sc_abort("Invalid color-map JSON: {conditionMessage(e)}")
    )
    if (is.null(payload$schema)) {
      return(.sc_legacy_json_map(payload))
    }
    return(.sc_map_from_payload(payload))
  }

  table <- tryCatch(
    utils::read.csv(
      path, stringsAsFactors = FALSE, check.names = FALSE,
      colClasses = "character", na.strings = character()
    ),
    error = function(e) .sc_abort("Invalid color-map CSV: {conditionMessage(e)}")
  )
  if (identical(names(table), c("label", "color"))) {
    colors <- .sc_payload_mapping(table)
    return(.sc_new_map(
      colors, "external", "light", "#BDBDBD", map_type = "external",
      provenance = NULL
    ))
  }
  expected <- c("record_type", "label", "color", "metadata")
  if (!identical(names(table), expected)) {
    .sc_abort(
      "CSV color maps must contain either {.field label/color} or the versioned {.field record_type/label/color/metadata} columns."
    )
  }
  if (sum(table$record_type == "metadata") != 1L ||
      any(!table$record_type %in% c("metadata", "mapping"))) {
    .sc_abort("Versioned CSV color maps require exactly one metadata row.")
  }
  metadata_text <- table$metadata[table$record_type == "metadata"]
  if (!nzchar(metadata_text)) {
    .sc_abort("Versioned CSV color-map metadata is empty.")
  }
  payload <- tryCatch(
    .sc_payload_from_json(metadata_text),
    error = function(e) .sc_abort("Invalid JSON in CSV color-map metadata: {conditionMessage(e)}")
  )
  csv_mapping <- table[table$record_type == "mapping", c("label", "color"), drop = FALSE]
  payload_colors <- .sc_payload_mapping(payload$mapping)
  csv_colors <- .sc_payload_mapping(csv_mapping)
  if (!identical(payload_colors, csv_colors)) {
    .sc_abort("CSV mapping rows do not match the versioned metadata payload.")
  }
  .sc_map_from_payload(payload)
}

#' @export
print.sc_color_map <- function(x, ...) {
  cat(format(x), sep = "\n")
  invisible(x)
}

#' @export
format.sc_color_map <- function(x, ...) {
  .sc_validate_map(x)
  header <- sprintf(
    "<sc_color_map[%d]> type: %s; palette: %s; background: %s; schema: v%d",
    length(x$labels), x$map_type, x$palette, x$background, x$schema_version
  )
  entries <- sprintf("  %s: %s", x$labels, x$colors)
  c(header, entries)
}

#' @export
as.data.frame.sc_color_map <- function(x, row.names = NULL, optional = FALSE, ...) {
  .sc_validate_map(x)
  out <- data.frame(label = x$labels, color = x$colors, stringsAsFactors = FALSE)
  if (!is.null(x$parent)) {
    out$parent <- unname(x$parent[x$labels])
  }
  if (!is.null(x$focus)) {
    out$focus <- x$labels %in% x$focus
  }
  if (!is.null(x$locks)) {
    out$locked <- if (is.character(x$locks)) {
      x$labels %in% x$locks
    } else {
      locked <- unname(x$locks[x$labels])
      replace(locked, is.na(locked), FALSE)
    }
  }
  out
}

#' @export
`[.sc_color_map` <- function(x, i, ...) {
  .sc_validate_map(x)
  colors <- as_named_colors(x)[i]
  colors <- colors[!is.na(colors)]
  x$labels <- names(colors)
  x$colors <- unname(colors)
  if (!is.null(x$parent)) {
    x$parent <- x$parent[x$labels]
    if (!is.null(x$parent_anchors)) {
      x$parent_anchors <- x$parent_anchors[unique(unname(x$parent))]
    }
  }
  if (!is.null(x$focus)) {
    x$focus <- intersect(x$focus, x$labels)
  }
  if (!is.null(x$locks)) {
    x$locks <- if (is.character(x$locks)) {
      intersect(x$locks, x$labels)
    } else {
      x$locks[names(x$locks) %in% x$labels]
    }
  }
  if (!is.null(x$aliases)) {
    x$aliases <- x$aliases[x$aliases %in% x$labels]
  }
  .sc_validate_map(x)
  x
}
