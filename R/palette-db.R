.sc_db <- function() {
  sc_palette_db
}

.sc_palette_row <- function(palette) {
  id <- .sc_palette_id(palette)
  meta <- .sc_db()$meta
  hit <- which(meta$palette_id == id)
  if (!length(hit)) {
    ids <- meta$palette_id
    distance <- utils::adist(id, ids)
    suggestion <- ids[order(distance)][seq_len(min(3L, length(ids)))]
    .sc_abort(c(
      "Unknown palette {.val {palette}}.",
      "i" = "Did you mean {paste(suggestion, collapse = ', ')}?",
      "i" = "Use {.fun sc_palette_names} to list registered palettes."
    ))
  }
  meta[hit[[1L]], , drop = FALSE]
}

.sc_palette_colors <- function(id, selection = "priority") {
  entry <- .sc_db()$colors[[id]]
  if (is.null(entry)) {
    return(character())
  }
  entry[[selection]]
}
