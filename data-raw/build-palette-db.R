source("data-raw/palettes-archr.R")
source("data-raw/palettes-core.R")

normalize_hex <- function(x) {
  rgb <- grDevices::col2rgb(x, alpha = TRUE)
  out <- grDevices::rgb(
    rgb[1L, ], rgb[2L, ], rgb[3L, ], alpha = rgb[4L, ], maxColorValue = 255
  )
  opaque <- rgb[4L, ] == 255
  out[opaque] <- substr(out[opaque], 1L, 7L)
  out <- toupper(out)
  names(out) <- names(x)
  out
}

archr_ids <- c(
  stallion = "archr_stallion",
  stallion2 = "archr_stallion2",
  calm = "archr_calm",
  kelly = "archr_kelly",
  bear = "archr_bear",
  ironMan = "archr_iron_man",
  circus = "archr_circus",
  paired = "archr_paired",
  grove = "archr_grove",
  summerNight = "archr_summer_night",
  captain = "archr_captain",
  horizon = "archr_horizon",
  horizonExtra = "archr_horizon_extra",
  blueYellow = "archr_blue_yellow",
  whiteRed = "archr_white_red",
  comet = "archr_comet",
  beach = "archr_beach",
  coolwarm = "archr_coolwarm",
  fireworks = "archr_fireworks",
  greyMagma = "archr_grey_magma",
  fireworks2 = "archr_fireworks2",
  purpleOrange = "archr_purple_orange"
)

colors <- list()
for (source_name in names(archr_ids)) {
  id <- unname(archr_ids[[source_name]])
  source_colors <- normalize_hex(archr_palettes[[source_name]])
  priority <- if (source_name %in% archr_discrete) {
    source_colors[order(as.integer(names(source_colors)))]
  } else {
    source_colors
  }
  colors[[id]] <- list(source = source_colors, priority = priority)
}
for (id in names(core_palettes)) {
  value <- normalize_hex(core_palettes[[id]])
  colors[[id]] <- list(source = value, priority = value)
}

meta_row <- function(
    palette_id, source, source_palette, palette_type, max_n, intended_use,
    recommended_geometry = "point,fill,line",
    recommended_background = "light,dark", status = "recommended",
    source_url = NA_character_, source_commit = NA_character_,
    citation = NA_character_, license = NA_character_, derived = FALSE,
    source_cvd_claim = NA_character_, notes = "",
    source_order = "literal vector order in internal palette database",
    priority_order = "same as source order") {
  data.frame(
    palette_id = palette_id,
    source = source,
    source_palette = source_palette,
    palette_type = palette_type,
    max_n = as.integer(max_n),
    intended_use = intended_use,
    recommended_geometry = recommended_geometry,
    recommended_background = recommended_background,
    status = status,
    source_order = source_order,
    priority_order = priority_order,
    source_url = source_url,
    source_commit = source_commit,
    citation = citation,
    license = license,
    derived = derived,
    source_cvd_claim = source_cvd_claim,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

archr_url <- paste0(
  "https://raw.githubusercontent.com/GreenleafLab/ArchR/",
  "6feec354ad6c8052ddbc4626a2ca2d858ed465bf/R/ColorPalettes.R"
)
archr_meta <- do.call(rbind, lapply(names(archr_ids), function(source_name) {
  id <- unname(archr_ids[[source_name]])
  discrete <- source_name %in% archr_discrete
  meta_row(
    id, "ArchR", source_name,
    if (discrete) "qualitative" else if (source_name %in% c(
      "coolwarm", "fireworks", "fireworks2"
    )) "diverging" else "sequential",
    if (discrete) length(archr_palettes[[source_name]]) else 256L,
    if (discrete) {
      "cell_identity,sample,condition,lineage,heatmap_annotation"
    } else {
      "expression,pseudotime,qc"
    },
    status = "compatibility",
    source_url = archr_url,
    source_commit = "6feec354ad6c8052ddbc4626a2ca2d858ed465bf",
    citation = "Granja et al. (2021), Nature Genetics 53:403-411; ArchR software.",
    license = "MIT (ArchR code); individual borrowed-palette terms may differ",
    derived = FALSE,
    notes = "Frozen compatibility palette; original source terms should be reviewed for redistribution.",
    priority_order = if (discrete) {
      "ascending numeric source labels used by ArchR paletteDiscrete"
    } else {
      "same as source order to preserve the continuous gradient"
    }
  )
}))

core_specs <- list(
  okabe_ito = list(
    "Okabe-Ito", "qualitative", "cell_identity,sample,condition,highlight",
    "https://jfly.uni-koeln.de/color/", "Okabe and Ito color universal design palette",
    "Publicly documented palette", FALSE,
    "Designed for common forms of color-vision deficiency.", "paired contrast"
  ),
  tol_bright = list(
    "Paul Tol", "qualitative", "cell_identity,sample,condition,highlight",
    "https://personal.sron.nl/~pault/", "Paul Tol colour schemes",
    "Free for personal and commercial use with attribution", FALSE,
    "Designed with color-vision deficiencies in mind.", "paired contrast"
  ),
  tol_vibrant = list(
    "Paul Tol", "qualitative", "cell_identity,sample,condition,highlight",
    "https://personal.sron.nl/~pault/", "Paul Tol colour schemes",
    "Free for personal and commercial use with attribution", FALSE,
    "Designed with color-vision deficiencies in mind.", ""
  ),
  tol_muted = list(
    "Paul Tol", "qualitative", "cell_identity,sample,lineage,heatmap_annotation",
    "https://personal.sron.nl/~pault/", "Paul Tol colour schemes",
    "Free for personal and commercial use with attribution", FALSE,
    "Designed with color-vision deficiencies in mind.", ""
  ),
  tol_medium_contrast = list(
    "Paul Tol", "qualitative", "condition,sample,highlight",
    "https://personal.sron.nl/~pault/", "Paul Tol colour schemes",
    "Free for personal and commercial use with attribution", FALSE,
    "Designed with color-vision deficiencies in mind.", "paired contrast"
  ),
  glasbey32 = list(
    "Glasbey et al.", "qualitative", "cell_identity,sample,heatmap_annotation",
    "https://doi.org/10.1002/col.20327",
    "Glasbey et al. (2007), Color Research and Application 32:304-309",
    "Palette provenance review", FALSE, "No universal CVD-safety claim.",
    "High-cardinality; perceptual distinction decreases as n grows."
  ),
  polychrome36 = list(
    "Polychrome", "qualitative", "cell_identity,sample,heatmap_annotation",
    "https://doi.org/10.18637/jss.v090.c01",
    "Coombes et al. (2019), Journal of Statistical Software 90, Code Snippet 1",
    "GPL-2", FALSE, "No universal CVD-safety claim.",
    "High-cardinality; combine color with redundant encodings."
  ),
  ditto40 = list(
    "dittoSeq", "qualitative", "cell_identity,sample,heatmap_annotation",
    "https://github.com/dtm2451/dittoSeq/blob/master/R/dittoColors.R",
    "Bunis et al. (2020), Bioinformatics 36:5535-5536",
    "MIT", TRUE,
    "Only the first seven are the strongest red-green CVD-aware subset.",
    "Entries 8-40 are grey and lighter/darker extensions; not fully CVD safe."
  ),
  chromatic = list(
    "scChromatic", "qualitative", "cell_identity,sample,lineage,heatmap_annotation",
    "https://github.com/xie186/scChromatic", "scChromatic package authors",
    "GPL (>= 3)", TRUE,
    "Perceptually optimized and audited; no universal CVD-safety claim.",
    "Frozen nested maximin sequence generated in HCL with normal/CVD diagnostics."
  ),
  chromatic_balance = list(
    "scChromatic", "diverging", "signed_score",
    "https://github.com/xie186/scChromatic",
    "Zeileis et al. (2020), Journal of Statistical Software 96:1",
    "GPL (>= 3)", TRUE,
    "Audited under common CVD simulations; no universal CVD-safety claim.",
    paste(
      "Frozen HCL-derived anchors generated with colorspace::diverging_hcl;",
      "blue is negative, neutral is zero, and red is positive."
    )
  ),
  viridis = list(
    "viridisLite", "sequential", "expression,pseudotime,qc",
    "https://sjmgarnier.github.io/viridisLite/", "Garnier et al., viridisLite",
    "MIT", FALSE, "Designed to remain legible under common CVD simulations.", ""
  ),
  cividis = list(
    "viridisLite", "sequential", "expression,pseudotime,qc",
    "https://sjmgarnier.github.io/viridisLite/", "Garnier et al., viridisLite",
    "MIT", FALSE, "Optimized for common CVD and grayscale viewing.", ""
  ),
  magma = list(
    "viridisLite", "sequential", "expression,pseudotime,qc",
    "https://sjmgarnier.github.io/viridisLite/", "Garnier et al., viridisLite",
    "MIT", FALSE, "Designed to remain legible under common CVD simulations.", ""
  )
)
core_meta <- do.call(rbind, lapply(names(core_specs), function(id) {
  spec <- core_specs[[id]]
  meta_row(
    id, spec[[1L]], id, spec[[2L]],
    if (spec[[2L]] == "qualitative") length(core_palettes[[id]]) else 256L,
    spec[[3L]], source_url = spec[[4L]], citation = spec[[5L]],
    license = spec[[6L]], derived = spec[[7L]], source_cvd_claim = spec[[8L]],
    notes = spec[[9L]],
    priority_order = if (id == "chromatic") {
      "frozen nested maximin order; each prefix is stable"
    } else {
      "same as source order"
    },
    status = if (id %in% c("glasbey32", "polychrome36")) {
      "provenance_review"
    } else {
      "recommended"
    }
  )
}))

scico_ids <- c("scico_batlow", "scico_lajolla", "scico_vik", "scico_broc")
scico_meta <- do.call(rbind, lapply(scico_ids, function(id) {
  meta_row(
    id, "scico", sub("^scico_", "", id),
    if (id %in% c("scico_vik", "scico_broc")) "diverging" else "sequential",
    256L, if (id %in% c("scico_vik", "scico_broc")) {
      "signed_score"
    } else {
      "expression,pseudotime,qc"
    },
    status = "compatibility",
    source_url = "https://github.com/thomasp85/scico",
    citation = "Crameri, Shephard and Heron (2020), Nature Communications 11:5444",
    license = "MIT (scico package); Scientific colour maps terms apply",
    source_cvd_claim = "Scientific colour maps are perceptually uniform and CVD-aware.",
    notes = "Optional runtime interoperability; requires the suggested scico package.",
    source_order = "provided at runtime by the optional scico package",
    priority_order = "same as source order"
  )
}))

meta <- rbind(core_meta, scico_meta, archr_meta)

audit_values <- function(value) {
  value <- unique(unname(value))
  rgb <- farver::decode_colour(value, to = "rgb")
  distances <- farver::compare_colour(rgb, rgb, from_space = "rgb", method = "cie2000")
  d <- distances[upper.tri(distances)]
  c(
    min_cie2000 = if (length(d)) min(d) else NA_real_,
    min_contrast_light = min(colorspace::contrast_ratio(value, "#FFFFFF")),
    min_contrast_dark = min(colorspace::contrast_ratio(value, "#1A1A1A"))
  )
}
audits <- lapply(meta$palette_id, function(id) {
  if (startsWith(id, "scico_")) return(rep(NA_real_, 3L))
  audit_values(colors[[id]]$priority)
})
audit_matrix <- do.call(rbind, audits)
meta$audit_min_cie2000 <- audit_matrix[, 1L]
meta$audit_min_contrast_light <- audit_matrix[, 2L]
meta$audit_min_contrast_dark <- audit_matrix[, 3L]
meta$audit_date <- "2026-07-30"

sc_palette_db <- list(meta = meta, colors = colors)
save(sc_palette_db, file = "R/sysdata.rda", compress = "xz", version = 3)
utils::write.csv(meta, "data-raw/palette-registry.csv", row.names = FALSE, na = "")
utils::write.csv(
  meta, "inst/extdata/palette-provenance.csv", row.names = FALSE, na = ""
)
