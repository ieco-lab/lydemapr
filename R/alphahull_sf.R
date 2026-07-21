#' Draw alpha convex hull around lydemapr established points
#'
#' The function takes SLF occurrence data and creates a boundary that defines their invaded range in the US.
#'
#' From the work of:
#' Keller J, Bona SD, Helmus MR. 2026. Leveraging spatial scale and temporal variation to track the spread rate of invasive spotted lanternflies (Lycorma delicatula). NeoBiota. 106:287–307. https://doi.org/10.3897/neobiota.106.177041
#'
#'
#' @param data Unless otherwise specified, lydemapr::lyde
#' @param alpha The coarseness of the hull drawing. Recommended value is based on cross validation work
#' @param bio_year A double limiting lyde observations to on or before the biological year specified.
#' @param use_public A logical specifying whether public reports should be included (FALSE by default).
#' @param only_established A logical specifying whether only points with established SLF should be included (TRUE by default).
#' @param buffer_width A necessary parameter for the construction of a shape from the hull (10 m recommended, so that is the default).
#'
#' @return An sf object containing the alpha convex hull polygon.
#'
#' @export
#'
#' @examples
#' \dontrun{
#'
#' outres <- alphahull_sf(data = lyde,
#'                        alpha = 12000,
#'                        bio_year = 2025,
#'                        use_public = FALSE,
#'                        only_established = TRUE,
#'                        buffer_width = 10)
#'
#' }
#'

alphahull_sf <- function(data = lyde,
                         alpha = 19746.64,
                         bio_year = NULL,
                         use_public = FALSE,
                         only_established = TRUE,
                         buffer_width = 10) {

  suppressMessages(require(sf))
  suppressMessages(require(tidyverse))
  suppressMessages(require(alphahull))
  suppressMessages(require(tigris))

  # Check whether to use public reports
  if (use_public) {
    data.keep <- data
    } else {
      data.keep <- data[data$collection_method != "individual_reporting",]
      }

  # Check whether to use only established points
  if (only_established) {
    data.keep <- data.keep[data.keep$lyde_established == TRUE,]
  } else {
    data.keep <- data.keep
  }


  # Remove any points with missing values
  data.keep <- data.keep[is.na(data.keep$latitude) == FALSE,]
  data.keep <- data.keep[is.na(data.keep$bio_year) == FALSE,]

  # use the most recent biological year if bio_year is not supplied
  if (is.null(bio_year)) {
    bio_year <- max(data.keep$bio_year, na.rm = TRUE)
  }

  # Limit to observations on or before the bio_year specified
  data.keep <- data.keep[data.keep$bio_year <= bio_year,]

  # Make points
  data.pts <- st_as_sf(data.keep, coords = c("longitude", "latitude"), crs = "EPSG:4326")

  # Project for accurate distance measures
  data.proj <- st_transform(data.pts, crs = "EPSG:6350")

  # Extract the coordinates
  data.xy <- st_coordinates(data.proj)

  # Remove duplicates
  data.xy <- unique(data.xy)

  # make the alphahull
  ah <- alphahull::ahull(data.xy, alpha = alpha)
  arcs <- as.data.frame(ah$arcs)

  ah_spldf <- mapply(function(v.x, v.y, theta, r, c1, c2) {
    angles <- alphahull::anglesArc(c(v.x, v.y), theta)
    seqang <- seq(angles[1], angles[2], length = 1000)
    sp::Line(cbind(c1 + r*cos(seqang), c2 + r*sin(seqang)))
  }, arcs$v.x, arcs$v.y, arcs$theta, arcs$r, arcs$c1, arcs$c2,
  SIMPLIFY = FALSE) %>%
    sp::Lines(ID = 1) %>%
    list %>%
    sp::SpatialLines(
      proj4string = sp::CRS(as.character(NA), doCheckCRSArgs = TRUE)
    ) %>%
    sp::SpatialLinesDataFrame(data.frame(id = 1), match.ID = FALSE)

  ah_poly <- raster::buffer(ah_spldf, width = buffer_width)
  # ^ required to convert lines to polys

  pols <- methods::slot(ah_poly, "polygons")
  holes <- lapply(pols, function(x)
    sapply(methods::slot(x, "Polygons"), slot, "hole"))
  not_holes <- lapply(1:length(pols), function(i)
    methods::slot(pols[[i]], "Polygons")[!holes[[i]]])
  IDs <- row.names(ah_poly)
  ah_poly_not_holes <- sp::SpatialPolygons(lapply(1:length(not_holes), function(i)
    sp::Polygons(not_holes[[i]], ID = IDs[i])),
    proj4string = sp::CRS(sp::proj4string(ah_poly), doCheckCRSArgs = TRUE))

  # Load the coastline
  suppressMessages(conus <- tigris::states(cb = TRUE, resolution = "20m") |>
    dplyr::filter(!STUSPS %in% c("AK", "HI", "PR", "VI", "GU", "MP", "AS")) |>
    sf::st_union())

  # Project to match
  conus <- st_transform(conus, crs = "EPSG:6350")

  # Clip to coastline
  outpoly <- sf::st_as_sf(ah_poly_not_holes)
  suppressWarnings(outpoly <- st_set_crs(outpoly, 6350))

  outpoly <- st_intersection(outpoly, conus)

  #Return the shape
  return(outpoly)
}

