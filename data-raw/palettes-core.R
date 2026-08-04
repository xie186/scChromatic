# Provenance-tracked palettes. Third-party vectors are exact transcriptions of
# the pinned sources recorded in inst/NOTICE. Package-owned vectors are rebuilt
# deterministically by generate-owned-palettes.R.
core_palettes <- list(
  okabe_ito = c(
    black = "#000000", orange = "#E69F00", sky_blue = "#56B4E9",
    bluish_green = "#009E73",
    yellow = "#F0E442", blue = "#0072B2", vermillion = "#D55E00",
    reddish_purple = "#CC79A7"
  ),
  tol_bright = c(
    blue = "#4477AA", red = "#EE6677", green = "#228833", yellow = "#CCBB44",
    cyan = "#66CCEE", purple = "#AA3377", grey = "#BBBBBB"
  ),
  tol_vibrant = c(
    orange = "#EE7733", blue = "#0077BB", cyan = "#33BBEE", magenta = "#EE3377",
    red = "#CC3311", teal = "#009988", grey = "#BBBBBB"
  ),
  tol_muted = c(
    rose = "#CC6677", indigo = "#332288", sand = "#DDCC77", green = "#117733",
    cyan = "#88CCEE", wine = "#882255", teal = "#44AA99", olive = "#999933",
    purple = "#AA4499"
  ),
  tol_medium_contrast = c(
    light_yellow = "#EECC66", light_red = "#EE99AA", light_blue = "#6699CC",
    dark_yellow = "#997700", dark_red = "#994455", dark_blue = "#004488"
  ),
  glasbey32 = c(
    "#FFFFFF", "#0000FF", "#FF0000", "#00FF00", "#000033", "#FF00B6",
    "#005300", "#FFD300", "#009FFF", "#9A4D42", "#00FFBE", "#783FC1",
    "#1F9698", "#FFACFD", "#B1CC71", "#F1085C", "#FE8F42", "#DD00FF",
    "#201A01", "#720055", "#766C95", "#02AD24", "#C8FF00", "#886C00",
    "#FFB79F", "#858567", "#A10300", "#14F9FF", "#00479E", "#DC5E93",
    "#93D4FF", "#004CFF"
  ),
  polychrome36 = c(
    "#5A5156", "#E4E1E3", "#F6222E", "#FE00FA", "#16FF32", "#3283FE",
    "#FEAF16", "#B00068", "#1CFFCE", "#90AD1C", "#2ED9FF", "#DEA0FD",
    "#AA0DFE", "#F8A19F", "#325A9B", "#C4451C", "#1C8356", "#85660D",
    "#B10DA1", "#FBE426", "#1CBE4F", "#FA0087", "#FC1CBF", "#F7E1A0",
    "#C075A6", "#782AB6", "#AAF400", "#BDCDFF", "#822E1C", "#B5EFB5",
    "#7ED7D1", "#1C7F93", "#D85FF7", "#683B79", "#66B0FF", "#3B00FB"
  ),
  ditto40 = c(
    "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00",
    "#CC79A7", "#666666", "#AD7700", "#1C91D4", "#007756", "#D5C711",
    "#005685", "#A04700", "#B14380", "#4D4D4D", "#FFBE2D", "#80C7EF",
    "#00F6B3", "#F4EB71", "#06A5FF", "#FF8320", "#D99BBD", "#8C8C8C",
    "#FFCB57", "#9AD2F2", "#2CFFC6", "#F6EF8E", "#38B7FF", "#FF9B4D",
    "#E0AFCA", "#A3A3A3", "#8A5F00", "#1674A9", "#005F45", "#AA9F0D",
    "#00446B", "#803800", "#8D3666", "#3D3D3D"
  ),
  chromatic = scchromatic_owned_palettes$chromatic,
  chromatic_balance = scchromatic_owned_palettes$chromatic_balance,
  d3_rainbow = .sc_d3_rainbow(200L),
  d3_cool = .sc_d3_cool((0:99) / 100),
  viridis = viridisLite::viridis(256L),
  cividis = viridisLite::cividis(256L),
  magma = viridisLite::magma(256L),
  scico_batlow = scico::scico(256L, palette = "batlow"),
  scico_lajolla = scico::scico(256L, palette = "lajolla"),
  scico_vik = scico::scico(256L, palette = "vik"),
  scico_broc = scico::scico(256L, palette = "broc")
)

viridis_lut <- function(option) {
  map <- viridisLite::viridis.map[viridisLite::viridis.map$opt == option, ]
  grDevices::rgb(map$R, map$G, map$B)
}

scico_lut <- function(palette) {
  map <- scico::scico_palette_data(palette)
  grDevices::rgb(map$r, map$g, map$b)
}

provider_interpolation_luts <- list(
  viridis = viridis_lut("D"),
  cividis = viridis_lut("E"),
  magma = viridis_lut("A"),
  scico_batlow = scico_lut("batlow"),
  scico_lajolla = scico_lut("lajolla"),
  scico_vik = scico_lut("vik"),
  scico_broc = scico_lut("broc")
)
