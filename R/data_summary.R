#' Prints quick data summary
#'
#' The function tabulates the data into observations by year and state
#'
#'@export
#'
#'@param year_type String defining whether to use the biological year definition ("biological", May 1st - April 30th, default) or the calendar year when faceting the figure ("calendar").
#'@param
#'@return A table summarizing the number of datapoints collected each year by state
#'@examples
#'## Examples
#'

data_summary <- function(year_type = "biological"){

  if(year_type == "biological"){

    table(lydemap::lyde$state, lydemap::lyde$bio_year,
          useNA = "ifany")

  }else if(year_type == "calendar"){

    table(lydemap::lyde$state, lydemap::lyde$year,
          useNA = "ifany")

  }else{stop("Please specify a suitable `year_type`: 'biological' or 'calendar'")}

}
