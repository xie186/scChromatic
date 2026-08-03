archr_expected <- list(
  archr_stallion = c(
    "#D51F26", "#272E6A", "#208A42", "#89288F", "#F47D2B", "#FEE500",
    "#8A9FD1", "#C06CAB", "#E6C2DC", "#90D5E4", "#89C75F", "#F37B7D",
    "#9983BD", "#D24B27", "#3BBCA8", "#6E4B9E", "#0C727C", "#7E1416",
    "#D8A767", "#3D3D3D"
  ),
  archr_stallion2 = c(
    "#D51F26", "#272E6A", "#208A42", "#89288F", "#F47D2B", "#FEE500",
    "#8A9FD1", "#C06CAB", "#E6C2DC", "#90D5E4", "#89C75F", "#F37B7D",
    "#9983BD", "#D24B27", "#3BBCA8", "#6E4B9E", "#0C727C", "#7E1416",
    "#D8A767"
  ),
  archr_calm = c(
    "#7DD06F", "#844081", "#688EC1", "#C17E73", "#484125", "#6CD3A7",
    "#597873", "#7B6FD0", "#CF4A31", "#D0CD47", "#722A2D", "#CBC594",
    "#D19EC4", "#5A7E36", "#D4477D", "#403552", "#76D73C", "#96CED5",
    "#CE54D1", "#C48736"
  ),
  archr_kelly = c(
    "#FFB300", "#803E75", "#FF6800", "#A6BDD7", "#C10020", "#CEA262",
    "#817066", "#007D34", "#F6768E", "#00538A", "#FF7A5C", "#53377A",
    "#FF8E00", "#B32851", "#F4C800", "#7F180D", "#93AA00", "#593315",
    "#F13A13", "#232C16"
  ),
  archr_bear = c(
    "#FAA818", "#41A30D", "#FBDF72", "#367D7D", "#D33502", "#6EBCBC",
    "#37526D", "#916848", "#F5B390", "#342739", "#BED678", "#A6D9EE",
    "#0D74B6", "#60824F", "#725CA5", "#E0598B"
  ),
  archr_iron_man = c(
    "#371377", "#7700FF", "#9E0142", "#FF0080", "#DC494C", "#F88D51",
    "#FAD510", "#FFFF5F", "#88CFA4", "#238B45", "#02401B", "#0AD7D3",
    "#046C9A", "#A2A475", "#595959"
  ),
  archr_circus = c(
    "#D52126", "#88CCEE", "#FEE52C", "#117733", "#CC61B0", "#99C945",
    "#2F8AC4", "#332288", "#E68316", "#661101", "#F97B72", "#DDCC77",
    "#11A579", "#89288F", "#E73F74"
  ),
  archr_paired = c(
    "#A6CDE2", "#1E78B4", "#74C476", "#34A047", "#F59899", "#E11E26",
    "#FCBF6E", "#F47E1F", "#CAB2D6", "#6A3E98", "#FAF39B", "#B15928"
  ),
  archr_grove = c(
    "#1A1334", "#01545A", "#017351", "#03C383", "#AAD962", "#FBBF45",
    "#EF6A32", "#ED0345", "#A12A5E", "#710162", "#3B9AB2"
  ),
  archr_summer_night = c(
    "#2A7185", "#A64027", "#FBDF72", "#60824F", "#9CDFF0", "#022336",
    "#725CA5"
  ),
  archr_captain = c("#BEBEBE", "#A1CDE1", "#12477C", "#EC9274", "#67001E"),
  archr_horizon = c(
    "#000075", "#2E00FF", "#9408F7", "#C729D6", "#FA4AB5", "#FF6A95",
    "#FF8B74", "#FFAC53", "#FFCD32", "#FFFF60"
  ),
  archr_horizon_extra = c(
    "#000436", "#021EA9", "#1632FB", "#6E34FC", "#C732D5", "#FD619D",
    "#FF9965", "#FFD32B", "#FFFC5A"
  ),
  archr_blue_yellow = c(
    "#352A86", "#343DAE", "#0262E0", "#1389D2", "#2DB7A3", "#A5BE6A",
    "#F8BA43", "#F6DA23", "#F8FA0D"
  ),
  archr_white_red = c("#FFFFFF", "#FF0000"),
  archr_comet = c("#E6E7E8", "#3A97FF", "#8816A7", "#000000"),
  archr_beach = c("#87D2DB", "#5BB1CB", "#4F66AF", "#F15F30", "#F7962E", "#FCEE2B"),
  archr_coolwarm = c("#4858A7", "#788FC8", "#D6DAE1", "#F49B7C", "#B51F29"),
  archr_fireworks = c("#FFFFFF", "#2488F0", "#7F3F98", "#E22929", "#FCB31A"),
  archr_grey_magma = c("#BEBEBE", "#FB8861", "#B63679", "#51127C", "#000004"),
  archr_fireworks2 = c("#000000", "#2488F0", "#7F3F98", "#E22929", "#FCB31A"),
  archr_purple_orange = c("#581845", "#900C3F", "#C70039", "#FF5744", "#FFC30F")
)

test_that("all ArchR source vectors match the frozen commit", {
  db <- get("sc_palette_db", envir = asNamespace("scChromatic"))
  expect_setequal(
    names(archr_expected),
    sc_palette_names(source = "ArchR")
  )
  for (id in names(archr_expected)) {
    expect_identical(
      unname(db$colors[[id]]$source),
      archr_expected[[id]],
      info = id
    )
  }
})

test_that("ArchR compatibility palettes require explicit IDs", {
  expect_identical(
    sc_pal("archr_stallion", selection = "source")(8),
    sc_palette("archr_stallion", 8, selection = "source")
  )
  expect_error(sc_palette("stallion", 8), "Unknown palette")
  expect_error(sc_palette("coolwarm", 8), "Unknown palette")
})

test_that("continuous ArchR priority order preserves the source gradient", {
  db <- get("sc_palette_db", envir = asNamespace("scChromatic"))
  ids <- sc_palette_names(source = "ArchR")
  ids <- ids[vapply(ids, function(id) {
    sc_palette_info(id)$palette_type != "qualitative"
  }, logical(1))]
  for (id in ids) {
    expect_identical(db$colors[[id]]$priority, db$colors[[id]]$source, info = id)
  }
})
