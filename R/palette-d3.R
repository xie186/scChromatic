# D3-compatible Cubehelix formulas; see inst/NOTICE for BSD-3-Clause terms.
.sc_d3_cubehelix <- function(h, s, l) {
  angle <- (h + 120) * pi / 180
  amplitude <- s * l * (1 - l)
  cosine <- cos(angle)
  sine <- sin(angle)
  channels <- cbind(
    l + amplitude * (-0.14861 * cosine + 1.78277 * sine),
    l + amplitude * (-0.29227 * cosine - 0.90649 * sine),
    l + amplitude * (1.97294 * cosine)
  )
  channels[] <- pmax(0, pmin(255, floor(255 * channels + 0.5)))
  toupper(grDevices::rgb(
    channels[, 1L], channels[, 2L], channels[, 3L], maxColorValue = 255
  ))
}

.sc_d3_rainbow <- function(n) {
  t <- (seq_len(n) - 1) / n
  distance <- abs(t - 0.5)
  .sc_d3_cubehelix(
    h = 360 * t - 100,
    s = 1.5 - 1.5 * distance,
    l = 0.8 - 0.9 * distance
  )
}

.sc_d3_cool <- function(t) {
  .sc_d3_cubehelix(
    h = 260 - 180 * t,
    s = 0.75 + 0.75 * t,
    l = 0.35 + 0.45 * t
  )
}
