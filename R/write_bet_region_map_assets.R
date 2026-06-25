bet_region_map_default_vertices <- function() {
  data.frame(
    region = c(rep(1L, 7), rep(2L, 5), rep(3L, 5), rep(4L, 5), rep(5L, 5)),
    region_label = c(
      rep("Region 1", 7),
      rep("Region 2", 5),
      rep("Region 3", 5),
      rep("Region 4", 5),
      rep("Region 5", 5)
    ),
    lon = c(
      120, 120, 210, 210, 185, 185, 140,
      110, 110, 140, 140, 110,
      140, 140, 185, 185, 140,
      185, 185, 210, 210, 185,
      140, 140, 210, 210, 140
    ),
    lat = c(
      20, 50, 50, 10, 10, -10, -10,
      -10, 20, 20, -10, -10,
      -10, 10, 10, -10, -10,
      -10, 10, 10, -10, -10,
      -40, -10, -10, -40, -40
    ),
    vertex = c(seq_len(7), seq_len(5), seq_len(5), seq_len(5), seq_len(5)),
    stringsAsFactors = FALSE
  )
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

bet_region_map_to_geojson <- function(vertices = bet_region_map_default_vertices()) {
  vertices <- bet_region_map_normalize_vertices(vertices)
  features <- lapply(split(vertices, vertices$region), function(x) {
    closed <- bet_region_map_close_polygons(x)
    coords <- lapply(seq_len(nrow(closed)), function(i) list(unname(c(closed$lon[[i]], closed$lat[[i]]))))
    list(
      type = "Feature",
      properties = list(region = as.integer(x$region[[1L]]), region_label = x$region_label[[1L]]),
      geometry = list(type = "Polygon", coordinates = list(coords))
    )
  })
  jsonlite::toJSON(
    list(type = "FeatureCollection", features = unname(features)),
    auto_unbox = TRUE,
    pretty = TRUE,
    digits = 10
  )
}

bet_region_map_lon_label <- function(x) {
  x <- ifelse(x > 180, x - 360, x)
  ifelse(x < 0, paste0(abs(x), "W"), paste0(x, "E"))
}

bet_region_map_lat_label <- function(x) {
  ifelse(x < 0, paste0(abs(x), "S"), ifelse(x > 0, paste0(x, "N"), "0"))
}

bet_region_map_world_data <- function() {
  if (!requireNamespace("maps", quietly = TRUE) || !requireNamespace("ggplot2", quietly = TRUE)) {
    return(data.frame(long = numeric(), lat = numeric(), group = character()))
  }
  world <- tryCatch(ggplot2::map_data("world2"), error = function(e) data.frame())
  if (!nrow(world)) return(world)
  world[world$long >= 100 & world$long <= 220 & world$lat >= -50 & world$lat <= 55, , drop = FALSE]
}

bet_region_map_plot <- function(vertices = bet_region_map_default_vertices()) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) return(NULL)
  vertices <- bet_region_map_normalize_vertices(vertices)
  closed <- bet_region_map_close_polygons(vertices)
  closed$region_factor <- factor(closed$region, levels = sort(unique(closed$region)))
  vertices$region_factor <- factor(vertices$region, levels = sort(unique(vertices$region)))
  labels <- stats::aggregate(cbind(lon, lat) ~ region + region_label, vertices, mean)
  world <- bet_region_map_world_data()

  plot <- ggplot2::ggplot()
  if (nrow(world)) {
    plot <- plot +
      ggplot2::geom_polygon(
        data = world,
        ggplot2::aes(.data$long, .data$lat, group = .data$group),
        fill = "#eee7d5",
        colour = "#b9b4a4",
        linewidth = 0.22
      )
  }
  plot +
    ggplot2::geom_polygon(
      data = closed,
      ggplot2::aes(.data$lon, .data$lat, group = .data$region_factor, fill = .data$region_factor),
      alpha = 0.34,
      colour = "#182c38",
      linewidth = 0.85
    ) +
    ggplot2::geom_path(
      data = closed,
      ggplot2::aes(.data$lon, .data$lat, group = .data$region_factor),
      colour = "#182c38",
      linewidth = 0.95,
      linejoin = "mitre"
    ) +
    ggplot2::geom_point(
      data = vertices,
      ggplot2::aes(.data$lon, .data$lat),
      size = 2.2,
      colour = "#9d1c20",
      fill = "#d7262b",
      shape = 21,
      stroke = 0.35
    ) +
    ggplot2::geom_text(
      data = labels,
      ggplot2::aes(.data$lon, .data$lat, label = .data$region),
      size = 7,
      fontface = "bold",
      colour = "#0e1720"
    ) +
    ggplot2::coord_quickmap(xlim = c(105, 215), ylim = c(-45, 55), expand = FALSE) +
    ggplot2::scale_x_continuous(
      breaks = c(110, 120, 140, 160, 180, 200, 210),
      labels = bet_region_map_lon_label
    ) +
    ggplot2::scale_y_continuous(
      breaks = c(-40, -20, 0, 20, 40, 50),
      labels = bet_region_map_lat_label
    ) +
    ggplot2::scale_fill_manual(values = rep(c("#d9eef7", "#dff4df", "#f5ecd0", "#eadff2", "#f8e1d7"), 2), guide = "none") +
    ggplot2::labs(
      title = "Alternative 5-region structure",
      subtitle = "Default labels use the 2026 BET naming: old Region 4 is Region 5; old Region 5 is Region 4.",
      x = NULL,
      y = NULL
    ) +
    ggplot2::theme_bw(base_size = 13) +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = "#f8fbfc", colour = NA),
      panel.grid.major = ggplot2::element_line(colour = "#d8e1e8", linewidth = 0.35),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text = ggplot2::element_text(size = 12, colour = "#273444"),
      plot.title = ggplot2::element_text(size = 16, face = "bold", colour = "#111827"),
      plot.subtitle = ggplot2::element_text(size = 11, colour = "#526579"),
      plot.margin = ggplot2::margin(8, 12, 8, 12)
    )
}

write_bet_region_map_assets <- function(output_dir,
                                        stem = "bet-2026-five-region",
                                        vertices = bet_region_map_default_vertices(),
                                        make_plot = TRUE) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  vertices <- bet_region_map_normalize_vertices(vertices)
  files <- c(
    csv = file.path(output_dir, paste0(stem, "-vertices.csv")),
    geojson = file.path(output_dir, paste0(stem, ".geojson")),
    png = file.path(output_dir, paste0(stem, "-map.png")),
    manifest = file.path(output_dir, paste0(stem, "-manifest.csv"))
  )
  utils::write.csv(vertices, files[["csv"]], row.names = FALSE, na = "")
  writeLines(as.character(bet_region_map_to_geojson(vertices)), files[["geojson"]])
  if (isTRUE(make_plot) && requireNamespace("ggplot2", quietly = TRUE)) {
    plot <- bet_region_map_plot(vertices)
    if (!is.null(plot)) {
      ggplot2::ggsave(files[["png"]], plot = plot, width = 10.5, height = 7.3, dpi = 180)
    }
  }
  manifest <- data.frame(
    asset = names(files)[names(files) != "manifest"],
    file = basename(files[names(files) != "manifest"]),
    written = file.exists(files[names(files) != "manifest"]),
    note = c(
      "Portable region vertex table; app-readable.",
      "Portable polygon geometry; app-readable.",
      "Report preview map; skipped only if ggplot2 is unavailable."
    ),
    stringsAsFactors = FALSE
  )
  utils::write.csv(manifest, files[["manifest"]], row.names = FALSE, na = "")
  invisible(files)
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
