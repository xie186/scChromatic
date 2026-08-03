# scChromatic

``` r

library(scChromatic)
library(ggplot2)
data(sc_example)
```

## Palette discovery

The registry separates palette type, intended use, provenance, capacity,
and status.

``` r

head(sc_palette_names(type = "qualitative"))
```

    ## [1] "okabe_ito"           "tol_bright"          "tol_vibrant"        
    ## [4] "tol_muted"           "tol_medium_contrast" "glasbey32"

``` r

sc_palette_info("chromatic")
```

    ##   palette_id      source source_palette palette_type max_n
    ## 9  chromatic scChromatic      chromatic  qualitative    40
    ##                                      intended_use recommended_geometry
    ## 9 cell_identity,sample,lineage,heatmap_annotation      point,fill,line
    ##   recommended_background      status
    ## 9             light,dark recommended
    ##                                        source_order
    ## 9 literal vector order in internal palette database
    ##                                       priority_order
    ## 9 frozen nested maximin order; each prefix is stable
    ##                              source_url source_commit
    ## 9 https://github.com/xie186/scChromatic          <NA>
    ##                      citation    license derived
    ## 9 scChromatic package authors GPL (>= 3)    TRUE
    ##                                                     source_cvd_claim
    ## 9 Perceptually optimized and audited; no universal CVD-safety claim.
    ##                                                                          notes
    ## 9 Frozen nested maximin sequence generated in HCL with normal/CVD diagnostics.
    ##   audit_min_cie2000 audit_min_contrast_light audit_min_contrast_dark audit_date
    ## 9           6.44697                 1.736383                2.677194 2026-07-30

``` r

sc_palette_recommend(12, use = "cell_identity")
```

    ##                                                 palette_id
    ## cell_identity,sample,lineage,heatmap_annotation  chromatic
    ## cell_identity,sample,heatmap_annotation            ditto40
    ##                                                                                                                       reason
    ## cell_identity,sample,lineage,heatmap_annotation qualitative; registered for this use; recommended; sufficient fixed capacity
    ## cell_identity,sample,heatmap_annotation         qualitative; registered for this use; recommended; sufficient fixed capacity
    ##                                                 capacity      status
    ## cell_identity,sample,lineage,heatmap_annotation       40 recommended
    ## cell_identity,sample,heatmap_annotation               40 recommended
    ##                                                 min_cie2000    score
    ## cell_identity,sample,lineage,heatmap_annotation   10.877739 81.87774
    ## cell_identity,sample,heatmap_annotation            2.000239 73.00024

Raw colors are available as vectors, while
[`sc_pal()`](https://xie186.github.io/scChromatic/reference/sc_pal.md)
returns a scales-compatible closure.

``` r

sc_palette("chromatic", 6)
```

    ## [1] "#475D8F" "#E3B54E" "#00DADF" "#765A11" "#009685" "#9C8CFB"

``` r

sc_pal("chromatic")(6)
```

    ## [1] "#475D8F" "#E3B54E" "#00DADF" "#765A11" "#009685" "#9C8CFB"

## Example single-cell dataset

`sc_example` is deterministic and synthetic. Its columns represent the
color semantics commonly encountered in single-cell figures.

``` r

dim(sc_example)
```

    ## [1] 720  12

``` r

head(sc_example)
```

    ##     cell_id     UMAP1    UMAP2 cell_type  lineage   sample  condition MS4A1
    ## 1 cell_0001 -3.163181 1.418680    B cell Lymphoid Sample 1    Control 3.850
    ## 2 cell_0002 -3.086307 1.324727    B cell Lymphoid Sample 2    Control 3.899
    ## 3 cell_0003 -2.846043 1.502208    B cell Lymphoid Sample 3 Stimulated 4.145
    ## 4 cell_0004 -2.992542 1.337283    B cell Lymphoid Sample 4 Stimulated 4.189
    ## 5 cell_0005 -2.976398 1.365888    B cell Lymphoid Sample 1    Control 4.029
    ## 6 cell_0006 -3.212464 1.536336    B cell Lymphoid Sample 2    Control 4.065
    ##   signed_score pseudotime percent_mito n_counts
    ## 1       -0.494      0.000         8.66     2279
    ## 2       -0.473      0.007         8.78     2257
    ## 3        1.341      0.013         8.87     2483
    ## 4        1.349      0.020        10.44     2460
    ## 5       -0.451      0.027         8.98     2185
    ## 6       -0.457      0.034         9.00     2160

## Persistent cell identities

``` r

cell_map <- sc_color_map(sc_example$cell_type, palette = "chromatic")

ggplot(sc_example, aes(UMAP1, UMAP2, color = cell_type)) +
  geom_point(size = 0.5) +
  scale_color_sc_map(cell_map)
```

![](scChromatic_files/figure-html/unnamed-chunk-4-1.png)

The same map is reused after filtering, so the three retained identities
keep their original colors.

``` r

stimulated <- subset(
  sc_example,
  condition == "Stimulated" & cell_type %in% c("CD4 T", "NK", "Monocyte")
)

ggplot(stimulated, aes(UMAP1, UMAP2, color = cell_type)) +
  geom_point(size = 0.7) +
  scale_color_sc_map(cell_map)
```

![](scChromatic_files/figure-html/unnamed-chunk-5-1.png)

## Samples and conditions

``` r

sample_map <- sc_color_map(sc_example$sample, palette = "chromatic")

ggplot(sc_example, aes(UMAP1, UMAP2, color = sample)) +
  geom_point(size = 0.5) +
  scale_color_sc_map(sample_map)
```

![](scChromatic_files/figure-html/unnamed-chunk-6-1.png)

``` r

ggplot(sc_example, aes(UMAP1, UMAP2, color = condition)) +
  geom_point(size = 0.5) +
  scale_color_sc_d("chromatic")
```

![](scChromatic_files/figure-html/unnamed-chunk-6-2.png)

## Continuous expression

``` r

ggplot(sc_example, aes(UMAP1, UMAP2, color = MS4A1)) +
  geom_point(size = 0.5) +
  scale_color_sc_c("viridis")
```

![](scChromatic_files/figure-html/unnamed-chunk-7-1.png)

## Signed scores centered at zero

`midpoint = 0` changes data rescaling, not merely the middle displayed
color.

``` r

ggplot(sc_example, aes(UMAP1, UMAP2, color = signed_score)) +
  geom_point(size = 0.5) +
  scale_color_sc_c("chromatic_balance", midpoint = 0)
```

![](scChromatic_files/figure-html/unnamed-chunk-8-1.png)

## Parent lineage and child subtype colors

``` r

lineage_map <- sc_hierarchy_map(sc_example$lineage, sc_example$cell_type)

ggplot(sc_example, aes(UMAP1, UMAP2, color = cell_type)) +
  geom_point(size = 0.5) +
  scale_color_sc_map(lineage_map)
```

![](scChromatic_files/figure-html/unnamed-chunk-9-1.png)

## Pseudotime and QC

``` r

ggplot(sc_example, aes(UMAP1, UMAP2, color = pseudotime)) +
  geom_point(size = 0.5) +
  scale_color_sc_c("cividis")
```

![](scChromatic_files/figure-html/unnamed-chunk-10-1.png)

``` r

ggplot(sc_example, aes(UMAP1, UMAP2, color = percent_mito)) +
  geom_point(size = 0.5) +
  scale_color_sc_c("viridis")
```

![](scChromatic_files/figure-html/unnamed-chunk-10-2.png)
