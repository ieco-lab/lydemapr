#' Display spread of SLF and survey effort through time
#'
#' The function plots the spread of SLF over time, showing the recorded population density detected by the survey effort
#'
#'@export
#'
#'@param year_type String defining whether to use the biological year definition ("biological", May 1st - April 30th, default) or the calendar year when faceting the figure ("calendar").
#'@param color_palette Uses color palettes defined in \link[ggplot2]{scale_color_brewer}. Defaults to "Reds".
#'@param ncols Number of columns for the facet plotting.
#'@return A faceted plot of the spread of SLF over time in the US
#'@examples
#'## Examples
#'



map_yearly <- function(year_type = "biological",
                       color_palette = "Reds",
                       ncols = 2
){

  suppressMessages(require(tidyverse))
  suppressMessages(require(sf))
  # switching off Spherical geometry
  suppressMessages(sf::sf_use_s2(FALSE))


  ### Loading background maps ###

  # extracting a map of the states
  states <- tigris::states() %>%
    select(ID = NAME, geometry)

  # only selecting contiguous US
  states <- states %>%
    dplyr::filter(!(ID %in% c("Alaska", "American Samoa",
                              "Commonwealth of the Northern Mariana Islands",
                              "Guam", "Hawaii","Puerto Rico",
                              "United States Virgin Islands")))

  ### Rarefying data ###

  if(year_type == "biological"){

  data <- lydemapr::lyde_10k %>%
    dplyr::filter(!is.na(lyde_density)) %>%
    dplyr::rename(time = bio_year)

  } else if(year_type == "calendar"){

    data <- lydemapr::lyde_10k %>%
      dplyr::filter(!is.na(lyde_density)) %>%
      dplyr::rename(time = year)

  } else {

    stop("Wrong year_type defined. Please select 'biological' or 'calendar'")

  }


  ### Defining plot area ###

  xlim_coord <- data %>% filter(lyde_established) %>% pull(longitude) %>% range()
  # tweaking to space map a little
  xlim_coord[1] <- xlim_coord[1] - diff(xlim_coord)*0.1
  xlim_coord[2] <- xlim_coord[2] + diff(xlim_coord)*0.1

  ylim_coord <- data %>% filter(lyde_established) %>% pull(latitude) %>% range()
  # tweaking again
  ylim_coord[1] <- ylim_coord[1] - diff(ylim_coord)*0.5
  ylim_coord[2] <- ylim_coord[2] + diff(ylim_coord)*0.5


  ## Plotting figure ##

  ggplot() +
    geom_sf(data = states, fill = "white") +
    geom_tile(data = data %>% filter(lyde_established),
              aes(x = longitude, y = latitude, fill = lyde_density)) +
    geom_sf(data = states, fill = "transparent") +
    coord_sf(xlim = xlim_coord, ylim = ylim_coord, expand = FALSE) +
    scale_fill_brewer(palette = color_palette) +
    labs(x = "Longitude", y = "Latitude", fill = "Recorded SLF Density") +
    theme(legend.position = "top",
          panel.grid = element_blank()) +
    facet_wrap(.~time, ncol = ncols)

}
