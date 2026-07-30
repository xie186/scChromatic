# Palette gallery

This gallery is generated from the package’s offline registry, so it
stays in sync with the colors returned by
[`sc_palette()`](https://xie186.github.io/scChromatic/reference/sc_palette.md).
Hover over a qualitative swatch to see its hexadecimal value.

**46**registered palettes

**23**qualitative

**18**sequential

**5**diverging

## Qualitative palettes

**`archr_stallion`**qualitative

ArchR · 20 colors · compatibility  
cell_identity · sample · condition · lineage · heatmap_annotation

**`archr_stallion2`**qualitative

ArchR · 19 colors · compatibility  
cell_identity · sample · condition · lineage · heatmap_annotation

**`archr_calm`**qualitative

ArchR · 20 colors · compatibility  
cell_identity · sample · condition · lineage · heatmap_annotation

**`archr_kelly`**qualitative

ArchR · 20 colors · compatibility  
cell_identity · sample · condition · lineage · heatmap_annotation

**`archr_bear`**qualitative

ArchR · 16 colors · compatibility  
cell_identity · sample · condition · lineage · heatmap_annotation

**`archr_iron_man`**qualitative

ArchR · 15 colors · compatibility  
cell_identity · sample · condition · lineage · heatmap_annotation

**`archr_circus`**qualitative

ArchR · 15 colors · compatibility  
cell_identity · sample · condition · lineage · heatmap_annotation

**`archr_paired`**qualitative

ArchR · 12 colors · compatibility  
cell_identity · sample · condition · lineage · heatmap_annotation

**`archr_grove`**qualitative

ArchR · 11 colors · compatibility  
cell_identity · sample · condition · lineage · heatmap_annotation

**`archr_summer_night`**qualitative

ArchR · 7 colors · compatibility  
cell_identity · sample · condition · lineage · heatmap_annotation

**`archr_zissou`**qualitative

ArchR · 5 colors · provenance_review  
cell_identity · sample · condition · lineage · heatmap_annotation

**`archr_darjeeling`**qualitative

ArchR · 5 colors · provenance_review  
cell_identity · sample · condition · lineage · heatmap_annotation

**`archr_rushmore`**qualitative

ArchR · 5 colors · provenance_review  
cell_identity · sample · condition · lineage · heatmap_annotation

**`archr_captain`**qualitative

ArchR · 5 colors · compatibility  
cell_identity · sample · condition · lineage · heatmap_annotation

**`okabe_ito`**qualitative

Okabe-Ito · 8 colors · recommended  
cell_identity · sample · condition · highlight

**`tol_bright`**qualitative

Paul Tol · 7 colors · recommended  
cell_identity · sample · condition · highlight

**`tol_vibrant`**qualitative

Paul Tol · 7 colors · recommended  
cell_identity · sample · condition · highlight

**`tol_muted`**qualitative

Paul Tol · 9 colors · recommended  
cell_identity · sample · lineage · heatmap_annotation

**`tol_medium_contrast`**qualitative

Paul Tol · 6 colors · recommended  
condition · sample · highlight

**`glasbey32`**qualitative

Glasbey et al. · 32 colors · provenance_review  
cell_identity · sample · heatmap_annotation

**`polychrome36`**qualitative

Polychrome · 36 colors · provenance_review  
cell_identity · sample · heatmap_annotation

**`ditto40`**qualitative

dittoSeq · 40 colors · recommended  
cell_identity · sample · heatmap_annotation

**`chromatic`**qualitative

scChromatic · 40 colors · recommended  
cell_identity · sample · lineage · heatmap_annotation

Qualitative palettes are fixed sequences. scChromatic does not
interpolate them by default; request `extend = "generate"` only when
more colors are needed.

## Sequential palettes

**`archr_horizon`**sequential

ArchR · compatibility  
expression · pseudotime · qc

**`archr_horizon_extra`**sequential

ArchR · compatibility  
expression · pseudotime · qc

**`archr_blue_yellow`**sequential

ArchR · compatibility  
expression · pseudotime · qc

**`archr_samba_night`**sequential

ArchR · provenance_review  
expression · pseudotime · qc

**`archr_solar_extra`**sequential

ArchR · provenance_review  
expression · pseudotime · qc

**`archr_white_purple`**sequential

ArchR · provenance_review  
expression · pseudotime · qc

**`archr_white_blue`**sequential

ArchR · provenance_review  
expression · pseudotime · qc

**`archr_white_red`**sequential

ArchR · compatibility  
expression · pseudotime · qc

**`archr_comet`**sequential

ArchR · compatibility  
expression · pseudotime · qc

**`archr_green_blue`**sequential

ArchR · provenance_review  
expression · pseudotime · qc

**`archr_beach`**sequential

ArchR · compatibility  
expression · pseudotime · qc

**`archr_grey_magma`**sequential

ArchR · compatibility  
expression · pseudotime · qc

**`archr_purple_orange`**sequential

ArchR · compatibility  
expression · pseudotime · qc

**`viridis`**sequential

viridisLite · recommended  
expression · pseudotime · qc

**`cividis`**sequential

viridisLite · recommended  
expression · pseudotime · qc

**`magma`**sequential

viridisLite · recommended  
expression · pseudotime · qc

**`scico_batlow`**sequential

scico · compatibility  
expression · pseudotime · qc

**`scico_lajolla`**sequential

scico · compatibility  
expression · pseudotime · qc

## Diverging palettes

**`archr_coolwarm`**diverging

ArchR · compatibility  
expression · pseudotime · qc

**`archr_fireworks`**diverging

ArchR · compatibility  
expression · pseudotime · qc

**`archr_fireworks2`**diverging

ArchR · compatibility  
expression · pseudotime · qc

**`scico_vik`**diverging

scico · compatibility  
signed_score

**`scico_broc`**diverging

scico · compatibility  
signed_score

For signed values, pass the data midpoint to the scale so rescaling is
centered correctly:

``` r

scale_color_sc_c("archr_coolwarm", midpoint = 0)
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
