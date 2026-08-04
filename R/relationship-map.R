.sc_validate_relationship <- function(relationship) {
  if (!is.matrix(relationship) || !is.numeric(relationship) ||
      length(dim(relationship)) != 2L || nrow(relationship) != ncol(relationship) ||
      nrow(relationship) < 2L) {
    .sc_abort(
      "{.arg relationship} must be a square numeric matrix with at least two labels."
    )
  }
  row_labels <- rownames(relationship)
  column_labels <- colnames(relationship)
  valid_labels <- function(x) {
    is.character(x) && length(x) == nrow(relationship) && !anyNA(x) &&
      !anyDuplicated(x) && all(nzchar(trimws(x)))
  }
  if (!valid_labels(row_labels) || !valid_labels(column_labels) ||
      !setequal(row_labels, column_labels)) {
    .sc_abort(
      "{.arg relationship} must have the same unique, non-empty row and column names."
    )
  }
  relationship <- relationship[row_labels, row_labels, drop = FALSE]
  off_diagonal <- row(relationship) != col(relationship)
  values <- relationship[off_diagonal]
  if (anyNA(values) || any(!is.finite(values))) {
    .sc_abort("{.arg relationship} must contain only finite, non-missing affinities.")
  }
  tolerance <- 1e-8
  if (any(values < -tolerance) || any(values > 1 + tolerance)) {
    .sc_abort("{.arg relationship} affinities must lie in the interval [0, 1].")
  }
  diag(relationship) <- 0
  if (max(abs(relationship - t(relationship))) > tolerance) {
    .sc_abort("{.arg relationship} must be symmetric.")
  }

  relationship <- (relationship + t(relationship)) / 2
  relationship[relationship < 0] <- 0
  relationship[relationship > 1] <- 1
  diag(relationship) <- 0
  labels <- row_labels[.sc_natural_order(row_labels)]
  relationship <- relationship[labels, labels, drop = FALSE]
  storage.mode(relationship) <- "double"
  relationship
}

.sc_relationship_canonical <- function(canonical, labels) {
  if (is.null(canonical)) {
    return(character())
  }
  if (inherits(canonical, "sc_color_map")) {
    .sc_validate_map(canonical)
    colors <- as_named_colors(canonical)
  } else {
    if (!is.character(canonical) || is.null(names(canonical)) ||
        anyNA(names(canonical)) || any(!nzchar(trimws(names(canonical)))) ||
        anyDuplicated(names(canonical))) {
      .sc_abort(
        "{.arg canonical} must be an sc_color_map or a fully named color vector."
      )
    }
    .sc_validate_colors(canonical, "canonical")
    colors <- canonical
  }
  absent <- setdiff(names(colors), labels)
  if (length(absent)) {
    .sc_abort(
      "Canonical label{?s} absent from {.arg relationship}: {.val {absent}}."
    )
  }
  colors <- stats::setNames(.sc_hex(unname(colors)), names(colors))
  colors[intersect(labels, names(colors))]
}

.sc_relationship_lock_names <- function(x, labels, name) {
  if (is.null(x) || !length(x)) {
    return(character())
  }
  if (is.character(x)) {
    if (anyNA(x) || any(!nzchar(trimws(x))) || anyDuplicated(x)) {
      .sc_abort("{.arg {name}} must contain unique, non-empty canonical labels.")
    }
    out <- x
  } else if (is.logical(x) && !is.null(names(x)) && !anyNA(x) &&
             !anyNA(names(x)) && !anyDuplicated(names(x)) &&
             all(nzchar(trimws(names(x))))) {
    out <- names(x)[x]
  } else {
    .sc_abort(
      "{.arg {name}} must be canonical label names or a uniquely named logical vector."
    )
  }
  absent <- setdiff(names(x), labels)
  if (is.character(x)) absent <- setdiff(x, labels)
  if (length(absent)) {
    .sc_abort("{.arg {name}} contains non-canonical label{?s}: {.val {absent}}.")
  }
  out
}

.sc_validate_stability_budget <- function(stability_budget, has_canonical) {
  if (!is.numeric(stability_budget) || length(stability_budget) != 1L ||
      !is.finite(stability_budget) || stability_budget < 0 ||
      stability_budget > .Machine$integer.max ||
      stability_budget != as.integer(stability_budget)) {
    .sc_abort("{.arg stability_budget} must be a non-negative whole number.")
  }
  if (stability_budget > 0 && !has_canonical) {
    .sc_abort("A positive {.arg stability_budget} requires {.arg canonical} colors.")
  }
  as.integer(stability_budget)
}

.sc_validate_relationship_seed <- function(seed) {
  if (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed) || seed < 0 ||
      seed > .Machine$integer.max || seed != as.integer(seed)) {
    .sc_abort("{.arg seed} must be a non-negative whole number.")
  }
  as.integer(seed)
}

.sc_relationship_orders <- function(n_labels, n_candidates, seed) {
  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (had_seed) {
    old_seed <- get(".Random.seed", envir = globalenv(), inherits = FALSE)
  }
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = globalenv())
    } else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    }
  }, add = TRUE)
  set.seed(
    seed, kind = "Mersenne-Twister", normal.kind = "Inversion",
    sample.kind = "Rejection"
  )
  list(
    labels = sample.int(n_labels),
    candidates = sample.int(n_candidates)
  )
}

.sc_relationship_target <- function(relationship) {
  target <- 8 + 32 * (1 - relationship)
  diag(target) <- 0
  target
}

.sc_relationship_distance_tables <- function(colors, modes) {
  normal <- .sc_pairwise_distance(colors)
  worst <- normal
  for (mode in setdiff(modes, "none")) {
    viewed <- .sc_cvd(colors, mode)
    worst <- pmin(worst, .sc_pairwise_distance(viewed))
  }
  diag(normal) <- 0
  diag(worst) <- 0
  list(normal = normal, worst = worst)
}

.sc_relationship_distances <- function(colors, modes) {
  .sc_relationship_distance_tables(colors, modes)$worst
}

.sc_relationship_loss <- function(candidate, others, target, distance) {
  normal <- pmin(distance$normal[candidate, others, drop = FALSE], 40)
  worst <- pmin(distance$worst[candidate, others, drop = FALSE], 40)
  wanted <- matrix(
    target, nrow = length(candidate), ncol = length(others), byrow = TRUE
  )
  normal_fit <- ((normal - wanted) / 40)^2
  cvd_shortfall <- (pmax(wanted - worst, 0) / 40)^2
  rowMeans(normal_fit + cvd_shortfall)
}

.sc_relationship_best <- function(i, assignment, candidate_order, target,
                                  distance, contrast) {
  others <- which(!is.na(assignment) & seq_along(assignment) != i)
  current <- assignment[[i]]
  used <- unique(assignment[others])
  allowed <- candidate_order[!candidate_order %in% used]
  if (!is.na(current)) {
    allowed <- candidate_order[
      !candidate_order %in% used | candidate_order == current
    ]
  }
  if (!length(allowed)) {
    .sc_abort("The relationship-map candidate grid was exhausted.")
  }
  if (!length(others)) {
    best <- allowed[[which.max(contrast[allowed])]]
    return(list(candidate = best, loss = 0, current_loss = Inf))
  }
  losses <- .sc_relationship_loss(
    allowed, assignment[others], target[i, others], distance
  )
  best_at <- which.min(losses)
  current_loss <- if (is.na(current)) {
    Inf
  } else {
    .sc_relationship_loss(
      current, assignment[others], target[i, others], distance
    )[[1L]]
  }
  list(
    candidate = allowed[[best_at]], loss = losses[[best_at]],
    current_loss = current_loss
  )
}

.sc_relationship_metrics <- function(assignment, target, distance) {
  normal <- pmin(distance$normal[assignment, assignment, drop = FALSE], 40)
  worst_raw <- distance$worst[assignment, assignment, drop = FALSE]
  worst <- pmin(worst_raw, 40)
  upper <- upper.tri(normal)
  normal_fit <- ((normal[upper] - target[upper]) / 40)^2
  cvd_shortfall <- (pmax(target[upper] - worst[upper], 0) / 40)^2
  list(
    objective = mean(normal_fit + cvd_shortfall),
    normal_fit = mean(normal_fit),
    cvd_shortfall = mean(cvd_shortfall),
    minimum_distance = min(worst_raw[upper])
  )
}

.sc_relationship_json_number <- function(x) {
  whole <- length(x) && is.numeric(x) && all(is.finite(x)) &&
    all(x == trunc(x)) && all(x >= -.Machine$integer.max) &&
    all(x <= .Machine$integer.max)
  if (whole) as.integer(x) else x
}

.sc_relationship_records <- function(relationship) {
  index <- which(upper.tri(relationship), arr.ind = TRUE)
  data.frame(
    label1 = rownames(relationship)[index[, 1L]],
    label2 = colnames(relationship)[index[, 2L]],
    affinity = .sc_relationship_json_number(as.numeric(relationship[index])),
    stringsAsFactors = FALSE
  )
}

#' Optimize a persistent color map from label relationships
#'
#' Treats `relationship` as a symmetric affinity matrix: `1` asks related
#' labels to use perceptually closer (but still distinct) colors, while `0`
#' asks unrelated labels to be farther apart. The diagonal is ignored.
#' Off-diagonal entries must contain finite values in `[0, 1]`; row and column
#' labels must be identical.
#'
#' The method fits normal-vision CIE2000 distance to the affinity-derived target
#' `8 + 32 * (1 - affinity)`. A separate penalty applies when the worst distance
#' across normal vision and requested CVD simulations falls below that target.
#' Distances above 40 are treated as equivalent. This is a deterministic,
#' seeded heuristic and a diagnostic accessibility aid, not a guarantee of
#' universal CVD safety.
#'
#' Canonical colors form the baseline. Hard-locked colors never change;
#' `stability_budget` is the maximum number of other canonical assignments
#' that may change when doing so strictly improves the objective. New labels do
#' not consume the budget. The normalized effective relationship input,
#' baseline, method settings, outcome, seed, and provenance are stored in the
#' returned map. Construction provenance remains immutable when a map is
#' subset; rerun this function to calculate metrics for a different label set.
#' Matrices returned by [sc_relationship_from_knn()] also carry their
#' coordinate-construction settings and pairwise sample support into the map.
#'
#' @param relationship Symmetric numeric affinity matrix whose off-diagonal
#'   entries lie in `[0, 1]`, with the same unique, non-empty row and column
#'   names. Diagonal values are ignored.
#' @param canonical Optional `sc_color_map` or fully named color vector. Its
#'   labels must be a subset of the matrix labels.
#' @param locked Additional canonical labels that may never change, supplied as
#'   names or a named logical vector. These are combined with locks already in
#'   a canonical `sc_color_map`.
#' @param stability_budget Maximum number of non-locked canonical colors that
#'   may change. The default preserves every canonical assignment.
#' @param seed Non-negative integer controlling label and candidate search order.
#' @param cvd Vision simulations used with normal vision. Values may come from
#'   `"none"`, `"deutan"`, `"protan"`, and `"tritan"`.
#' @param background Background used for candidate generation and initialization.
#' @param na.value Color used for missing labels.
#' @return A derived `sc_color_map` with locks, stability accounting, optimizer
#'   context, effective relationship input, canonical baseline, and provenance.
#' @export
#' @examples
#' affinity <- matrix(
#'   c(1, .9, .1, .9, 1, .2, .1, .2, 1), nrow = 3,
#'   dimnames = list(c("CD4 T", "CD8 T", "B"), c("CD4 T", "CD8 T", "B"))
#' )
#' canonical <- sc_color_map(c("CD4 T", "B"))
#' map <- sc_relationship_map(affinity, canonical, locked = "B", seed = 42)
#' as_named_colors(map)
sc_relationship_map <- function(
    relationship, canonical = NULL, locked = character(),
    stability_budget = 0L, seed = 1L,
    cvd = c("deutan", "protan", "tritan"),
    background = c("light", "dark"), na.value = "#BDBDBD") {
  relationship_derivation <- attr(relationship, "sc_context", exact = TRUE)
  if (!is.null(relationship_derivation)) {
    if (!is.list(relationship_derivation)) {
      .sc_abort(
        "The {.field sc_context} relationship provenance must be a JSON-native object."
      )
    }
    .sc_validate_json_native(
      relationship_derivation, "relationship$sc_context"
    )
    method <- relationship_derivation$method
    input_fingerprint <- relationship_derivation$input_md5
    fingerprint <- relationship_derivation$matrix_md5
    context_fingerprint <- relationship_derivation$context_md5
    if (!is.character(method) || length(method) != 1L || !nzchar(method) ||
        !is.character(input_fingerprint) || length(input_fingerprint) != 1L ||
        !grepl("^[0-9a-f]{32}$", input_fingerprint) ||
        !is.character(fingerprint) || length(fingerprint) != 1L ||
        !grepl("^[0-9a-f]{32}$", fingerprint) ||
        !is.character(context_fingerprint) ||
        length(context_fingerprint) != 1L ||
        !grepl("^[0-9a-f]{32}$", context_fingerprint)) {
      .sc_abort(
        paste(
          "The {.field sc_context} relationship provenance is missing its",
          "method or required fingerprints."
        )
      )
    }
    if (!identical(method, "coordinate-knn-v1")) {
      .sc_abort(
        "Unsupported relationship context method {.val {method}}."
      )
    }
    context_without_fingerprint <- relationship_derivation
    context_without_fingerprint$context_md5 <- NULL
    if (!identical(
      .sc_context_md5(context_without_fingerprint), context_fingerprint
    )) {
      .sc_abort(paste(
        "The relationship context metadata was modified after its provenance",
        "fingerprint was created; derive it again before optimization."
      ))
    }
  }
  relationship <- .sc_validate_relationship(relationship)
  if (!is.null(relationship_derivation) &&
      !identical(.sc_relationship_matrix_md5(relationship), fingerprint)) {
    .sc_abort(paste(
      "The effective relationship matrix was modified after its context",
      "provenance was created; derive it again before optimization."
    ))
  }
  labels <- rownames(relationship)
  canonical_colors <- .sc_relationship_canonical(canonical, labels)
  stability_budget <- .sc_validate_stability_budget(
    stability_budget, length(canonical_colors) > 0L
  )
  seed <- .sc_validate_relationship_seed(seed)

  allowed_modes <- c("none", "deutan", "protan", "tritan")
  if (!is.character(cvd) || anyNA(cvd) || any(!cvd %in% allowed_modes)) {
    .sc_abort(
      "{.arg cvd} must contain values from {paste(allowed_modes, collapse = ', ')}."
    )
  }
  modes <- unique(c("none", cvd))
  if (inherits(canonical, "sc_color_map") && missing(background)) {
    background <- canonical$background
  } else {
    background <- match.arg(background)
  }
  if (inherits(canonical, "sc_color_map") && missing(na.value)) {
    na.value <- canonical$na.value
  }
  .sc_validate_colors(na.value, "na.value")
  if (length(na.value) != 1L) {
    .sc_abort("{.arg na.value} must be one color.")
  }

  inherited_locks <- if (inherits(canonical, "sc_color_map")) {
    .sc_relationship_lock_names(canonical$locks, names(canonical_colors), "canonical$locks")
  } else {
    character()
  }
  explicit_locks <- .sc_relationship_lock_names(
    locked, names(canonical_colors), "locked"
  )
  locked_labels <- unique(c(inherited_locks, explicit_locks))
  if (anyDuplicated(toupper(unname(canonical_colors[locked_labels])))) {
    .sc_warn("Duplicate hard-locked canonical colors cannot be resolved by optimization.")
  }

  candidates <- unique(c(
    unname(canonical_colors), .sc_candidate_colors(background)
  ))
  candidates <- unique(.sc_hex(candidates))
  if (length(candidates) < length(labels)) {
    .sc_abort(
      "The relationship-map candidate grid supports fewer colors than the requested labels."
    )
  }
  orders <- .sc_relationship_orders(length(labels), length(candidates), seed)
  target <- .sc_relationship_target(relationship)
  distance <- .sc_relationship_distance_tables(candidates, modes)
  bg <- if (background == "light") "#FFFFFF" else "#1A1A1A"
  contrast <- as.numeric(colorspace::contrast_ratio(candidates, bg))

  assignment <- rep(NA_integer_, length(labels))
  names(assignment) <- labels
  canonical_index <- match(names(canonical_colors), labels)
  assignment[canonical_index] <- match(unname(canonical_colors), candidates)
  new_index <- which(is.na(assignment))
  search_order <- orders$labels[orders$labels %in% new_index]
  for (i in search_order) {
    assignment[[i]] <- .sc_relationship_best(
      i, assignment, orders$candidates, target, distance, contrast
    )$candidate
  }

  refine_new <- function(assignment) {
    for (i in search_order) {
      best <- .sc_relationship_best(
        i, assignment, orders$candidates, target, distance, contrast
      )
      if (best$loss + 1e-12 < best$current_loss) {
        assignment[[i]] <- best$candidate
      }
    }
    assignment
  }
  assignment <- refine_new(assignment)

  eligible <- setdiff(canonical_index, match(locked_labels, labels))
  eligible <- orders$labels[orders$labels %in% eligible]
  changed_index <- integer()
  for (step in seq_len(min(stability_budget, length(eligible)))) {
    move <- NULL
    for (i in setdiff(eligible, changed_index)) {
      best <- .sc_relationship_best(
        i, assignment, orders$candidates, target, distance, contrast
      )
      improvement <- best$current_loss - best$loss
      if (is.null(move) || improvement > move$improvement + 1e-12) {
        move <- list(i = i, candidate = best$candidate, improvement = improvement)
      }
    }
    if (is.null(move) || move$improvement <= 1e-12) break
    assignment[[move$i]] <- move$candidate
    changed_index <- c(changed_index, move$i)
  }
  assignment <- refine_new(assignment)

  colors <- stats::setNames(candidates[assignment], labels)
  changed <- names(canonical_colors)[
    unname(colors[names(canonical_colors)]) != unname(canonical_colors)
  ]
  if (length(changed) > stability_budget ||
      any(unname(colors[locked_labels]) != unname(canonical_colors[locked_labels]))) {
    .sc_abort("Internal relationship-map stability invariant failed.")
  }
  metrics <- .sc_relationship_metrics(assignment, target, distance)
  metrics <- lapply(metrics, .sc_relationship_json_number)

  canonical_provenance <- if (inherits(canonical, "sc_color_map") &&
                              !is.null(canonical$provenance)) {
    .sc_payload_records(canonical$provenance, "provenance")
  } else {
    list()
  }
  method_provenance <- list(list(
    source = "scChromatic",
    source_palette = "relationship-v1",
    source_url = "https://github.com/xie186/scChromatic",
    source_version = .sc_package_version(),
    citation = "scChromatic relationship-aware color optimization",
    license = "GPL (>= 3)",
    derived = TRUE,
    source_cvd_claim = paste(
      "Optimized under specified CVD simulations;",
      "no universal CVD-safety claim."
    )
  ))
  derivation_provenance <- if (is.null(relationship_derivation)) {
    list()
  } else {
    list(list(
      source = "scChromatic",
      source_palette = relationship_derivation$method,
      source_url = "https://github.com/xie186/scChromatic",
      source_version = .sc_package_version(),
      citation = "scChromatic context-derived relationship construction",
      license = "GPL (>= 3)",
      derived = TRUE,
      source_cvd_claim = paste(
        "No color-vision claim; this record derives label affinities",
        "from coordinate neighborhoods."
      )
    ))
  }
  canonical_history <- if (inherits(canonical, "sc_color_map") &&
                           !is.null(canonical$history)) {
    .sc_payload_records(canonical$history, "history")
  } else {
    list()
  }
  history <- c(canonical_history, list(list(
    action = "relationship_optimized",
    method = "relationship-v1",
    scope = "construction",
    seed = seed,
    stability_budget = stability_budget,
    changed_count = as.integer(length(changed)),
    final_objective = metrics$objective
  )))
  metadata <- list(relationship_input = list(
    semantics = "symmetric affinity in [0,1]; diagonal ignored",
    representation = "normalized_effective",
    normalization = paste(
      "natural label order; symmetric mean within tolerance;",
      "clamp to [0,1]; diagonal discarded"
    ),
    symmetry_tolerance = 1e-8,
    labels = labels,
    pairs = .sc_relationship_records(relationship)
  ))
  if (!is.null(relationship_derivation)) {
    metadata$relationship_input$derivation <- relationship_derivation
  }
  if (length(canonical_colors)) {
    baseline <- list(
      source_type = if (inherits(canonical, "sc_color_map")) {
        "sc_color_map"
      } else {
        "named_colors"
      },
      assignments = data.frame(
        label = names(canonical_colors),
        before_color = unname(canonical_colors),
        after_color = unname(colors[names(canonical_colors)]),
        locked = names(canonical_colors) %in% locked_labels,
        changed = names(canonical_colors) %in% changed,
        stringsAsFactors = FALSE
      )
    )
    if (inherits(canonical, "sc_color_map")) {
      baseline$palette <- canonical$palette
      baseline$map_type <- canonical$map_type
      baseline$schema_version <- canonical$schema_version
      baseline$package_version <- canonical$package_version
    }
    metadata$canonical_baseline <- baseline
  }

  # ponytail: this exact candidate search is intentionally local; approximate
  # search belongs in a later method version only if large ontologies require it.
  .sc_new_map(
    colors, "derived:relationship-v1", background, na.value,
    provenance = c(
      canonical_provenance, derivation_provenance, method_provenance
    ),
    map_type = "derived",
    locks = stats::setNames(labels %in% locked_labels, labels),
    seed = as.numeric(seed),
    history = history,
    context = list(
      method = "relationship-v1",
      scope = "construction",
      relationship_source = if (is.null(relationship_derivation)) {
        "matrix"
      } else {
        relationship_derivation$method
      },
      relationship_semantics = "affinity",
      optimizer = "seeded-greedy-coordinate",
      heuristic = TRUE,
      distance = "CIEDE2000",
      objective = "normal_fit_plus_worst_cvd_shortfall",
      cvd = modes,
      target_formula = "8 + 32 * (1 - affinity)",
      target_min_cie2000 = 8L,
      target_max_cie2000 = 40L,
      distance_cap_cie2000 = 40L,
      cvd_shortfall_weight = 1L,
      stability_budget = stability_budget,
      stability_budget_used = as.integer(length(changed)),
      canonical_count = as.integer(length(canonical_colors)),
      locked_count = as.integer(length(locked_labels)),
      candidate_count = as.integer(length(candidates)),
      final_objective = metrics$objective,
      normal_fit_stress = metrics$normal_fit,
      worst_cvd_shortfall = metrics$cvd_shortfall,
      minimum_worst_case_cie2000 = metrics$minimum_distance,
      rng = "Mersenne-Twister/Inversion/Rejection",
      r_version = as.character(getRversion()),
      colorspace_version = as.character(utils::packageVersion("colorspace")),
      farver_version = as.character(utils::packageVersion("farver")),
      candidate_grid = .sc_candidate_grid_version
    ),
    metadata = metadata
  )
}
