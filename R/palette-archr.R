#' Create a scales-compatible ArchR palette
#'
#' ArchR colors are frozen from commit
#' `6feec354ad6c8052ddbc4626a2ca2d858ed465bf`.
#'
#' @param palette Original ArchR palette name.
#' @param alpha Opacity in `(0, 1]`.
#' @param reverse Reverse the color order.
#' @param selection Use audited priority order or literal source order.
#' @return A closure accepting the number of colors.
#' @export
#' @examples
#' pal_archr("stallion")(5)
pal_archr <- function(palette = "stallion", alpha = 1, reverse = FALSE,
                      selection = c("priority", "source")) {
  selection <- match.arg(selection)
  id <- .sc_palette_id(palette)
  if (!startsWith(id, "archr_")) {
    id <- paste0("archr_", id)
  }
  .sc_palette_row(id)
  sc_pal(id, alpha = alpha, reverse = reverse, selection = selection)
}
