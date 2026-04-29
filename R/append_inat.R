#' Clean downloaded iNaturalist data into the same grid as the `lyde` and `lyde_10k` datasets
#'
#' The function tidies and cleans downloaded spotted lanternfly data from iNaturalist's export page and appends it to `lyde`.
#'
#' This should be applied to a dataset downloaded through the link:
#'    `https://www.inaturalist.org/observations/export`
#'
#'    Or for the direct search query:
#'    `https://www.inaturalist.org/observations/export?search_on=names&quality_grade=research&identifications=most_agree&captive=false&place_id=1&taxon_id=324726`
#'
#' @export
#'
#' @param path A character string that is the path to the csv file containing the downloaded iNaturalist data.
#' @param round (logical) If TRUE, the latitude and longitude columns will have been rounded to the 1k grid. If FALSE, the coordinates will be raw, directly from iNaturalist.
#'
#' @return A cleaned tibble
#
#'
#' @examples
#' \dontrun{
#' # return lyde with iNaturalist observations with the raw latitude/longitude coordinates
#' df <- append_inat("observations-686514.csv", round = FALSE)
#'
#' # return lyde with iNaturalist observations with the latitude/longitude coordinates rounded to the 1km grid
#' df <- append_inat("observations-686514.csv", round = TRUE)
#' }

append_inat <- function(path, round = TRUE) {

  suppressMessages(require(tidyverse))

  # read in the file
  df <- readr::read_csv(path, show_col_types = FALSE)

  # add in a function that will gracefully skip a step if the columns called are not found in the path file
  safe_step <- function(df, cols, step_fn) {
    missing <- lubridate::setdiff(cols, names(df))

    if(length(missing) > 0) {
      warning(paste0("Skipping step: missing column(s): ",
                     paste(missing, collapse = ",")),
              call. = FALSE)
      return(df)
    }
    step_fn(df)
  }

  # add columns identifying the source information and collection method
  df$source <- "inat"
  df$source_agency <- "iNaturalist"
  df$collection_method <- "individual_reporting"

  # fix columns that should be logical
  inat_slf <- safe_step(df,
                        c("captive_cultivated", "coordinates_obscured"),
                        function(d) {
                          d %>%
                            dplyr::mutate(across(all_of(
                              c("captive_cultivated", "coordinates_obscured")),
                              ~ if(!is.logical(.x)) as.logical(.x) else .x))})

  # remove duplicates
  inat_slf <- safe_step(inat_slf,
                        "id",
                        function(d) {
                          d %>%
                            dplyr::distinct(id, .keep_all = T)})

  # clean coordinates
  inat_slf <- safe_step(inat_slf,
                        c("coordinates_obscured"),
                        function(d) {
                          d %>%
                            dplyr::filter(!coordinates_obscured, !is.na(latitude), !is.na(longitude)) %>%
                            dplyr::select(-coordinates_obscured)})

  # add date information (year ad bio_year)
  inat_slf <- safe_step(inat_slf,
                        c("observed_on", "time_observed_at", "created_at", "updated_at"),
                        function(d) {
                          d %>%
                            dplyr::mutate_at(c("observed_on", "time_observed_at", "created_at", "updated_at"),
                                             ~ parsedate::parse_date(.)) %>%   # clean dates
                            dplyr::rename(SurveyDate = observed_on) %>%
                            dplyr::mutate(month = lubridate::month(SurveyDate),
                                          year = lubridate::year(SurveyDate)) %>%
                            dplyr::mutate(bio_year = dplyr::if_else(month < 5,      # add the biological year
                                                                    year - 1,
                                                                    year,
                                                                    missing = year))})

  # converting state info
  name_to_abb <- tibble::tibble(place_state_name = state.name,
                                iNatState = state.abb)

  inat_slf <- safe_step(inat_slf,
                        "place_state_name",
                        function(d) {
                          d %>%
                            dplyr::left_join(name_to_abb)})

  ##### ATTRIBUTE POLYS #####
  # manually attributing state polygons

  # loading polygons of states (from package tigris)
  states <- suppressMessages(tigris::states(cb = T, resolution = "500k"))

  # only looking at conus
  selected_states <- c(state.abb, "DC")
  selected_states <- selected_states[!selected_states %in% c("AK", "HI")]

  coords <- c("longitude", "latitude")

  # sub-setting multipolygon
  polys <- states %>%
    dplyr::select(State = STUSPS) %>%
    dplyr::filter(State %in% selected_states)


  # storing inat_slf's colnames for later and data length
  ori_cols <- colnames(inat_slf)
  ori_rown <- nrow(inat_slf)

  # adding row_ID column to inat_slf
  inat_slf <- add_column(inat_slf, row_ID = 1:nrow(inat_slf))

  # intersecting
  inat_slf <- inat_slf %>%
    # reducing data to coordinates only, and ID for future merging
    dplyr::select(!!coords, row_ID) %>%
    # transforming into sf object
    sf::st_as_sf(coords = coords,
                 crs = sf::st_crs(polys)) %>%
    # intersecting polygons with coordinate points
    sf::st_join(polys, join = (sf::st_intersects)) %>%
    as_tibble() %>%
    # simplifying to drop geometry
    dplyr::select(-geometry) %>%
    # joining back into main dataset
    dplyr::left_join(inat_slf, ., by = "row_ID") %>%
    dplyr::select(-row_ID)


  # use the iNat state data to fill in gaps
  inat_slf <- safe_step(inat_slf,
                        c("State", "iNatState"),
                        function(d) {
                          d %>%
                            dplyr::mutate(state = dplyr::coalesce(State, iNatState))})
  ###########################

  # add present, established, and density columns
  inat_slf$lyde_present <- TRUE
  inat_slf$lyde_established <- FALSE
  inat_slf$lyde_density <- "Unpopulated"

  # add uuid
  inat_slf <- inat_slf %>%
    tibble::add_column(pointID = uuid::UUIDgenerate(use.time = F,
                                                    n = nrow(inat_slf)))

  # remove the unnecessary columns
  inat_slf <- safe_step(inat_slf,
                      c("source", "year", "bio_year", "latitude", "longitude",
                        "state", "lyde_present", "lyde_established", "lyde_density",
                        "source_agency", "collection_method", "pointID"),
                      function(d) {
                        d %>%
                          dplyr::select(source, year, bio_year, latitude, longitude, state, lyde_present,
                                        lyde_established, lyde_density, source_agency, collection_method, pointID)})


  ### CREATE GRIDDED DATA ###

  # rounding the coordinates to get 1km data (unless otherwise specified) and 10k data

  # we need to determine the correspondence in decimal degrees to a km, for the transformation
  # we will use as reference the area around the site of first discovery of SLF to derive the grid size
  # longitudinal distance (calculated in km)
  LonDist <- round(geosphere::distm(c(-76, 40.5), c(-75, 40.5), fun = geosphere::distHaversine)[1,1]/1000, 0)
  LatDist <- round(geosphere::distm(c(-75.5, 41), c(-75.5, 40), fun = geosphere::distHaversine)[1,1]/1000, 0)

  # here we round the coordinates to 1km if specified. otherwise, they will be the raw iNaturalist data
  if (round == TRUE) {
    # approximate resolution is 1 km
    grid_res = 1

    # now we can round to 1k
    inat_slf <- safe_step(inat_slf,
                      c("latitude", "longitude"),
                      function(d) {
                        d %>%
                          dplyr::mutate(latitude = DescTools::RoundTo(latitude, multiple = grid_res/LatDist),
                                        longitude = DescTools::RoundTo(longitude, multiple = grid_res/LonDist))})
    }

  # regardless of if the coordinates should be rounded to 1k or not, we will include the rounded 10k coordinates
  grid_res = 10
  inat_slf <- safe_step(inat_slf,
                        c("latitude", "longitude"),
                        function(d) {
                          d %>%
                            dplyr::mutate(rounded_latitude_10k = DescTools::RoundTo(latitude, multiple = grid_res/LatDist),
                                          rounded_longitude_10k = DescTools::RoundTo(longitude, multiple = grid_res/LonDist))})



  # now we will bind the inat data to the lyde data
  inat_lyde <- dplyr::bind_rows(lydemapr::lyde, inat_slf)

  # to be consistent witht the lyde dataset, we will remove all data points from years after the current year
  if(lubridate::month(Sys.Date()) >= 5) {
    inat_lyde <- inat_lyde %>%
      dplyr::filter(bio_year <= lubridate::year(Sys.Date())-1)
    } else {
    inat_lyde <- inat_lyde %>%
      dplyr::filter(bio_year < lubridate::year(Sys.Date())-1)
    }

###########################

  return(inat_lyde)
}
