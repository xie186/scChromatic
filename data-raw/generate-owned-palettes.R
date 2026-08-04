# Deterministic generators for palettes owned by scChromatic. This file is
# sourced by build-palette-db.R and is excluded from the installed package.
generate_scchromatic_palettes <- function() {
  list(
    chromatic = sc_palette_generate(40L, background = "light"),
    chromatic_balance = toupper(colorspace::diverging_hcl(
      11L,
      h = c(250, 10),
      c = 75,
      l = c(35, 95),
      power = 1.1
    ))
  )
}

scchromatic_owned_palettes <- generate_scchromatic_palettes()
