# Palette gallery

This gallery is generated from the package’s offline registry, so it
stays in sync with the colors returned by
[`sc_palette()`](https://xie186.github.io/scChromatic/reference/sc_palette.md).
Hover over a qualitative swatch to see its hexadecimal value. Status
groups put recommended starting points first while keeping compatibility
collections visible.

**19**registered palettes

**9**qualitative

**6**sequential

**3**diverging

**1**cyclic

## Recommended palettes

**`okabe_ito`**qualitative

khroma · 8 colors · recommended  
cell_identity · sample · condition · highlight

**`tol_bright`**qualitative

khroma · 7 colors · recommended  
cell_identity · sample · condition · highlight

**`tol_vibrant`**qualitative

khroma · 7 colors · recommended  
cell_identity · sample · condition · highlight

**`tol_muted`**qualitative

khroma · 9 colors · recommended  
cell_identity · sample · lineage · heatmap_annotation

**`tol_medium_contrast`**qualitative

khroma · 6 colors · recommended  
condition · sample · highlight

**`ditto40`**qualitative

dittoSeq · 40 colors · recommended  
cell_identity · sample · heatmap_annotation

**`chromatic`**qualitative

scChromatic · 40 colors · recommended  
cell_identity · sample · lineage · heatmap_annotation

**`chromatic_balance`**diverging

scChromatic · recommended  
signed_score

**`viridis`**sequential

viridisLite · recommended  
expression · pseudotime · qc

**`cividis`**sequential

viridisLite · recommended  
expression · pseudotime · qc

**`magma`**sequential

viridisLite · recommended  
expression · pseudotime · qc

These palettes are the primary framework-neutral starting points.
Qualitative palettes are fixed sequences; request `extend = "generate"`
only when more colors are needed.

## Compatibility collections

**`glasbey32`**qualitative

Polychrome · 32 colors · compatibility  
cell_identity · sample · heatmap_annotation

**`polychrome36`**qualitative

Polychrome · 36 colors · compatibility  
cell_identity · sample · heatmap_annotation

**`d3_rainbow`**cyclic

D3 Scale Chromatic · compatibility  
cell_identity · sample · condition · lineage · heatmap_annotation

**`d3_cool`**sequential

D3 Scale Chromatic · compatibility  
expression · pseudotime · qc

**`scico_batlow`**sequential

scico · compatibility  
expression · pseudotime · qc

**`scico_lajolla`**sequential

scico · compatibility  
expression · pseudotime · qc

**`scico_vik`**diverging

scico · compatibility  
signed_score

**`scico_broc`**diverging

scico · compatibility  
signed_score

Compatibility palettes preserve explicitly named external collections,
including licensed Polychrome and `scico_*` palettes, and the
`d3_rainbow` and `d3_cool` schemes used by CELLXGENE. `d3_rainbow`
reproduces CELLXGENE’s categorical fallback, but its colors depend on
both the requested count and category order. It is therefore a
visual-compatibility option, not a stable label-to-color contract, and
[`sc_color_map()`](https://xie186.github.io/scChromatic/reference/sc_color_map.md)
intentionally excludes it. Request it with `sc_palette("d3_rainbow", n)`
or a discrete `scale_*_sc_d()`.

`d3_cool` provides a smooth continuous gradient for visual
compatibility. Its exact 100 D3 source bins are available with
`sc_palette("d3_cool", 100, selection = "source")`. CELLXGENE assigns
points through those bins in reverse order, so the default priority
order and the R continuous scale run from low green to high purple; the
smooth R scale preserves the appearance rather than identical upstream
bin boundaries.

For signed values, pass the data midpoint to the scale so rescaling is
centered correctly:

``` r

scale_color_sc_c("chromatic_balance", midpoint = 0)
```

    ## <ScaleContinuous>
    ##  Range:  
    ##  Limits:    0 --    1

High-cardinality palettes are perceptually optimized or compatibility
collections, not guarantees of universal color-vision-deficiency safety.
Use
[`sc_palette_audit()`](https://xie186.github.io/scChromatic/reference/sc_palette_audit.md)
and combine color with labels, shapes, facets, or other encodings when
distinctions matter.
