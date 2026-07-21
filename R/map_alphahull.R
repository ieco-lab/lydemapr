#' Map alpha convex hull around the lyde data
#'
#' The function maps a dataset of SLF occurrences and a polygon delineating their invaded range.
#'
#'
#' @param data The lydemapr data file.
#' @param bio_year Limits the data observations to those occurring on or before the biological year specified. Unless explicitly supplied, it defaults to the latest available year.
#' @param alpha The coarseness of the hull drawing. The default is based on the cross validation work.
#' @param use_public A logical specifying whether public reports should be included (FALSE by default).
#' @param only_established A logical specifying whether only points with established SLF should be included (TRUE by default).
#' @param buffer_width A necessary parameter for the construction of a shape from the hull (10 m recommended, so that is the default).
#' @param zoom Defines the limits of the map to be plotted. `"range"` limits the map to the established range for SLF; `"full"` displays the whole United States. `"custom"` the user to specify the range over which the map should be displayed (see `xlim_coord, ylim_coord` below).
#' @param xlim_coord,ylim_coord Ordered numerical vectors of length 2 determining the longitudinal (`xlim`) and latitudinal (`ylim`) boundaries of the map, to be expressed as decimal degree coordinates. Unnecessary if zoom is set to any value other than `"custom"`
#' @param print_message Logical value. Can be set to `FALSE` to shut down the warning on run time.
#'
#'
#' @return A ggplot map of the alpha convex hull on top of the lyde data.
#'
#' @export
#'
#' @examples
#' \dontrun {
#'
#' map_alphahull(bio_year = 2025)
#'
#' map_alphahull(use_public = TRUE, bio_year = 2022, zoom = "full")
#'
#' }
#'

map_alphahull <- function(data = lyde,
                          bio_year = max(data$bio_year, na.rm = TRUE),
                          alpha = 19746.64,
                          use_public = FALSE,
                          only_established = TRUE,
                          buffer_width = 10,
                          zoom = "range",
                          xlim_coord = NULL,
                          ylim_coord = NULL,
                          print_message = TRUE) {

  suppressMessages(require(sf))
  suppressMessages(require(tidyverse))
  # switching off spherical geometry
  suppressMessages(sf::sf_use_s2(FALSE))

  if(print_message){
    print("Please be patient: the large dataset might cause the map to load slowly")
  }

  ## Setting up ##
  # First some preparations:

  ### Loading background maps ###

  # extracting a map of the states
  suppressMessages(states <- sf::st_as_sf(maps::map("state", plot = FALSE, fill = TRUE)))

  # looking up state abbreviations
  state_lookup <- dplyr::tibble(
    ID    = tolower(state.name),
    abbr  = state.abb
  )

  # adding abbreviations and finding centroids of states to place labels of map
  suppressWarnings(states <- states %>%
                     dplyr::left_join(state_lookup, by = "ID") %>%
                     cbind(sf::st_coordinates(sf::st_centroid(states))) %>%
                     filter(!is.na(abbr)))


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


  # write the alphahull with the ideal specifications and for the provided bio_year
  outres <- lydemapr::alphahull_sf(data = data,
                                   alpha = alpha,
                                   bio_year = bio_year,
                                   use_public = use_public,
                                   only_established = only_established,
                                   buffer_width = buffer_width) %>%
    sf::st_transform(crs = 4326)

  # limit the data to on or before the provided bio_year
  data.keep <- data.keep[data.keep$bio_year <= bio_year,]

  data_established <- data.keep %>%
    dplyr::filter(lyde_established) %>%
    as_tibble()

  data_surveyed <- data.keep %>%
    dplyr::filter(!lyde_established) %>%
    as_tibble()


  if(zoom == "full"){
    xlim_coord <- NULL
    ylim_coord <- NULL
  } else if(zoom == "range"){
    xlim_coord <- data.keep %>% filter(lyde_established) %>% pull(longitude) %>% range()
    # tweaking to space map a little
    xlim_coord[1] <- xlim_coord[1] - diff(xlim_coord)*0.1
    xlim_coord[2] <- xlim_coord[2] + diff(xlim_coord)*0.1

    ylim_coord <- data.keep %>% filter(lyde_established) %>% pull(latitude) %>% range()
    # tweaking the other coordinate
    ylim_coord[1] <- ylim_coord[1] - diff(ylim_coord)*0.5
    ylim_coord[2] <- ylim_coord[2] + diff(ylim_coord)*0.5
  } else if(zoom == "custom"){
    stopifnot(diff(xlim_coord)>0)
    stopifnot(diff(ylim_coord)>0)
  }

  ggplot(data = states) +
    geom_sf(fill = "white") +
    geom_point(data = data_surveyed, aes(x = longitude, y = latitude),
               col = "grey", alpha = 0.3, shape = 4, size = .5) +
    geom_point(data = data_established %>%
                 arrange(desc(bio_year)) %>%
                 mutate(bio_year = forcats::fct_rev(
                   forcats::as_factor(bio_year)
                 )), aes(x = longitude, y = latitude, color = bio_year), shape = 19, size = 0.5) +
    geom_sf(data = outres, alpha = 0.4, fill = "black", color = "red") +
    scale_color_viridis_d(option = "plasma", direction = 1) +
    geom_text(data = states, aes(X, Y, label = abbr), size = 4.5) +
    coord_sf(xlim = xlim_coord, ylim = ylim_coord, expand = FALSE) +
    labs(x = "Longitude", y = "Latitude", color = "Year") +
    guides(colour = guide_legend(override.aes = list(size = 5,
                                                     shape = 15))) +
    theme(legend.position = c(0.9,0.2),
          panel.grid = element_blank(),
          legend.key=element_rect(fill=NA),
          panel.background = element_rect(fill = 'white', color = 'white'))
}
