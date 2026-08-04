source("R/utils.R")
source("R/palette-generate.R")
source("R/palette-d3.R")

build_versions <- c(
  colorspace = "2.1.3",
  farver = "2.1.2",
  viridisLite = "0.4.3",
  scico = "1.5.0"
)
for (package in names(build_versions)) {
  expected <- unname(build_versions[[package]])
  if (!requireNamespace(package, quietly = TRUE)) {
    stop("Build requires ", package, " ", expected, "; it is not installed.", call. = FALSE)
  }
  installed <- as.character(utils::packageVersion(package))
  if (!identical(installed, expected)) {
    stop(
      "Build requires ", package, " ", expected, "; found ", installed, ".",
      call. = FALSE
    )
  }
}

source("data-raw/generate-owned-palettes.R")
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

colors <- list()
for (id in names(core_palettes)) {
  value <- normalize_hex(core_palettes[[id]])
  priority <- switch(
    id,
    okabe_ito = value[c(2:8, 1)],
    tol_medium_contrast = value[c(3, 6, 1, 5, 4, 2)],
    glasbey32 = value[c(2:32, 1)],
    d3_cool = rev(value),
    value
  )
  entry <- list(
    source = value,
    priority = priority
  )
  if (id %in% names(provider_interpolation_luts)) {
    entry$interpolation <- normalize_hex(provider_interpolation_luts[[id]])
  }
  colors[[id]] <- entry
}

meta_row <- function(
    palette_id, source, source_palette, palette_type, max_n, intended_use,
    recommended_geometry = "point,fill,line",
    recommended_background = "light,dark", status = "recommended",
    source_url = NA_character_, source_version = NA_character_,
    source_commit = NA_character_, source_sha256 = NA_character_,
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
    source_version = source_version,
    source_commit = source_commit,
    source_sha256 = source_sha256,
    citation = citation,
    license = license,
    derived = derived,
    source_cvd_claim = source_cvd_claim,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

core_specs <- list(
  okabe_ito = list(
    "khroma", "qualitative", "cell_identity,sample,condition,highlight",
    "https://cran.r-project.org/src/contrib/khroma_1.17.0.tar.gz",
    "Okabe and Ito color universal design palette; khroma 1.17.0",
    "GPL (>= 3) (khroma 1.17.0)", TRUE,
    "Designed for common forms of color-vision deficiency.",
    "Black is moved from first to last in priority order; paired contrast."
  ),
  tol_bright = list(
    "khroma", "qualitative", "cell_identity,sample,condition,highlight",
    "https://cran.r-project.org/src/contrib/khroma_1.17.0.tar.gz",
    "Paul Tol colour schemes; khroma 1.17.0",
    "GPL (>= 3) (khroma 1.17.0)", FALSE,
    "Designed with color-vision deficiencies in mind.", "paired contrast"
  ),
  tol_vibrant = list(
    "khroma", "qualitative", "cell_identity,sample,condition,highlight",
    "https://cran.r-project.org/src/contrib/khroma_1.17.0.tar.gz",
    "Paul Tol colour schemes; khroma 1.17.0",
    "GPL (>= 3) (khroma 1.17.0)", FALSE,
    "Designed with color-vision deficiencies in mind.", ""
  ),
  tol_muted = list(
    "khroma", "qualitative", "cell_identity,sample,lineage,heatmap_annotation",
    "https://cran.r-project.org/src/contrib/khroma_1.17.0.tar.gz",
    "Paul Tol colour schemes; khroma 1.17.0",
    "GPL (>= 3) (khroma 1.17.0)", FALSE,
    "Designed with color-vision deficiencies in mind.", ""
  ),
  tol_medium_contrast = list(
    "khroma", "qualitative", "condition,sample,highlight",
    "https://cran.r-project.org/src/contrib/khroma_1.17.0.tar.gz",
    "Paul Tol colour schemes; khroma 1.17.0",
    "GPL (>= 3) (khroma 1.17.0)", TRUE,
    "Designed for medium-contrast color pairs.",
    "Priority order is rearranged for adjacent light/dark pair contrast."
  ),
  glasbey32 = list(
    "Polychrome", "qualitative", "cell_identity,sample,heatmap_annotation",
    "https://cran.r-project.org/src/contrib/Polychrome_1.6.1.tar.gz",
    paste(
      "Glasbey et al. (2007), Color Research and Application 32:304-309;",
      "Polychrome 1.6.1"
    ),
    "Apache-2.0 (Polychrome 1.6.1)", TRUE,
    "No universal CVD-safety claim.",
    paste(
      "Exact Polychrome glasbey object; white is moved from first to last in",
      "priority order. High-cardinality distinction decreases as n grows."
    )
  ),
  polychrome36 = list(
    "Polychrome", "qualitative", "cell_identity,sample,heatmap_annotation",
    "https://cran.r-project.org/src/contrib/Polychrome_1.6.1.tar.gz",
    paste(
      "Coombes et al. (2019), Journal of Statistical Software 90, Code Snippet 1;",
      "Polychrome 1.6.1"
    ),
    "Apache-2.0 (Polychrome 1.6.1)", FALSE,
    "No universal CVD-safety claim.",
    "Exact Polychrome palette36 object; combine color with redundant encodings."
  ),
  ditto40 = list(
    "dittoSeq", "qualitative", "cell_identity,sample,heatmap_annotation",
    "https://bioconductor.org/packages/3.23/bioc/src/contrib/dittoSeq_1.24.0.tar.gz",
    "Bunis et al. (2020), Bioinformatics 36:5535-5536; dittoSeq 1.24.0",
    "MIT (dittoSeq 1.24.0)", FALSE,
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
  d3_rainbow = list(
    "D3 Scale Chromatic", "cyclic",
    "cell_identity,sample,condition,lineage,heatmap_annotation",
    paste0(
      "https://github.com/d3/d3-scale-chromatic/blob/",
      "05e76dafaa89059153e177a4f57d9af985ba49a8/",
      "src/sequential-multi/rainbow.js"
    ),
    paste(
      "Bostock, d3-scale-chromatic 1.5.0 less-angry rainbow;",
      "CELLXGENE categorical color compatibility."
    ),
    "BSD-3-Clause (d3-scale-chromatic); CELLXGENE behavior referenced under MIT",
    TRUE, "No source CVD-safety claim.",
    paste(
      "Dynamic compatibility palette sampled at t = 0:(n - 1) / n;",
      "the stored 200-color reference is for audit only. CELLXGENE behavior",
      "verified at commit 76a39fcf92da57c9e4fd59831ad805a3b007da8c.",
      "Cyclic order is not nested, so assignments change when n changes."
    )
  ),
  d3_cool = list(
    "D3 Scale Chromatic", "sequential", "expression,pseudotime,qc",
    paste0(
      "https://github.com/d3/d3-scale-chromatic/blob/",
      "05e76dafaa89059153e177a4f57d9af985ba49a8/",
      "src/sequential-multi/rainbow.js"
    ),
    paste(
      "Bostock, d3-scale-chromatic 1.5.0; Niccoli perceptual rainbow;",
      "CELLXGENE continuous color compatibility."
    ),
    "BSD-3-Clause (d3-scale-chromatic); CELLXGENE behavior referenced under MIT",
    TRUE, "No source CVD-safety claim.",
    paste(
      "Exact 100 source bins sampled at t = 0:99 / 100; priority order is",
      "reversed to match CELLXGENE low-to-high data mapping at commit",
      "76a39fcf92da57c9e4fd59831ad805a3b007da8c."
    )
  ),
  viridis = list(
    "viridisLite", "sequential", "expression,pseudotime,qc",
    "https://cran.r-project.org/src/contrib/viridisLite_0.4.3.tar.gz",
    "Garnier et al., viridisLite 0.4.3",
    "MIT (viridisLite 0.4.3)", FALSE,
    "Designed to remain legible under common CVD simulations.", ""
  ),
  cividis = list(
    "viridisLite", "sequential", "expression,pseudotime,qc",
    "https://cran.r-project.org/src/contrib/viridisLite_0.4.3.tar.gz",
    "Garnier et al., viridisLite 0.4.3; Nunez, Anderton, and Renslow (2018)",
    "MIT (viridisLite 0.4.3)", FALSE,
    "Optimized for common CVD and grayscale viewing.", ""
  ),
  magma = list(
    "viridisLite", "sequential", "expression,pseudotime,qc",
    "https://cran.r-project.org/src/contrib/viridisLite_0.4.3.tar.gz",
    "Garnier et al., viridisLite 0.4.3",
    "MIT (viridisLite 0.4.3)", FALSE,
    "Designed to remain legible under common CVD simulations.", ""
  )
)
core_meta <- do.call(rbind, lapply(names(core_specs), function(id) {
  spec <- core_specs[[id]]
  source_palette <- switch(
    id,
    okabe_ito = "okabeito",
    tol_bright = "bright",
    tol_vibrant = "vibrant",
    tol_muted = "muted",
    tol_medium_contrast = "mediumcontrast",
    glasbey32 = "glasbey",
    polychrome36 = "palette36",
    ditto40 = "dittoColors",
    d3_rainbow = "interpolateRainbow",
    d3_cool = "interpolateCool",
    id
  )
  meta_row(
    id, spec[[1L]], source_palette, spec[[2L]],
    if (id == "d3_rainbow") {
      200L
    } else if (id == "d3_cool") {
      100L
    } else if (spec[[2L]] == "qualitative") {
      length(core_palettes[[id]])
    } else {
      256L
    },
    spec[[3L]], source_url = spec[[4L]], citation = spec[[5L]],
    license = spec[[6L]], derived = spec[[7L]], source_cvd_claim = spec[[8L]],
    notes = spec[[9L]],
    source_version = if (id %in% c(
      "okabe_ito", "tol_bright", "tol_vibrant", "tol_muted",
      "tol_medium_contrast"
    )) {
      "khroma 1.17.0"
    } else if (id %in% c("glasbey32", "polychrome36")) {
      "Polychrome 1.6.1"
    } else if (id == "ditto40") {
      "dittoSeq 1.24.0"
    } else if (id %in% c("viridis", "cividis", "magma")) {
      "viridisLite 0.4.3"
    } else if (id %in% c("d3_rainbow", "d3_cool")) {
      "d3-scale-chromatic 1.5.0"
    } else {
      NA_character_
    },
    source_sha256 = if (id %in% c(
      "okabe_ito", "tol_bright", "tol_vibrant", "tol_muted",
      "tol_medium_contrast"
    )) {
      "40ba0f49e19710453fce918d1e036c4fcb6c7d3a70186236b8ad6b9f777c180f"
    } else if (id %in% c("glasbey32", "polychrome36")) {
      "4213cfb6247b58153d3668ea09a2691e99939cb2618ba322c80f95894acac58c"
    } else if (id == "ditto40") {
      "5c08274913e93158a9660507d50f5e79d4facbe01ab745e4fee0cd703e13454e"
    } else if (id %in% c("viridis", "cividis", "magma")) {
      "433be9bde66234dc76301fb4ffbbc9fc74bab5c14f4548d8ef2fc0065e121ef5"
    } else {
      NA_character_
    },
    source_commit = if (id %in% c("d3_rainbow", "d3_cool")) {
      "05e76dafaa89059153e177a4f57d9af985ba49a8"
    } else {
      NA_character_
    },
    source_order = if (id == "d3_rainbow") {
      "dynamic D3 samples t = 0:(n - 1) / n; 200-color audit reference stored"
    } else if (id == "d3_cool") {
      "100 D3 interpolateCool source bins sampled at t = 0:99 / 100"
    } else if (id %in% c(
      "okabe_ito", "tol_bright", "tol_vibrant", "tol_muted",
      "tol_medium_contrast", "glasbey32", "polychrome36", "ditto40"
    )) {
      "exact hexadecimal order of the pinned package object"
    } else if (id %in% c("chromatic", "chromatic_balance")) {
      "deterministically regenerated by data-raw/generate-owned-palettes.R"
    } else if (id %in% c("viridis", "cividis", "magma")) {
      "exact 256-color LUT generated by the pinned viridisLite function"
    } else {
      "literal vector order in internal palette database"
    },
    priority_order = if (id == "chromatic") {
      "frozen nested maximin order; each prefix is stable"
    } else if (id == "d3_rainbow") {
      "same dynamic D3 sample order as source"
    } else if (id == "d3_cool") {
      "reverse source order to match CELLXGENE low-to-high data mapping"
    } else if (id == "okabe_ito") {
      "source order with black moved from first to last"
    } else if (id == "tol_medium_contrast") {
      "source colors reordered into adjacent light/dark contrast pairs"
    } else if (id == "glasbey32") {
      "source order with white moved from first to last"
    } else {
      "same as source order"
    },
    status = if (id %in% c("d3_rainbow", "d3_cool")) {
      "compatibility"
    } else if (id %in% c("glasbey32", "polychrome36")) {
      "compatibility"
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
    source_url = "https://cran.r-project.org/src/contrib/scico_1.5.0.tar.gz",
    source_version = "scico 1.5.0; Scientific colour maps 7.0.1",
    source_sha256 = "647121b3f64118b162a35f9709a301f696239e9a707a04559c0368617c01c9b0",
    citation = "Crameri, Shephard and Heron (2020), Nature Communications 11:5444",
    license = "MIT (scico 1.5.0); CC BY 4.0 (Scientific colour maps)",
    source_cvd_claim = "Scientific colour maps are perceptually uniform and CVD-aware.",
    notes = paste(
      "Exact unmodified 256-color LUT generated by scico 1.5.0 and bundled",
      "for dependency-free, reproducible interoperability."
    ),
    source_order = "exact 256-color LUT generated by pinned scico 1.5.0",
    priority_order = "same as source order"
  )
}))

meta <- rbind(core_meta, scico_meta)

required_text <- c(
  "palette_id", "source", "source_palette", "source_url", "citation", "license"
)
for (field in required_text) {
  if (anyNA(meta[[field]]) || any(!nzchar(meta[[field]]))) {
    stop("Registry field ", field, " must be complete for every palette.", call. = FALSE)
  }
}
if (anyDuplicated(meta$palette_id)) {
  stop("Registry palette IDs must be unique.", call. = FALSE)
}
if (any(meta$status == "provenance_review")) {
  stop("Unresolved provenance_review rows cannot be shipped.", call. = FALSE)
}
has_commit <- !is.na(meta$source_commit) & nzchar(meta$source_commit)
has_archive <- !is.na(meta$source_sha256) & nzchar(meta$source_sha256)
third_party <- meta$source != "scChromatic"
if (any(third_party & !(has_commit | has_archive))) {
  stop("Every third-party palette requires a source commit or archive hash.", call. = FALSE)
}
if (any(has_archive & !grepl("^[0-9a-f]{64}$", meta$source_sha256))) {
  stop("Registry source_sha256 values must be lowercase SHA-256 hashes.", call. = FALSE)
}

min_cie2000 <- function(value) {
  rgb <- farver::decode_colour(value, to = "rgb")
  distances <- farver::compare_colour(rgb, rgb, from_space = "rgb", method = "cie2000")
  d <- distances[upper.tri(distances)]
  if (length(d)) min(d) else NA_real_
}

audit_values <- function(value) {
  value <- unname(value)
  c(
    min_cie2000 = min_cie2000(value),
    min_cie2000_deutan = min_cie2000(colorspace::deutan(value)),
    min_cie2000_protan = min_cie2000(colorspace::protan(value)),
    min_cie2000_tritan = min_cie2000(colorspace::tritan(value)),
    min_contrast_light = min(colorspace::contrast_ratio(value, "#FFFFFF")),
    min_contrast_dark = min(colorspace::contrast_ratio(value, "#1A1A1A"))
  )
}
audit_inputs <- stats::setNames(lapply(meta$palette_id, function(id) {
  colors[[id]]$priority
}), meta$palette_id)
audits <- lapply(audit_inputs, audit_values)
audit_matrix <- do.call(rbind, audits)
meta$audit_min_cie2000 <- audit_matrix[, 1L]
meta$audit_min_cie2000_deutan <- audit_matrix[, 2L]
meta$audit_min_cie2000_protan <- audit_matrix[, 3L]
meta$audit_min_cie2000_tritan <- audit_matrix[, 4L]
meta$audit_min_contrast_light <- audit_matrix[, 5L]
meta$audit_min_contrast_dark <- audit_matrix[, 6L]
meta$audit_n <- lengths(audit_inputs)
meta$audit_basis <- "stored priority-order reference vector"
meta$audit_method <- paste0(
  "CIEDE2000 via farver ", utils::packageVersion("farver"),
  "; CVD simulation via colorspace ", utils::packageVersion("colorspace")
)
meta$audit_date <- "2026-08-04"

expected_columns <- c(
  "palette_id", "source", "source_palette", "palette_type", "max_n",
  "intended_use", "recommended_geometry", "recommended_background", "status",
  "source_order", "priority_order", "source_url", "source_version",
  "source_commit", "source_sha256", "citation", "license", "derived",
  "source_cvd_claim", "notes", "audit_min_cie2000",
  "audit_min_cie2000_deutan", "audit_min_cie2000_protan",
  "audit_min_cie2000_tritan", "audit_min_contrast_light",
  "audit_min_contrast_dark", "audit_n", "audit_basis", "audit_method",
  "audit_date"
)
if (!identical(names(meta), expected_columns)) {
  stop("Registry columns or ordering changed unexpectedly.", call. = FALSE)
}

sc_palette_db <- list(meta = meta, colors = colors)
save(sc_palette_db, file = "R/sysdata.rda", compress = "xz", version = 3)
utils::write.csv(meta, "data-raw/palette-registry.csv", row.names = FALSE, na = "")
utils::write.csv(
  meta, "inst/extdata/palette-provenance.csv", row.names = FALSE, na = ""
)
