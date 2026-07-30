# Build a small deterministic PBMC-like dataset for examples and vignettes.
cell_types <- c("B cell", "CD4 T", "CD8 T", "NK", "Monocyte", "Dendritic")
lineages <- c("Lymphoid", "Lymphoid", "Lymphoid", "Lymphoid", "Myeloid", "Myeloid")
centers <- data.frame(
  UMAP1 = c(-3.0, -1.2, 1.0, 3.0, -1.2, 1.7),
  UMAP2 = c(1.4, 2.2, 2.0, 1.1, -2.0, -2.1)
)
n_each <- 120L
within <- rep(seq_len(n_each), times = length(cell_types))
type_index <- rep(seq_along(cell_types), each = n_each)
angle <- within * pi * (3 - sqrt(5)) + type_index / 3
radius <- sqrt((within - 0.5) / n_each) * (0.72 + 0.08 * sin(within / 9))
sample_index <- (within - 1L) %% 4L + 1L
condition <- ifelse(sample_index <= 2L, "Control", "Stimulated")

sc_example <- data.frame(
  cell_id = sprintf("cell_%04d", seq_along(within)),
  UMAP1 = centers$UMAP1[type_index] + radius * cos(angle) +
    ifelse(condition == "Stimulated", 0.12, -0.12),
  UMAP2 = centers$UMAP2[type_index] + radius * sin(angle),
  cell_type = factor(cell_types[type_index], levels = cell_types),
  lineage = factor(lineages[type_index], levels = c("Lymphoid", "Myeloid")),
  sample = factor(paste("Sample", sample_index), levels = paste("Sample", 1:4)),
  condition = factor(condition, levels = c("Control", "Stimulated")),
  MS4A1 = round(pmax(
    0,
    ifelse(type_index == 1L, 3.8, 0.25) +
      0.35 * sin(within / 7) +
      ifelse(condition == "Stimulated", 0.2, 0)
  ), 3),
  signed_score = round(
    ifelse(condition == "Stimulated", 0.9, -0.9) +
      0.45 * sin(within / 8 + type_index),
    3
  ),
  pseudotime = round(pmin(
    1,
    (within - 1) / (n_each - 1) * 0.8 + ifelse(type_index >= 5L, 0.2, 0)
  ), 3),
  percent_mito = round(
    3 + 6 * (0.5 + 0.5 * sin(within / 11 + type_index)) +
      ifelse(sample_index == 4L, 1.5, 0),
    2
  ),
  n_counts = as.integer(round(
    1800 + 650 * (0.5 + 0.5 * cos(within / 13 + type_index)) +
      ifelse(condition == "Stimulated", 250, 0)
  )),
  stringsAsFactors = FALSE
)

dir.create("data", showWarnings = FALSE)
save(sc_example, file = "data/sc_example.rda", compress = "xz", version = 3)
