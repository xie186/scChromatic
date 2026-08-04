test_that("mapping is independent of character label order", {
  a <- sc_color_map(c("B", "T", "NK", "Mono"))
  b <- sc_color_map(c("Mono", "NK", "T", "B"))
  expect_identical(as_named_colors(a), as_named_colors(b))
})

test_that("factors use declared levels including unused levels", {
  labels <- factor(c("T", "B"), levels = c("B", "T", "NK"))
  map <- sc_color_map(labels, order = "factor")
  expect_identical(names(as_named_colors(map)), c("B", "T", "NK"))
})

test_that("subsets and updates preserve assignments", {
  labels_full <- c("B", "T", "NK", "Mono")
  map <- sc_color_map(labels_full, palette = "chromatic")

  labels_subset <- c("T", "NK")
  subset_colors <- as_named_colors(map)[labels_subset]
  expect_identical(
    subset_colors,
    as_named_colors(map)[c("T", "NK")]
  )

  updated <- update_sc_color_map(map, c(labels_full, "DC"))
  expect_identical(
    as_named_colors(updated)[names(as_named_colors(map))],
    as_named_colors(map)
  )
})

test_that("existing mappings require unique names", {
  expect_error(sc_color_map("B", existing = "#000000"), "fully named")
  duplicate <- c(B = "#000000", B = "#FFFFFF")
  expect_error(sc_color_map("B", existing = duplicate), "duplicate")
})

test_that("versioned JSON and CSV round trips preserve registered maps", {
  map <- sc_color_map(c("B", "T", "NK"))
  for (extension in c(".json", ".csv")) {
    path <- tempfile(fileext = extension)
    write_sc_color_map(map, path)
    restored <- read_sc_color_map(path)
    expect_identical(as_named_colors(restored), as_named_colors(map))
    expect_identical(restored$schema, "scChromatic.color-map")
    expect_identical(restored$schema_version, 1L)
    expect_identical(restored$provenance, map$provenance)
  }
})

test_that("all schema metadata round trips and external maps update without a registry", {
  legacy <- tempfile(fileext = ".csv")
  utils::write.csv(
    data.frame(label = c("B", "T"), color = c("#000000", "#FFFFFF")),
    legacy, row.names = FALSE
  )
  map <- read_sc_color_map(legacy)
  map$map_type <- "derived"
  map$palette <- "derived:graph-v1"
  map$aliases <- c("B cell" = "B")
  map$locks <- c(B = TRUE, T = FALSE)
  map$history <- list(list(action = "created", score = 1.25))
  map$context <- list(method = "knn", samples = c("s1", "s2"))
  map$seed <- 42
  map$metadata <- list(ontology = "CL", ontology_version = "2026-07-23")

  for (extension in c(".json", ".csv")) {
    path <- tempfile(fileext = extension)
    write_sc_color_map(map, path)
    restored <- read_sc_color_map(path)
    for (field in names(map)) {
      expect_identical(restored[[field]], map[[field]], info = field)
    }
  }

  updated <- update_sc_color_map(map, c("B", "T", "NK"))
  expect_identical(as_named_colors(updated)[c("B", "T")], as_named_colors(map))
  expect_identical(updated$history, map$history)
  expect_identical(updated$context, map$context)
  expect_identical(updated$locks, map$locks)
  expect_identical(updated$aliases, map$aliases)
})

test_that("highlight maps retain focus metadata in both formats", {
  map <- sc_highlight_map(c("B", "T", "NK"), focus = c("B", "NK"))
  for (extension in c(".json", ".csv")) {
    path <- tempfile(fileext = extension)
    write_sc_color_map(map, path)
    restored <- read_sc_color_map(path)
    expect_identical(restored$map_type, "highlight")
    expect_identical(restored$focus, map$focus)
    expect_identical(restored$focus_palette, map$focus_palette)
    expect_identical(restored$other, map$other)
    expect_identical(as_named_colors(restored), as_named_colors(map))
  }
})

test_that("highlight updates use the stored muted color", {
  map <- sc_highlight_map(c("B", "T"), focus = "B", other = "grey85")
  map$na.value <- "#000000"
  updated <- update_sc_color_map(map, c("B", "T", "NK"))
  expect_identical(as_named_colors(updated)[["NK"]], map$other)
})

test_that("legacy maps migrate and unsupported future schemas are rejected", {
  legacy_json <- tempfile(fileext = ".json")
  jsonlite::write_json(list(
    palette = "unregistered-source",
    background = "dark",
    package_version = "0.1.0",
    na.value = "#BDBDBD",
    mapping = data.frame(label = c("B", "T"), color = c("#000000", "#FFFFFF"))
  ), legacy_json, auto_unbox = TRUE)
  migrated <- read_sc_color_map(legacy_json)
  expect_identical(migrated$schema_version, 1L)
  expect_identical(migrated$map_type, "external")
  expect_silent(update_sc_color_map(migrated, c("B", "T", "NK")))

  current <- tempfile(fileext = ".json")
  write_sc_color_map(sc_color_map(c("B", "T")), current)
  payload <- jsonlite::read_json(current, simplifyVector = FALSE)
  payload$schema_version <- 2L
  jsonlite::write_json(payload, current, auto_unbox = TRUE)
  expect_error(read_sc_color_map(current), "Unsupported color-map schema version")
})

test_that("map import validates labels, colors, and versioned CSV integrity", {
  for (mapping in list(
    data.frame(label = c("B", "B"), color = c("#000000", "#FFFFFF")),
    data.frame(label = c("B", ""), color = c("#000000", "#FFFFFF")),
    data.frame(label = c("B", "T"), color = c("#000000", "not-a-color"))
  )) {
    path <- tempfile(fileext = ".csv")
    utils::write.csv(mapping, path, row.names = FALSE)
    expect_error(read_sc_color_map(path))
  }

  path <- tempfile(fileext = ".csv")
  write_sc_color_map(sc_color_map(c("B", "T")), path)
  table <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  first_mapping <- which(table$record_type == "mapping")[[1L]]
  table$color[[first_mapping]] <- "#123456"
  utils::write.csv(table, path, row.names = FALSE)
  expect_error(read_sc_color_map(path), "do not match")
})

test_that("installed schema declares the supported payload version", {
  path <- system.file("schema", "sc-color-map.schema.json", package = "scChromatic")
  expect_true(nzchar(path))
  schema <- jsonlite::read_json(path, simplifyVector = FALSE)
  expect_identical(schema$properties$schema$const, "scChromatic.color-map")
  expect_identical(schema$properties$schema_version$const, 1L)
  expect_identical(
    unlist(schema$properties$map_type$enum, use.names = FALSE),
    c("registered", "external", "derived", "hierarchy", "highlight")
  )
  expect_identical(schema$properties$mapping$minItems, 1L)
})

test_that("every map type emits fields declared by the installed schema", {
  legacy <- tempfile(fileext = ".csv")
  utils::write.csv(
    data.frame(label = "B", color = "#000000"), legacy, row.names = FALSE
  )
  derived <- read_sc_color_map(legacy)
  derived$map_type <- "derived"
  derived$palette <- "derived:test"
  maps <- list(
    registered = sc_color_map(c("B", "T")),
    external = read_sc_color_map(legacy),
    derived = derived,
    hierarchy = suppressWarnings(sc_hierarchy_map(c("L", "M"), c("B", "Mono"))),
    highlight = sc_highlight_map(c("B", "T"), "B")
  )
  schema_path <- system.file(
    "schema", "sc-color-map.schema.json", package = "scChromatic"
  )
  schema <- jsonlite::read_json(schema_path, simplifyVector = FALSE)
  declared <- names(schema$properties)
  for (type in names(maps)) {
    path <- tempfile(fileext = ".json")
    write_sc_color_map(maps[[type]], path)
    payload <- jsonlite::read_json(path, simplifyVector = FALSE)
    expect_identical(payload$map_type, type)
    expect_true(all(names(payload) %in% declared))
    expect_identical(payload$schema, "scChromatic.color-map")
    expect_identical(payload$schema_version, 1L)
    expect_gte(length(payload$mapping), 1L)
    if (identical(type, "highlight")) {
      expect_type(payload$focus, "list")
      expect_length(payload$focus, 1L)
    }
  }
})

test_that("map invariants reject empty and type-incomplete mappings", {
  expect_error(sc_color_map(character()), "at least one")

  map <- sc_color_map("B")
  map$map_type <- "unknown"
  expect_error(write_sc_color_map(map, tempfile(fileext = ".json")), "map_type")

  map$map_type <- "hierarchy"
  expect_error(write_sc_color_map(map, tempfile(fileext = ".json")), "require")

  hierarchy <- suppressWarnings(sc_hierarchy_map("Lymphoid", "B"))
  hierarchy$parent_palette <- NULL
  expect_error(
    write_sc_color_map(hierarchy, tempfile(fileext = ".json")),
    "parent_palette"
  )

  map <- sc_color_map(c("B", "T"))
  map$locks <- c(B = TRUE)
  table <- as.data.frame(map)
  expect_identical(table$locked, c(TRUE, FALSE))
})

test_that("map subsetting retains class and exact assignments", {
  map <- sc_color_map(c("B", "T", "NK"))
  subset <- map[c("T", "NK")]
  expect_s3_class(subset, "sc_color_map")
  expect_identical(as_named_colors(subset), as_named_colors(map)[c("T", "NK")])
})
