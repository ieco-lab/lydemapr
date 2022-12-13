#' Map the spread of SLF in the U.S.
#'
#' The function takes a the dataset of SLF occurrences and displays a map of the spread over time.
#' The "zoom" option allows for a customized focus of the map
#'
#'@export
#'
#'@param resolution Defines the resolution at which the data is displayed. `"1k"` resolution shows data aggregated at a 1km2 grid, while `"10k"` shows tiles aggregated at a 10km2 grid
#'@param zoom Defines the limits of the map to be plotted. `"range"` limits the map to the established range for SLF; `"full"` displays the whole United States. `"custom"` the user to specify the range over which the map should be displayed (see `xlim_coord, ylim_coord` below).
#'@param xlim_coord,ylim_coord Ordered numerical vectors of length 2 determining the longitudinal (`xlim`) and latitudinal (`ylim`) boundaries of the map, to be expressed as decimal degree coordinates. Unnecessary if zoom is set to any value other than `"custom"`
#'@param rarefy TRUE/FALSE
#'@param color_palette Choose among viridis palettes
#'@return The legend of the plot, as an object
#'@examples
#'## Examples
#' d1 <- tibble(x = runif(100, 0, 15),
#'             y = x + rnorm(100, sd = 1),
#'             z = sample(c("A", "B", "C"), 100, replace = T))
#' d2 <- tibble(x = runif(100, -10, 10),
#'             y = - x^2 + rnorm(100, sd = 1),
#'             z = sample(c("A", "B", "C"), 100, replace = T))
#' g1 <- ggplot(d1) +
#'   geom_point(aes(x = x, y = y, col = z))
#' g2 <- ggplot(d2) +
#'   geom_point(aes(x = x, y = y, col = z))
#' g_legend <- get_legend(g1)
#' grid.arrange(g1 + theme(legend.position = "none"),
#'              g2 + theme(legend.position = "none"),
#'              g_legend, nrow = 1,
#'              widths = c(3,3,1))



map_spread <- function(resolution = "1k",
                       zoom = "range",
                       xlim_coord = NULL, ylim_coord = NULL,
                       rarefy = TRUE,
                       color_palette = "plasma",
                       print_message = TRUE
){

  suppressMessages(require(tidyverse))
  suppressMessages(require(sf))


if(print_message){
  print("Please be patient: the large dataset might cause the map to be slow to load")
}

## Setting up ##
# First some preparations:

### Loading background maps ###

# extracting a map of the states
states <- tigris::states() %>%
  select(ID = NAME, geometry)
# finding centroids for label positions
suppressWarnings(
  states <- cbind(states, st_coordinates(st_centroid(states)))
)
# only selecting contiguous US
states <- states %>%
  dplyr::filter(!(ID %in% c("Alaska", "American Samoa",
                            "Commonwealth of the Northern Mariana Islands",
                            "Guam", "Hawaii","Puerto Rico",
                            "United States Virgin Islands")))
# making table key for state 2-letter abbreviations
state_abbr <- tibble(state.name = state.name,
                     state.abb) %>%
  dplyr::left_join(tibble(ID = states$ID), ., by = c(ID = "state.name")) %>%
  dplyr::mutate(state.abb = tidyr::replace_na(state.abb, ""))
# adding 2-letter codes to state sf
states$code <- state_abbr$state.abb


### Selecting appropriate dataset based on resolution specified

if(resolution == "1k"){
  data <- lyde
} else if(resolution == "10k"){
  data <- lyde_10k
} else {stop("Wrong resolution specified. Please select '1k' or '10k'")}


### Rarefying data if required (default), and selecting appropriate resolution ###

data_established <- data %>%
  dplyr::filter(slf_established) %>%
  dplyr::group_by(latitude, longitude) %>%
  dplyr::summarise(
    bio_year = min(bio_year),
    .groups = "keep")

data_surveyed <- data %>%
  dplyr::group_by(latitude, longitude) %>%
  dplyr::summarise(
    slf_established = any(slf_established),
    .groups = "keep") %>%
  dplyr::filter(!slf_established)


### Determining range based on zoom specification

if(zoom == "full"){
  xlim_coord <- NULL
  ylim_coord <- NULL
} else if(zoom == "range"){
  xlim_coord <- data %>% filter(slf_established) %>% pull(longitude) %>% range()
  # tweaking to space map a little
  xlim_coord[1] <- xlim_coord[1] - diff(xlim_coord)*0.1
  xlim_coord[2] <- xlim_coord[2] + diff(xlim_coord)*0.1

  ylim_coord <- data %>% filter(slf_established) %>% pull(latitude) %>% range()
  # tweaking again
  ylim_coord[1] <- ylim_coord[1] - diff(ylim_coord)*0.5
  ylim_coord[2] <- ylim_coord[2] + diff(ylim_coord)*0.5
} else if(zoom == "custom"){
  xlim_coord = xlim_coord
  ylim_coord = ylim_coord
}


## Producing Map ##

if(resolution == "1k"){

  ggplot() +
    geom_sf(data = states, fill = "white") +
    coord_sf(xlim = xlim_coord, ylim = ylim_coord, expand = FALSE) +
    geom_point(data = data_surveyed,
               aes(x = longitude, y = latitude),
               col = "grey", alpha = 0.3, shape = 4, size = .5) +
    geom_point(data = data_established %>%
                 arrange(desc(bio_year)) %>%
                 mutate(bio_year = as.factor(bio_year)),
               aes(x = longitude, y = latitude, col = bio_year),
               shape = 19, size =0.8) +
    geom_text(data = states, aes(X, Y, label = code), size = 4.5) +
    scale_color_viridis_d(option = color_palette, direction = 1) +
    labs(x = "Longitude", y = "Latitude", col = "Year") +
    guides(colour = guide_legend(override.aes = list(size = 5,
                                                     shape = 15)))+
    theme(legend.position = c(0.9,0.2),
          panel.grid = element_blank(),
          legend.key=element_rect(fill=NA))

} else if(resolution == "10k"){

  ggplot() +
    geom_sf(data = states, fill = "white") +
    coord_sf(xlim = xlim_coord, ylim = ylim_coord, expand = FALSE) +
    geom_tile(data = data_surveyed,
               aes(x = longitude, y = latitude),
               fill = "grey75", alpha = 1) +
    geom_tile(data = data_established %>%
                 arrange(desc(bio_year)) %>%
                 mutate(bio_year = as.factor(bio_year)),
               aes(x = longitude, y = latitude, fill = bio_year)) +
    geom_text(data = states, aes(X, Y, label = code), size = 4.5) +
    scale_fill_viridis_d(option = "plasma", direction = 1) +
    labs(x = "Longitude", y = "Latitude", fill = "Year") +
    guides(colour = guide_legend(override.aes = list(size = 5,
                                                     shape = 15)))+
    theme(legend.position = c(0.9,0.2),
          panel.grid = element_blank(),
          legend.key=element_rect(fill=NA))

}



}
