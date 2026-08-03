# Provenance-tracked fixed palettes. Keep literal vectors frozen so releases
# are reproducible. See inst/NOTICE and palette-registry.csv.
core_palettes <- list(
  okabe_ito = c(
    orange = "#E69F00", sky_blue = "#56B4E9", bluish_green = "#009E73",
    yellow = "#F0E442", blue = "#0072B2", vermillion = "#D55E00",
    reddish_purple = "#CC79A7", black = "#000000"
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
    light_blue = "#6699CC", dark_blue = "#004488", light_yellow = "#EECC66",
    dark_red = "#994455", dark_yellow = "#997700", light_red = "#EE99AA"
  ),
  glasbey32 = c(
    "#0000FF", "#FF0000", "#00FF00", "#000033", "#FF00B6", "#005300",
    "#FFD300", "#009FFF", "#9A4D42", "#00FFBE", "#783FC1", "#1F9698",
    "#FFACFD", "#B1CC71", "#F1085C", "#FE8F42", "#DD00FF", "#201A01",
    "#720055", "#766C95", "#02AD24", "#C8FF00", "#886C00", "#FFB79F",
    "#858567", "#A10300", "#14F9FF", "#00479E", "#DC5E93", "#93D4FF",
    "#004CFF", "#F2F3F4"
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
  chromatic = c(
    "#475D8F", "#E3B54E", "#00DADF", "#765A11", "#009685", "#9C8CFB",
    "#D14D70", "#8C7D00", "#EA74A9", "#007C4D", "#7D73BD", "#A99C5D",
    "#89CA98", "#C69400", "#8F4667", "#00AFB3", "#98BAFF", "#B30089",
    "#5F4AC2", "#5A8849", "#A5679C", "#ECA7D1", "#C484D1", "#5AD27C",
    "#1D6C36", "#CE8795", "#68A977", "#A03F37", "#BE52B1", "#2A8C65",
    "#3E7ADB", "#FEA67F", "#D4BC00", "#3085A2", "#E4814A", "#B96637",
    "#006C7C", "#AE6876", "#00B86B", "#A019B0"
  ),
  chromatic_balance = c(
    "#0055A3", "#4674B0", "#7A94C0", "#A5B4D1", "#CDD4E2", "#F1F1F1",
    "#E4CFCF", "#D4A9AA", "#C28284", "#AC5A5D", "#942E34"
  ),
  viridis = stats::setNames(viridisLite::viridis(11), seq_len(11)),
  cividis = stats::setNames(viridisLite::cividis(11), seq_len(11)),
  magma = stats::setNames(viridisLite::magma(11), seq_len(11))
)
