#' Display spread of SLF and survey effort through time
#'
#' The function plots the spread of SLF over time, showing the recorded population density detected by the survey effort
#'
#'@export
#'
#'@param year_type String defining whether to use the biological year definition ("biological", May 1st - April 30th, default) or the calendar year when faceting the figure ("calendar").
#'@param color_palette Uses color palettes defined in \link[ggplot2]{scale_color_brewer}. Defaults to "Reds".
#'@param ncols Number of column for facet.
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

  data <- lyde_10k %>%
    dplyr::filter(!is.na(slf_density)) %>%
    dplyr::mutate(slf_density = factor(slf_density,
                                       levels = c("Unpopulated",
                                                  "Low",
                                                  "Medium",
                                                  "High"))) %>%
    dplyr::group_by(longitude, latitude, bio_year) %>%
    dplyr::summarise(slf_present = any(slf_present),
              slf_established = any(slf_established),
              slf_density = max(as.numeric(slf_density), na.rm = T),
              .groups = "keep") %>%
    dplyr::mutate(slf_density = dplyr::recode(as.character(slf_density),
                                "1" = "Unpopulated",
                                "2" = "Low",
                                "3" = "Medium",
                                "4" = "High"),
           slf_density = factor(slf_density, levels = c("Unpopulated",
                                                        "Low",
                                                        "Medium",
                                                        "High"))) %>%
    dplyr::rename(time = bio_year)

  } else if(year_type == "calendar"){

    data <- lyde_10k %>%
      dplyr::filter(!is.na(slf_density)) %>%
      dplyr::mutate(slf_density = factor(slf_density,
                                         levels = c("Unpopulated",
                                                    "Low",
                                                    "Medium",
                                                    "High"))) %>%
      dplyr::group_by(longitude, latitude, year) %>%
      dplyr::summarise(slf_present = any(slf_present),
                       slf_established = any(slf_established),
                       slf_density = max(as.numeric(slf_density), na.rm = T),
                       .groups = "keep") %>%
      dplyr::mutate(slf_density = dplyr::recode(as.character(slf_density),
                                                "1" = "Unpopulated",
                                                "2" = "Low",
                                                "3" = "Medium",
                                                "4" = "High"),
                    slf_density = factor(slf_density, levels = c("Unpopulated",
                                                                 "Low",
                                                                 "Medium",
                                                                 "High"))) %>%
      dplyr::rename(time = year)

  } else {

    stop("Wrong year_type defined. Please select 'biological' or 'calendar'")

  }


  ### Defining plot area ###

  xlim_coord <- data %>% filter(slf_established) %>% pull(longitude) %>% range()
  # tweaking to space map a little
  xlim_coord[1] <- xlim_coord[1] - diff(xlim_coord)*0.1
  xlim_coord[2] <- xlim_coord[2] + diff(xlim_coord)*0.1

  ylim_coord <- data %>% filter(slf_established) %>% pull(latitude) %>% range()
  # tweaking again
  ylim_coord[1] <- ylim_coord[1] - diff(ylim_coord)*0.5
  ylim_coord[2] <- ylim_coord[2] + diff(ylim_coord)*0.5


  ## Plotting figure ##

  ggplot() +
    geom_sf(data = states, fill = "white") +
    geom_tile(data = data %>% filter(slf_established),
              aes(x = longitude, y = latitude, fill = slf_density)) +
    geom_sf(data = states, fill = "transparent") +
    coord_sf(xlim = xlim_coord, ylim = ylim_coord, expand = FALSE) +
    scale_fill_brewer(palette = color_palette) +
    labs(x = "Longitude", y = "Latitude", fill = "Recorded SLF Density") +
    theme(legend.position = "top",
          panel.grid = element_blank()) +
    facet_wrap(.~time, ncol = ncols)

}
