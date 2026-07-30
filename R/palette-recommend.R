.sc_use_type <- function(use) {
  switch(
    use,
    cell_identity = "qualitative",
    sample = "qualitative",
    condition = "qualitative",
    lineage = "qualitative",
    heatmap_annotation = "qualitative",
    highlight = "qualitative",
    expression = "sequential",
    pseudotime = "sequential",
    qc = "sequential",
    signed_score = "diverging"
  )
}

#' Recommend palettes from transparent registry rules
#'
#' Ranking uses palette type, intended-use metadata, capacity, status,
#' background guidance, and measured CIE2000 separation. No learned model is
#' involved.
#'
#' @param n Number of categories or gradient anchors needed.
#' @param use Single-cell visualization purpose.
#' @param geometry Point, fill, or line geometry.
#' @param background Light or dark background.
#' @param cvd Include normal/CVD minimum separation in ranking.
#' @param top Maximum rows to return.
#' @return A data frame of ranked palettes and reasons.
#' @export
#' @examples
#' sc_palette_recommend(8, use = "cell_identity")
sc_palette_recommend <- function(
    n,
    use = c(
      "cell_identity", "sample", "condition", "lineage", "expression",
      "signed_score", "pseudotime", "qc", "heatmap_annotation", "highlight"
    ),
    geometry = c("point", "fill", "line"),
    background = c("light", "dark"),
    cvd = TRUE,
    top = 5) {
  n <- .sc_validate_n(n, allow_null = FALSE)
  use <- match.arg(use)
  geometry <- match.arg(geometry)
  background <- match.arg(background)
  cvd <- .sc_validate_flag(cvd, "cvd")
  top <- .sc_validate_n(top, allow_null = FALSE)
  wanted_type <- .sc_use_type(use)
  meta <- .sc_db()$meta
  meta <- meta[meta$palette_type == wanted_type, , drop = FALSE]
  if (wanted_type == "qualitative") {
    meta <- meta[meta$max_n >= n | meta$palette_id == "chromatic", , drop = FALSE]
  }
  if (!nrow(meta)) {
    return(data.frame())
  }
  status_score <- c(recommended = 30, compatibility = 15, experimental = 5,
                    provenance_review = 0)
  score <- unname(status_score[meta$status])
  score[is.na(score)] <- 0
  intended <- vapply(meta$intended_use, function(z) {
    grepl(paste0("(^|,)", use, "(,|$)"), z)
  }, logical(1))
  score <- score + 25 * intended
  score <- score + 8 * grepl(paste0("(^|,)", geometry, "(,|$)"),
                             meta$recommended_geometry)
  score <- score + 8 * grepl(paste0("(^|,)", background, "(,|$)"),
                             meta$recommended_background)
  if (use == "condition" && n == 2L) {
    score <- score + 25 * grepl("paired", meta$notes, ignore.case = TRUE)
  }
  if (use == "cell_identity" && n > 20L) {
    score <- score + pmin(meta$max_n, 40) / 2
  }
  min_distance <- rep(NA_real_, nrow(meta))
  for (i in seq_len(nrow(meta))) {
    if (startsWith(meta$palette_id[[i]], "scico_") &&
        !requireNamespace("scico", quietly = TRUE)) next
    count <- if (wanted_type == "qualitative") n else min(meta$max_n[[i]], 9L)
    colors <- tryCatch(
      sc_palette(
        meta$palette_id[[i]], count,
        extend = if (wanted_type == "qualitative") "generate" else "error",
        background = background
      ),
      error = function(e) NULL
    )
    if (is.null(colors)) next
    modes <- if (cvd) c("none", "deutan", "protan", "tritan") else "none"
    audit <- sc_palette_audit(
      colors,
      background = if (background == "light") "#FFFFFF" else "#1A1A1A",
      cvd = modes
    )
    min_distance[[i]] <- min(audit$vision$min_distance, na.rm = TRUE)
  }
  score <- score + ifelse(is.finite(min_distance), pmin(min_distance, 20), 0)
  reason <- paste0(
    wanted_type, "; ",
    ifelse(intended, "registered for this use", "compatible by palette type"),
    "; ", meta$status,
    ifelse(meta$max_n >= n, "; sufficient fixed capacity", "; deterministic extension")
  )
  out <- data.frame(
    palette_id = meta$palette_id,
    reason = reason,
    capacity = meta$max_n,
    status = meta$status,
    min_cie2000 = min_distance,
    score = score,
    stringsAsFactors = FALSE
  )
  out <- out[order(-out$score, -out$capacity, out$palette_id), , drop = FALSE]
  utils::head(out, top)
}
