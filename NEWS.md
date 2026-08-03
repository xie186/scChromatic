# scChromatic 0.1.0

* Initial release with persistent color maps, hierarchy-aware mappings,
  qualitative and continuous scales, deterministic palette extension,
  accessibility diagnostics, and provenance metadata.
* Includes palettes frozen from ArchR commit
  `6feec354ad6c8052ddbc4626a2ca2d858ed465bf`.
* Adds `sc_example`, a deterministic synthetic PBMC-like dataset demonstrating
  identity, lineage, sample, condition, expression, signed-score, pseudotime,
  and QC color semantics.
* Reframes ArchR-derived palettes as an explicitly named compatibility
  collection, removes unresolved ArchR provenance entries, and prioritizes
  framework-neutral palettes throughout the API documentation and website.
* Removes the ArchR-specific `pal_archr()` helper and unprefixed palette aliases;
  retained compatibility colors remain available through explicit `archr_*` IDs.
* Adds `chromatic_balance`, a package-owned diverging HCL palette for signed
  scores centered at zero.
