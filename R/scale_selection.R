#' Plot the optimal alphahull values each year
#'
#' This function creates a figure to find the optimal alphahull value each year. It creates a figure similar to Fig. S2.1 from https://neobiota.pensoft.net/article/177041.
#'
#' @param data The alpha_selection file.
#'
#'
#' @return A ggplot that finds the preferred α’ for each year using Youden's J statistic.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' scale_selection()
#'}

scale_selection <- function(data = alpha_selection) {

  suppressMessages(require(ggplot2))

  # Read in data
  d <- data

  d$alpha_prime <- d$alpha * sqrt(pi)

  # First, we need to sum by fold
  d$alpha_year <- paste(d$alpha, d$year, sep = "_")
  d2 <- data.frame(alpha_year = unique(d$alpha_year), FP = NA, TP = NA, FN = NA, TN = NA)

  for (i in seq_len(nrow(d2))) {
    d2$FP[i] <- sum(d$FP[d$alpha_year == d2$alpha_year[i]])
    d2$FN[i] <- sum(d$FN[d$alpha_year == d2$alpha_year[i]])
    d2$TP[i] <- sum(d$TP[d$alpha_year == d2$alpha_year[i]])
    d2$TN[i] <- sum(d$TN[d$alpha_year == d2$alpha_year[i]])
  }

  # Get year and alpha back
  d2 <- tidyr::separate(d2, alpha_year, into = c("alpha", "year"), sep = "_", remove = FALSE)
  d2$alpha <- as.numeric(d2$alpha)
  d2$year <- as.integer(d2$year)

  # Calculate derived values
  d2$precision <- d2$TP/(d2$TP + d2$FP)
  d2$recall <- d2$TP/(d2$TP + d2$FN)
  d2$FPR <- d2$FP/(d2$FP + d2$TN)
  d2$sensitivity <- d2$TP/(d2$TP + d2$FN)

  # Now we select the optimal values
  # For the AUC-style plot, Youden's J measures the distance from the 1:1 line
  d2$youdenJ <- d2$TP/(d2$TP + d2$FN) + d2$TN/(d2$TN + d2$FP) - 1

  #Summarize to years
  d3 <- data.frame(year = unique(d2$year), youdenJ = NA, alpha_sel = NA)
  for (i in seq_len(nrow(d3))) {
    data.subset <- d2[d2$year == d3$year[i], ]
    best <- which.max(data.subset$youdenJ)
    d3$youdenJ[i] <- data.subset$youdenJ[best]
    d3$alpha_sel[i] <- data.subset$alpha[best]
  }

  # Alternatively, we can consider g-mean
  # This is equal to sqrt(Sensitivity * Specificity)
  # Which is sqrt(TPR x TNR)
  d2$specificity <- d2$TN/(d2$TN + d2$FP)
  d2$gmean <- sqrt(d2$sensitivity * d2$specificity)

  d3$alpha_sel_gmean <- NA
  d3$gmean <- NA
  for (i in seq_len(nrow(d3))) {
    data.subset <- d2[d2$year == d3$year[i], ]
    best <- which.max(data.subset$gmean)
    d3$gmean[i] <- data.subset$gmean[best]
    d3$alpha_sel_gmean[i] <- data.subset$alpha[best]
  }

  #####################
  # Highlight the best-performing value in the ROC space plots
  d3$alpha_year <- paste(d3$alpha_sel, d3$year, sep = "_") # Add alpha_year to d3

  d_highs <- d2[d2$alpha_year %in% d3$alpha_year,]
  d_highs$round_alpha <- round(d_highs$alpha, digits = 1)

  d3$alpha_prime <- d3$alpha_sel * sqrt(pi)
  d2$alpha_prime <- d2$alpha * sqrt(pi)
  d_highs$alpha_prime <- round(d_highs$alpha * sqrt(pi), 0)
  d_highs$alpha_prime_lab <- paste(d_highs$alpha_prime, " m")

  p.roc <- ggplot(d2, aes(x = FPR, y = sensitivity))
  p.roc +
    geom_abline(slope = 1, intercept = 0, lty = "dashed") +
    geom_point(data = d_highs, aes(x = FPR, y = sensitivity), color = "red", size = 4) +
    geom_label(data = d_highs, aes(x = FPR, y = sensitivity, label = alpha_prime_lab), vjust = 0, nudge_y = -0.1, nudge_x = 0.22) +
    geom_point(aes(color = alpha_prime)) +
    facet_wrap(~year) +
    xlim(c(0,1)) +
    ylim(c(0,1)) +
    xlab("False positive rate") +
    scale_color_continuous(type = "viridis", name = "α' (m)", trans = "log", breaks = c(2000, 10000, 50000, 150000)) +
    theme_bw()

  }

