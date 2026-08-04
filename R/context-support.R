.sc_context_coordinates <- function(coordinates, labels, sample) {
  if (is.data.frame(coordinates)) {
    numeric_columns <- vapply(coordinates, is.numeric, logical(1))
    if (!all(numeric_columns)) {
      .sc_abort("Every column of {.arg coordinates} must be numeric.")
    }
    coordinates <- as.matrix(coordinates)
  }
  if (!is.matrix(coordinates) || !is.numeric(coordinates) ||
      nrow(coordinates) < 2L || ncol(coordinates) < 1L ||
      anyNA(coordinates) || any(!is.finite(coordinates))) {
    .sc_abort(
      "{.arg coordinates} must be a finite numeric matrix with at least two rows and one column."
    )
  }
  storage.mode(coordinates) <- "double"
  if ((!is.character(labels) && !is.factor(labels)) ||
      length(labels) != nrow(coordinates)) {
    .sc_abort("{.arg labels} must contain one character or factor value per row.")
  }
  labels <- as.character(labels)
  if (anyNA(labels) || any(!nzchar(trimws(labels)))) {
    .sc_abort("{.arg labels} must not contain missing or empty values.")
  }
  if (length(unique(labels)) < 2L) {
    .sc_abort("{.arg labels} must contain at least two observed labels.")
  }

  if (is.null(sample)) {
    sample <- rep("all", nrow(coordinates))
  }
  if ((!is.character(sample) && !is.factor(sample)) ||
      length(sample) != nrow(coordinates)) {
    .sc_abort("{.arg sample} must contain one character or factor value per row.")
  }
  sample <- as.character(sample)
  if (anyNA(sample) || any(!nzchar(trimws(sample)))) {
    .sc_abort("{.arg sample} must not contain missing or empty values.")
  }
  list(coordinates = coordinates, labels = labels, sample = sample)
}

.sc_exact_knn_affinity <- function(coordinates, labels, label_levels, k) {
  n <- nrow(coordinates)
  votes <- matrix(
    0, nrow = length(label_levels), ncol = length(label_levels),
    dimnames = list(label_levels, label_levels)
  )
  source <- match(labels, label_levels)
  if (!k) {
    affinity <- votes
    affinity[,] <- NA_real_
    present <- label_levels %in% labels
    diag(affinity)[present] <- 1
    return(affinity)
  }
  block_size <- max(1L, min(n, floor(16 * 1024^2 / (8 * n))))

  # ponytail: exact search is O(n^2); add an optional ANN backend only when
  # profiling shows that context matrices, rather than supplied matrices, dominate.
  for (start in seq.int(1L, n, by = block_size)) {
    index <- start:min(n, start + block_size - 1L)
    distance <- matrix(0, nrow = length(index), ncol = n)
    for (dimension in seq_len(ncol(coordinates))) {
      delta <- outer(
        coordinates[index, dimension], coordinates[, dimension], "-"
      )
      squared_delta <- delta^2
      if (any(!is.finite(squared_delta))) {
        .sc_abort(
          paste(
            "Coordinate differences overflowed while computing distances;",
            "rescale {.arg coordinates} to a smaller numeric range."
          )
        )
      }
      distance <- distance + squared_delta
      if (any(!is.finite(distance))) {
        .sc_abort(
          paste(
            "Coordinate distances overflowed during accumulation;",
            "rescale {.arg coordinates} to a smaller numeric range."
          )
        )
      }
    }
    distance[cbind(seq_along(index), index)] <- Inf
    for (i in seq_along(index)) {
      boundary <- sort.int(distance[i, ], partial = k)[[k]]
      tolerance <- max(64, 8 * ncol(coordinates)) * .Machine$double.eps *
        max(abs(boundary), .Machine$double.xmin)
      neighbor <- which(distance[i, ] <= boundary + tolerance)
      target_count <- tabulate(source[neighbor], nbins = length(label_levels))
      votes[source[index[[i]]], ] <- votes[source[index[[i]]], ] +
        target_count / length(neighbor)
    }
  }
  label_count <- tabulate(source, nbins = length(label_levels))
  conditional <- votes / label_count
  affinity <- (conditional + t(conditional)) / 2
  present <- label_count > 0L
  affinity[!present, ] <- NA_real_
  affinity[, !present] <- NA_real_
  diag(affinity)[present] <- 1
  affinity
}

.sc_context_md5 <- function(x) {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(x, path, version = 3, compress = FALSE)
  unname(tools::md5sum(path))
}

.sc_relationship_matrix_md5 <- function(x) {
  .sc_context_md5(.sc_validate_relationship(x))
}

.sc_context_summary <- function(x) {
  middle <- stats::median(x)
  if (middle == trunc(middle)) middle <- as.integer(middle)
  list(
    min = as.integer(min(x)), median = middle, max = as.integer(max(x))
  )
}

.sc_context_pair_support <- function(support) {
  index <- which(upper.tri(support), arr.ind = TRUE)
  data.frame(
    label1 = rownames(support)[index[, 1L]],
    label2 = colnames(support)[index[, 2L]],
    sample_count = as.integer(support[index]),
    stringsAsFactors = FALSE
  )
}

#' Derive label relationships from coordinate neighborhoods
#'
#' Builds an exact Euclidean k-nearest-neighbor graph within each sample, then
#' converts directed cell-level edges into symmetric label affinities. For a
#' label pair `i, j`, affinity is the mean of the directed neighbor
#' probabilities `p(j | i)` and `p(i | j)`. Values therefore lie in `[0, 1]`.
#'
#' Sample matrices receive equal weight, irrespective of cell count. A pair is
#' aggregated only across samples containing both labels. By default, pairs
#' never observed together are reported as an error; `unobserved = "zero"`
#' explicitly treats them as unrelated. The returned numeric matrix can be
#' passed directly to [sc_relationship_map()]. Its construction settings and
#' pairwise sample support are carried into that map's provenance.
#'
#' Coordinate distance should be scientifically meaningful. PCA, a model latent
#' space, or spatial coordinates are usually preferable to UMAP when quantitative
#' distances matter. The resulting affinities depend on label prevalence, local
#' density, coordinate scaling, and `k`; they are context summaries rather than
#' direct evidence of biological similarity. Raw coordinates, row names, and
#' sample identifiers are not stored in the returned provenance; only
#' fingerprints and aggregate summaries are retained.
#'
#' @param coordinates Numeric matrix or all-numeric data frame with observations
#'   in rows and coordinate dimensions in columns.
#' @param labels Character or factor label for every row.
#' @param sample Optional character or factor sample identifier for every row.
#'   Neighbors are found within samples. `NULL` treats all rows as one sample.
#' @param k Requested number of neighbors. It is reduced to `n - 1` within
#'   samples containing fewer than `k + 1` rows.
#' @param aggregate Equal-sample aggregation, either `"mean"` or `"median"`.
#' @param unobserved How to handle label pairs never observed together in any
#'   sample: error or explicitly assign zero affinity.
#' @return A symmetric numeric affinity matrix with an `sc_context` attribute
#'   containing construction provenance and pairwise sample support.
#' @export
#' @examples
#' coordinates <- matrix(c(0, .1, .2, .3, 2, 2.1, 4, 4.1), ncol = 1)
#' labels <- rep(c("A", "B"), 4)
#' samples <- rep(c("s1", "s2"), each = 4)
#' relationship <- sc_relationship_from_knn(
#'   coordinates, labels, samples, k = 1
#' )
#' sc_relationship_map(relationship, seed = 1)
sc_relationship_from_knn <- function(
    coordinates, labels, sample = NULL, k = 15L,
    aggregate = c("mean", "median"), unobserved = c("error", "zero")) {
  input <- .sc_context_coordinates(coordinates, labels, sample)
  coordinates <- input$coordinates
  labels <- input$labels
  sample <- input$sample
  k <- .sc_validate_n(k, allow_null = FALSE)
  aggregate <- match.arg(aggregate)
  unobserved <- match.arg(unobserved)
  input_md5 <- .sc_context_md5(list(
    coordinates = unname(coordinates),
    labels = unname(labels),
    sample = unname(sample)
  ))

  label_levels <- unique(labels)[.sc_natural_order(unique(labels))]
  sample_levels <- unique(sample)[.sc_natural_order(unique(sample))]
  per_sample <- array(
    NA_real_,
    dim = c(length(label_levels), length(label_levels), length(sample_levels)),
    dimnames = list(label_levels, label_levels, sample_levels)
  )
  sample_k <- data.frame(
    cell_count = integer(length(sample_levels)),
    k = integer(length(sample_levels)), stringsAsFactors = FALSE
  )

  for (s in seq_along(sample_levels)) {
    index <- which(sample == sample_levels[[s]])
    sample_k$cell_count[[s]] <- length(index)
    sample_k$k[[s]] <- min(k, length(index) - 1L)
    per_sample[, , s] <- .sc_exact_knn_affinity(
      coordinates[index, , drop = FALSE], labels[index], label_levels,
      sample_k$k[[s]]
    )
  }
  if (any(sample_k$k < k)) {
    .sc_warn(
      "Reduced {.arg k} within samples containing fewer than {k + 1L} rows."
    )
  }

  combine <- if (aggregate == "mean") base::mean else stats::median
  relationship <- apply(per_sample, c(1L, 2L), function(x) {
    if (all(is.na(x))) 0 else combine(x, na.rm = TRUE)
  })
  support <- apply(!is.na(per_sample), c(1L, 2L), sum)
  unobserved_index <- which(upper.tri(support) & support == 0L, arr.ind = TRUE)
  if (nrow(unobserved_index) && unobserved == "error") {
    pair <- paste(
      rownames(support)[unobserved_index[, 1L]],
      colnames(support)[unobserved_index[, 2L]], sep = " / "
    )
    .sc_abort(c(
      "No sample jointly observes relationship pair{?s}: {.val {pair}}.",
      "i" = "Use {.code unobserved = \"zero\"} only if no joint evidence should mean unrelated."
    ))
  }
  relationship <- (relationship + t(relationship)) / 2
  diag(relationship) <- 1
  dimnames(relationship) <- list(label_levels, label_levels)
  dimnames(support) <- list(label_levels, label_levels)

  coordinate_names <- colnames(coordinates)
  if (is.null(coordinate_names)) {
    coordinate_names <- paste0("dimension", seq_len(ncol(coordinates)))
  }
  filled_pairs <- if (nrow(unobserved_index)) {
    data.frame(
      label1 = rownames(support)[unobserved_index[, 1L]],
      label2 = colnames(support)[unobserved_index[, 2L]],
      stringsAsFactors = FALSE
    )
  } else {
    NULL
  }
  context <- list(
    method = "coordinate-knn-v1",
    scope = "construction",
    distance = "euclidean",
    engine = "base-blockwise-exact",
    affinity = "mean_bidirectional_neighbor_probability",
    affinity_formula = "(p(j|i) + p(i|j)) / 2",
    aggregation = aggregate,
    sample_weighting = "equal",
    tie_rule = "include_all_neighbors_at_kth_distance",
    tie_tolerance = paste(
      "max(64, 8 * dimensions) * double epsilon *",
      "max(kth squared distance, double xmin)"
    ),
    tie_weighting = "equal_cell_weight_split_across_tied_neighbors",
    missing_label_rule = "pairwise_complete_samples",
    unobserved = unobserved,
    k_requested = k,
    cell_count = as.integer(nrow(coordinates)),
    sample_count = as.integer(length(sample_levels)),
    coordinate_dimensions = as.integer(ncol(coordinates)),
    coordinate_names = unname(coordinate_names),
    sample_cell_count_summary = .sc_context_summary(sample_k$cell_count),
    effective_k_summary = .sc_context_summary(sample_k$k),
    sample_identifiers = "not_stored",
    pair_support = .sc_context_pair_support(support)
  )
  if (!is.null(filled_pairs)) context$zero_filled_pairs <- filled_pairs
  context$r_version <- as.character(getRversion())
  context$input_md5 <- input_md5
  context$matrix_md5 <- .sc_relationship_matrix_md5(relationship)
  context$context_md5 <- .sc_context_md5(context)
  attr(relationship, "sc_context") <- context
  relationship
}

.sc_encoding_groups <- function(conflict, labels) {
  degree <- rowSums(conflict)
  group <- integer(length(labels))
  while (any(group == 0L)) {
    candidates <- which(group == 0L)
    saturation <- vapply(candidates, function(i) {
      length(unique(group[conflict[i, ] & group > 0L]))
    }, integer(1))
    ranked <- order(
      -saturation, -degree[candidates], candidates, method = "radix"
    )
    i <- candidates[ranked[[1L]]]
    unavailable <- unique(group[conflict[i, ] & group > 0L])
    group[[i]] <- setdiff(seq_len(length(labels)), unavailable)[[1L]]
  }
  group
}

#' Allocate redundant shapes or patterns for confusable colors
#'
#' Finds label pairs whose worst CIE2000 distance across normal and requested
#' CVD simulations is below `min_cie2000`, then assigns auxiliary encoding
#' groups with a deterministic DSATUR heuristic so every such pair differs.
#' Colors are returned unchanged.
#' Shapes are ggplot2-compatible integers. Default pattern names are compatible
#' with ggpattern; `texture_group` can also be used as a grouping variable for
#' other texture systems such as scatterHatch.
#'
#' Allocation is deterministic for one full label set, but graph priorities can
#' change when labels are added or removed. Allocate once for the full label
#' universe and reuse or subset the returned table across figures. The
#' `sc_encoding` and `conflicts` attributes record the method, settings, pools,
#' and conflicting pairs; save the object as RDS if those attributes must persist,
#' because ordinary data-frame CSV export does not retain them.
#'
#' @param x An `sc_color_map` or fully named color vector.
#' @param channel Allocate `"shape"`, `"pattern"`, or joint shape-pattern
#'   combinations with `"both"`. A conflicting pair differs in at least one
#'   enabled aesthetic.
#' @param min_cie2000 Pairs below this worst-vision CIE2000 distance must receive
#'   different auxiliary encodings.
#' @param cvd Vision simulations used with normal vision.
#' @param shapes Unique integer plotting shapes.
#' @param patterns Unique non-empty pattern names.
#' @return A data frame containing label, unchanged color, encoding group,
#'   texture group, shape, pattern, and number of confusable neighbors, with
#'   `sc_encoding` settings and `conflicts` records as attributes.
#' @export
#' @examples
#' colors <- c(A = "#0072B2", B = "#0072B2", C = "#D55E00")
#' sc_redundant_encoding(colors, channel = "shape")
sc_redundant_encoding <- function(
    x, channel = c("shape", "pattern", "both"), min_cie2000 = 8,
    cvd = c("deutan", "protan", "tritan"),
    shapes = c(16L, 17L, 15L, 18L, 8L, 3L),
    patterns = c("none", "stripe", "crosshatch", "circle", "wave", "weave")) {
  resolved <- .sc_audit_colors(x)
  colors <- resolved$colors
  if (is.null(names(colors)) || anyNA(names(colors)) ||
      any(!nzchar(trimws(names(colors)))) || anyDuplicated(names(colors))) {
    .sc_abort("{.arg x} must provide one unique, non-empty label per color.")
  }
  .sc_validate_colors(colors, "x")
  labels <- names(colors)[.sc_natural_order(names(colors))]
  colors <- stats::setNames(.sc_hex(unname(colors[labels])), labels)
  channel <- match.arg(channel)
  if (!is.numeric(min_cie2000) || length(min_cie2000) != 1L ||
      !is.finite(min_cie2000) || min_cie2000 < 0) {
    .sc_abort("{.arg min_cie2000} must be one non-negative finite number.")
  }
  allowed_modes <- c("none", "deutan", "protan", "tritan")
  if (!is.character(cvd) || anyNA(cvd) || any(!cvd %in% allowed_modes)) {
    .sc_abort(
      "{.arg cvd} must contain values from {paste(allowed_modes, collapse = ', ')}."
    )
  }
  modes <- unique(c("none", cvd))
  if (!is.numeric(shapes) || !length(shapes) || anyNA(shapes) ||
      any(!is.finite(shapes)) || any(shapes < 0 | shapes > 25) ||
      any(shapes != floor(shapes)) || anyDuplicated(shapes)) {
    .sc_abort(
      "{.arg shapes} must contain unique integer plotting shapes from 0 to 25."
    )
  }
  shapes <- as.integer(shapes)
  if (!is.character(patterns) || !length(patterns) || anyNA(patterns) ||
      any(!nzchar(trimws(patterns))) || anyDuplicated(patterns)) {
    .sc_abort("{.arg patterns} must contain unique, non-empty names.")
  }

  distance <- .sc_relationship_distances(unname(colors), modes)
  conflict <- distance < min_cie2000
  diag(conflict) <- FALSE
  group <- .sc_encoding_groups(conflict, labels)
  choices <- switch(
    channel,
    shape = data.frame(shape = shapes, pattern = "none"),
    pattern = data.frame(shape = shapes[[1L]], pattern = patterns),
    both = expand.grid(
      shape = shapes, pattern = patterns,
      KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
    )
  )
  if (max(group) > nrow(choices)) {
    .sc_abort(
      "Confusable colors require {max(group)} auxiliary encodings, but {.arg channel} provides {nrow(choices)}."
    )
  }
  conflict_index <- which(upper.tri(conflict) & conflict, arr.ind = TRUE)
  conflicts <- data.frame(
    label1 = labels[conflict_index[, 1L]],
    label2 = labels[conflict_index[, 2L]],
    color1 = unname(colors[conflict_index[, 1L]]),
    color2 = unname(colors[conflict_index[, 2L]]),
    min_cie2000 = as.numeric(distance[conflict_index]),
    stringsAsFactors = FALSE
  )
  encoding <- data.frame(
    label = labels,
    color = unname(colors),
    encoding_group = group,
    texture_group = group,
    shape = choices$shape[group],
    pattern = choices$pattern[group],
    conflict_count = as.integer(rowSums(conflict)),
    stringsAsFactors = FALSE
  )
  attr(encoding, "sc_encoding") <- list(
    method = "cvd-conflict-dsatur-v1",
    scope = "allocation",
    distance = "CIEDE2000",
    edge_rule = "minimum distance across requested views < min_cie2000",
    graph_coloring = "deterministic DSATUR",
    tie_break = "saturation, degree, natural label",
    heuristic = TRUE,
    channel = channel,
    min_cie2000 = min_cie2000,
    cvd = modes,
    shapes = shapes,
    patterns = patterns,
    conflict_count = as.integer(nrow(conflicts)),
    encoding_count = as.integer(max(group)),
    input_md5 = .sc_context_md5(list(labels = labels, colors = colors)),
    package_version = .sc_package_version(),
    colorspace_version = as.character(utils::packageVersion("colorspace")),
    farver_version = as.character(utils::packageVersion("farver"))
  )
  attr(encoding, "conflicts") <- conflicts
  encoding
}
