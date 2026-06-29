## Lightweight region-map asset writer.
##
## The GeoJSONs are display assets for mfclshiny/report export. They are not
## MFCL inputs and should stay small enough to ship with Kflow artifacts.

bet_region_map_default_vertices <- function() {
  data.frame(
    region = c(rep(1L, 8), rep(2L, 5), rep(3L, 5), rep(4L, 5), rep(5L, 5)),
    region_label = c(
      rep("Region 1", 8),
      rep("Region 2", 5),
      rep("Region 3", 5),
      rep("Region 4", 5),
      rep("Region 5", 5)
    ),
    lon = c(
      120, 120, 210, 210, 185, 140, 140, 120,
      110, 110, 140, 140, 110,
      140, 140, 185, 185, 140,
      185, 185, 210, 210, 185,
      140, 140, 210, 210, 140
    ),
    lat = c(
      20, 50, 50, 10, 10, 10, 20, 20,
      -10, 20, 20, -10, -10,
      -10, 10, 10, -10, -10,
      -10, 10, 10, -10, -10,
      -40, -10, -10, -40, -40
    ),
    vertex = c(seq_len(8), seq_len(5), seq_len(5), seq_len(5), seq_len(5)),
    stringsAsFactors = FALSE
  )
}

bet_nine_region_map_default_vertices <- function() {
  # Display-only 2023 BET 9-region diagnostic map used by 01/02.
  # Vertices are the exterior boundaries of the 2023 MufArea rectangles from
  # the size-composition input repository.
  make_region <- function(region, label, lon, lat) {
    data.frame(
      region = as.integer(region),
      region_label = label,
      lon = lon,
      lat = lat,
      vertex = seq_along(lon),
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, list(
    make_region(1L, "Region 1", c(170, 170, 120, 120, 140, 140), c(10, 50, 50, 20, 20, 10)),
    make_region(2L, "Region 2", c(210, 170, 170, 210), c(50, 50, 10, 10)),
    make_region(3L, "Region 3", c(170, 170, 140, 140, 155, 155, 160, 160), c(-10, 10, 10, 0, 0, -5, -5, -10)),
    make_region(4L, "Region 4", c(210, 170, 170, 210), c(10, 10, -10, -10)),
    make_region(5L, "Region 5", c(170, 140, 140, 150, 150, 140, 140, 170), c(-10, -10, -15, -15, -20, -20, -40, -40)),
    make_region(6L, "Region 6", c(210, 170, 170, 210), c(-10, -10, -40, -40)),
    make_region(7L, "Region 7", c(110, 110, 140, 140), c(20, -10, -10, 20)),
    make_region(8L, "Region 8", c(160, 155, 155, 140, 140, 160), c(-5, -5, 0, 0, -10, -10)),
    make_region(9L, "Region 9", c(150, 140, 140, 150), c(-15, -15, -20, -20))
  ))
}

bet_region_map_normalize_vertices <- function(vertices) {
  vertices <- as.data.frame(vertices, stringsAsFactors = FALSE)
  names(vertices) <- tolower(trimws(names(vertices)))
  required <- c("region", "region_label", "lon", "lat", "vertex")
  missing <- setdiff(required, names(vertices))
  if (length(missing)) {
    stop("Region map vertices missing column(s): ", paste(missing, collapse = ", "), call. = FALSE)
  }
  vertices$region <- as.integer(vertices$region)
  vertices$region_label <- as.character(vertices$region_label)
  vertices$lon <- as.numeric(vertices$lon)
  vertices$lat <- as.numeric(vertices$lat)
  vertices$vertex <- as.integer(vertices$vertex)
  vertices <- vertices[is.finite(vertices$region) & is.finite(vertices$lon) & is.finite(vertices$lat), , drop = FALSE]
  vertices$lon <- ifelse(vertices$lon < 0, vertices$lon + 360, vertices$lon)
  vertices <- vertices[order(vertices$region, vertices$vertex), , drop = FALSE]
  rownames(vertices) <- NULL
  vertices
}

bet_region_map_close_polygons <- function(vertices) {
  vertices <- bet_region_map_normalize_vertices(vertices)
  out <- lapply(split(vertices, vertices$region, drop = TRUE), function(x) {
    first <- x[1L, , drop = FALSE]
    first$vertex <- max(x$vertex, na.rm = TRUE) + 1L
    rbind(x, first)
  })
  do.call(rbind, out)
}

bet_region_map_label_from_stem <- function(stem = "") {
  if (is.null(stem) || !length(stem)) stem <- ""
  stem <- trimws(as.character(stem[[1L]]))
  if (!nzchar(stem)) return("Region map")
  stem <- gsub("[._-]+", " ", stem)
  words <- strsplit(stem, "[[:space:]]+")[[1L]]
  words <- vapply(words, function(word) {
    if (grepl("^[[:upper:][:digit:]]+$", word)) return(word)
    paste0(toupper(substr(word, 1L, 1L)), tolower(substr(word, 2L, nchar(word))))
  }, character(1))
  paste(words, collapse = " ")
}

bet_region_map_to_geojson <- function(vertices = bet_region_map_default_vertices(),
                                      map_label = "Region map") {
  # Hand-build this small FeatureCollection so `sf` is optional.
  if (is.null(map_label) || !length(map_label)) map_label <- ""
  map_label <- trimws(as.character(map_label[[1L]]))
  vertices <- bet_region_map_normalize_vertices(vertices)
  features <- lapply(split(vertices, vertices$region), function(x) {
    closed <- bet_region_map_close_polygons(x)
    coords <- lapply(seq_len(nrow(closed)), function(i) unname(c(closed$lon[[i]], closed$lat[[i]])))
    list(
      type = "Feature",
      properties = list(region = as.integer(x$region[[1L]]), region_label = x$region_label[[1L]]),
      geometry = list(type = "Polygon", coordinates = list(coords))
    )
  })
  geojson <- list(type = "FeatureCollection", features = unname(features))
  if (nzchar(map_label)) geojson$name <- map_label
  jsonlite::toJSON(
    geojson,
    auto_unbox = TRUE,
    pretty = TRUE,
    digits = 10
  )
}

bet_region_map_to_sf <- function(vertices = bet_region_map_default_vertices()) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("The sf package is required to build an sf region map object.", call. = FALSE)
  }
  vertices <- bet_region_map_normalize_vertices(vertices)
  attrs <- unique(vertices[, c("region", "region_label"), drop = FALSE])
  attrs <- attrs[order(attrs$region), , drop = FALSE]
  geometries <- lapply(split(vertices, vertices$region, drop = TRUE), function(x) {
    closed <- bet_region_map_close_polygons(x)
    sf::st_polygon(list(as.matrix(closed[, c("lon", "lat"), drop = FALSE])))
  })
  sf::st_sf(
    region = attrs$region,
    region_label = attrs$region_label,
    geometry = sf::st_sfc(geometries, crs = 4326)
  )
}

bet_region_map_lon_label <- function(x) {
  x <- ifelse(x > 180, x - 360, x)
  ifelse(x < 0, paste0(abs(x), "W"), paste0(x, "E"))
}

bet_region_map_lat_label <- function(x) {
  ifelse(x < 0, paste0(abs(x), "S"), ifelse(x > 0, paste0(x, "N"), "0"))
}

bet_region_map_vertex_label <- function(lon, lat) {
  paste(bet_region_map_lon_label(lon), bet_region_map_lat_label(lat), sep = "\n")
}

bet_region_map_coordinate_labels <- function(vertices) {
  labels <- unique(vertices[, c("lon", "lat"), drop = FALSE])
  labels$label <- bet_region_map_vertex_label(labels$lon, labels$lat)
  labels$hjust <- ifelse(
    labels$lon <= 112, 1.12,
    ifelse(labels$lon == 120 & labels$lat == 20, -0.12, ifelse(labels$lon >= 208, 1.08, 0.5))
  )
  labels$vjust <- ifelse(labels$lat >= 45, 1.18, ifelse(labels$lat <= -35, -0.2, ifelse(labels$lat >= 0, -0.42, 1.18)))
  labels
}

bet_region_map_region_label_positions <- function(vertices) {
  vertices <- bet_region_map_normalize_vertices(vertices)
  regions <- sort(unique(vertices$region))
  if (identical(regions, 1:9)) {
    return(data.frame(
      region = 1:9,
      lon = c(152, 188, 156, 188, 158, 188, 126, 147, 147),
      lat = c(30, 32, 1, 1, -30, -30, 6, -2, -18),
      label = as.character(1:9)
    ))
  }
  if (identical(regions, 1:5)) {
    return(data.frame(
      region = 1:5,
      lon = c(166, 124, 162, 197, 176),
      lat = c(27, 5, 0, 0, -25),
      label = as.character(1:5)
    ))
  }
  rows <- lapply(split(vertices, vertices$region), function(x) {
    region <- as.integer(x$region[[1L]])
    data.frame(region = region, lon = mean(x$lon), lat = mean(x$lat), label = as.character(region))
  })
  do.call(rbind, rows)
}

bet_region_map_world_data <- function() {
  if (!requireNamespace("maps", quietly = TRUE) || !requireNamespace("ggplot2", quietly = TRUE)) {
    return(data.frame(long = numeric(), lat = numeric(), group = character()))
  }
  world <- tryCatch(ggplot2::map_data("world2"), error = function(e) data.frame())
  if (!nrow(world)) return(world)
  world
}

bet_region_map_plot <- function(vertices = bet_region_map_default_vertices()) {
  # Preview plots are useful for auditing boundaries, but optional.
  if (!requireNamespace("ggplot2", quietly = TRUE)) return(NULL)
  vertices <- bet_region_map_normalize_vertices(vertices)
  closed <- bet_region_map_close_polygons(vertices)
  closed$region_factor <- factor(closed$region, levels = sort(unique(closed$region)))
  vertices$region_factor <- factor(vertices$region, levels = sort(unique(vertices$region)))
  labels <- bet_region_map_region_label_positions(vertices)
  coord_labels <- bet_region_map_coordinate_labels(vertices)
  world <- bet_region_map_world_data()

  plot <- ggplot2::ggplot()
  if (nrow(world)) {
    plot <- plot +
      ggplot2::geom_polygon(
        data = world,
        ggplot2::aes(.data$long, .data$lat, group = .data$group),
        fill = "#e7ddc6",
        colour = "#c8c0ac",
        linewidth = 0.2
      )
  }
  plot +
    ggplot2::geom_polygon(
      data = closed,
      ggplot2::aes(.data$lon, .data$lat, group = .data$region_factor, fill = .data$region_factor),
      alpha = 0.20,
      colour = "#102b38",
      linewidth = 0.72
    ) +
    ggplot2::geom_path(
      data = closed,
      ggplot2::aes(.data$lon, .data$lat, group = .data$region_factor),
      colour = "#102b38",
      linewidth = 0.92,
      linejoin = "mitre"
    ) +
    ggplot2::geom_point(
      data = vertices,
      ggplot2::aes(.data$lon, .data$lat),
      size = 2.1,
      colour = "#8b1f28",
      fill = "#c62830",
      shape = 21,
      stroke = 0.45
    ) +
    ggplot2::geom_label(
      data = coord_labels,
      ggplot2::aes(.data$lon, .data$lat, label = .data$label, hjust = .data$hjust, vjust = .data$vjust),
      size = 3.8,
      fontface = "bold",
      linewidth = 0.18,
      label.padding = grid::unit(1.6, "pt"),
      label.r = grid::unit(2.2, "pt"),
      fill = "#fffdf7",
      colour = "#8a2730",
      alpha = 0.95
    ) +
    ggplot2::geom_text(
      data = labels,
      ggplot2::aes(.data$lon, .data$lat, label = .data$label),
      size = 6.3,
      fontface = "bold",
      colour = "#0e1720"
    ) +
    ggplot2::coord_quickmap(xlim = c(100, 215), ylim = c(-45, 55), expand = FALSE) +
    ggplot2::scale_x_continuous(
      breaks = c(110, 120, 140, 160, 180, 200, 210),
      labels = bet_region_map_lon_label
    ) +
    ggplot2::scale_y_continuous(
      breaks = c(-40, -20, 0, 20, 40, 50),
      labels = bet_region_map_lat_label
    ) +
    ggplot2::scale_fill_manual(values = rep(c("#dceff8", "#e6f2df", "#f6efd8", "#f7e3dc", "#e8e8f6"), 2), guide = "none") +
    ggplot2::labs(
      title = NULL,
      subtitle = NULL,
      x = NULL,
      y = NULL
    ) +
    ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = "#f5fbfe", colour = "#9aa9b2", linewidth = 0.35),
      panel.grid.major = ggplot2::element_line(colour = "#d6e4eb", linewidth = 0.32),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text = ggplot2::element_text(size = 11.4, colour = "#334155"),
      plot.title = ggplot2::element_blank(),
      plot.subtitle = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(8, 12, 8, 12)
    )
}

write_bet_region_map_assets <- function(output_dir,
                                        stem = "bet-2026-five-region",
                                        vertices = bet_region_map_default_vertices(),
                                        make_plot = TRUE,
                                        map_label = bet_region_map_label_from_stem(stem)) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  vertices <- bet_region_map_normalize_vertices(vertices)
  files <- c(geojson = file.path(output_dir, paste0(stem, ".geojson")))
  writeLines(as.character(bet_region_map_to_geojson(vertices, map_label = map_label)), files[["geojson"]])
  invisible(files)
}

write_bet_nine_region_map_assets <- function(output_dir,
                                             stem = "bet-2023-nine-region",
                                             vertices = bet_nine_region_map_default_vertices(),
                                             make_plot = TRUE,
                                             map_label = bet_region_map_label_from_stem(stem)) {
  write_bet_region_map_assets(
    output_dir = output_dir,
    stem = stem,
    vertices = vertices,
    make_plot = make_plot,
    map_label = map_label
  )
}

detect_frq_region_count <- function(frq_file) {
  if (!file.exists(frq_file)) return(NA_integer_)
  lines <- trimws(readLines(frq_file, warn = FALSE))
  lines <- lines[nzchar(lines) & !startsWith(lines, "#")]
  if (!length(lines)) return(NA_integer_)
  tokens <- strsplit(lines[[1L]], "[[:space:]]+")[[1L]]
  out <- suppressWarnings(as.integer(tokens[[1L]]))
  if (is.na(out)) NA_integer_ else out
}
