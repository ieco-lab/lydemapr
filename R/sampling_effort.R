#' Produce a table summarizing sampling effort
#'
#' The function summarizes the sampling effort each year based on SLF records from government sources, using the alpha convex hull to delineate the invaded area.
#'
#' @param data Unless otherwise specified, lydemapr::lyde
#' @param alpha The coarseness of the hull drawing. Recommended value is based on cross validation work
#'
#' @return A table
#'
#' @export
#'
#' @examples
#' \dontrun{
#' }


sampling_effort <- function(data = lyde,
                            alpha = 19746.64,
                            buffer_width = 10) {

  suppressMessages(require(sf))

  years <- sort(unique(data$bio_year))


  #hull_data <- data %>% distinct(bio_year, latitude, longitude, lyde_established, .keep_all = TRUE)

  # run alphahulls, and calculate the area and perimeter for each year
  alphahull_sizes <- purrr::map_dfr(years, function(yr) {
    hull <- lydemapr::alphahull_sf(data = data,
                         alpha = alpha,
                         bio_year = yr,
                         use_public = FALSE,
                         only_established = TRUE,
                         buffer_width = buffer_width)

    tibble::tibble(bio_year = yr,
                   A = round(as.numeric(st_area(hull))/1e6, 1),
                   P = round(as.numeric(st_length(st_boundary(hull)))/1000, 1))})

  obs <- lyde %>%
    dplyr::filter(collection_method != "individual_reporting") %>%
    dplyr::distinct(bio_year, latitude, longitude, .keep_all = T) %>%
    dplyr::group_by(bio_year) %>%
    dplyr::summarize(presences = sum(lyde_present == TRUE, na.rm = TRUE),
                     presences_w_establishment = sum(lyde_present == TRUE & lyde_established == TRUE, na.rm = TRUE),
                     absences = sum(lyde_present == FALSE, na.rm = TRUE))

  tab <- obs %>% dplyr::left_join(alphahull_sizes, by = dplyr::join_by(bio_year))

  tab <- tab %>%
    dplyr::mutate('Sampling effort (Obs. per km\u00B2 area)' = round((presences + absences)/A, 1),
                  'Sampling effort (Obs. per km boundary)' = round((presences + absences)/P, 1))

  tab %>% dplyr::rename('Biological Year' = bio_year,
                        'Number of presences' = presences,
                        'Number of presences with confirmed establishment' = presences_w_establishment,
                        'Number of absences' = absences,
                        'Invaded area (km\u00B2)' = A,
                        'Invasion boundary length (km)' = P)
}
