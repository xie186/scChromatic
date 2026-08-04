# scChromatic (development version)

* Removes the unresolved ArchR palette snapshot and all installed `archr_*`
  registry entries; ArchR is no longer a package or palette-data dependency.
* Pins every remaining third-party palette to an exact licensed source package,
  version, URL, and SHA-256 checksum, and resolves the Glasbey and Polychrome
  provenance-review entries against Polychrome 1.6.1.
* Adds deterministic build-time generation for package-owned palettes and
  frozen registry diagnostics for deutan, protan, and tritan simulations.
* Bundles exact 256-color viridisLite 0.4.3 and scico 1.5.0 lookup tables,
  preserving provider output without runtime palette-package dependencies.
* Adds a versioned Draft 2020-12 color-map schema and lossless JSON/CSV
  interchange for mappings, hierarchy, focus, provenance, aliases, locks,
  history, context, seeds, and JSON-native extension metadata. Legacy files
  are migrated, while unknown future schema versions are rejected.
* Makes hierarchy growth append-only: new parents and children receive colors
  without changing established child assignments or parent anchors, including
  after serialization and restoration.
* Reports biological labels and colors for worst palette pairs, retains exact
  duplicate collisions, avoids categorical-cardinality warnings for continuous
  palettes, and makes qualitative recommendation cutoffs explicitly opt-in.
* Adds cross-platform R CMD check (including the declared R 4.2 minimum),
  pinned-source verification and palette-database regeneration, informational
  coverage, and check-gated pkgdown deployment workflows.
* Removes unused framework and testing packages from `Suggests`.

# scChromatic 0.1.0

* Initial release with persistent color maps, hierarchy-aware mappings,
  qualitative and continuous scales, deterministic palette extension,
  accessibility diagnostics, and provenance metadata.
* Adds `sc_example`, a deterministic synthetic PBMC-like dataset demonstrating
  identity, lineage, sample, condition, expression, signed-score, pseudotime,
  and QC color semantics.
* Removes the ArchR-specific `pal_archr()` helper and unprefixed palette aliases.
* Adds `chromatic_balance`, a package-owned diverging HCL palette for signed
  scores centered at zero.
* Adds `d3_rainbow` and `d3_cool` as explicit CELLXGENE compatibility palettes.
  The cyclic rainbow reproduces count- and order-dependent categorical colors
  and is excluded from persistent `sc_color_map()` assignments; the cool scale
  includes CELLXGENE's exact 100 source bins and offers smooth continuous-scale
  compatibility in the same low-to-high direction.
