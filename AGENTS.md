# AGENTS.md — Guidance for AI Agents

## Project Overview

`lydemapr` is an R package that aggregates and anonymizes presence/absence and population density survey data for the Spotted Lanternfly (*Lycorma delicatula*, SLF) in the United States, and provides functions to visualize the spread of this invasive pest through maps and summaries.

- **Package version:** 4.0.0
- **License:** CC-BY
- **R version requirement:** ≥ 4.0.0
- **Maintainer:** Seba De Bona <sebastiano.debona@temple.edu>
- **Website:** https://ieco-lab.github.io/lydemapr/
- **Bug reports:** https://github.com/ieco-lab/lydemapr/issues

## Repository Structure

```
lydemapr/
├── R/                        # R source files (exported functions and data docs)
│   ├── append_inat.R         # append_inat(): integrates downloaded iNaturalist data
│   ├── lyde.R                # Documentation for the `lyde` dataset (1 km² resolution)
│   ├── lyde_summary.R        # lyde_summary(): tabulates data by year and state
│   ├── lydemapr-package.R    # Package-level documentation
│   ├── map_spread.R          # map_spread(): snapshot map of SLF spread
│   └── map_yearly.R          # map_yearly(): faceted map of SLF spread over time
├── man/                      # Auto-generated Rd documentation (do not edit manually)
├── data/
│   ├── lyde.rda              # Primary dataset at 1 km² resolution
│   └── lyde_10k.rda          # Rarefied dataset at 10 km² resolution
├── vignettes/
│   └── introduction.Rmd      # Package vignette demonstrating all functions
├── download_data/            # Versioned downloadable data exports (CSV + metadata)
│   ├── older_data_versions/
│   └── v4_2025/
├── DESCRIPTION               # Package metadata and dependencies
├── NAMESPACE                 # Exported symbols (managed by roxygen2)
├── _pkgdown.yml              # pkgdown website configuration
└── lydemapr.Rproj            # RStudio project file
```

## Dependencies

**Imports** (required at runtime):
- `sf` — spatial operations and coordinate transformations
- `tidyverse` — data manipulation and ggplot2-based plotting
- `tigris` — fetches US state boundary shapefiles

**Suggests** (needed for vignettes/docs only):
- `knitr`, `rmarkdown`

**Additional packages used inside functions** (loaded via `require()`):
- `geosphere` — distance calculations in `append_inat()`
- `DescTools` — coordinate rounding in `append_inat()`
- `uuid` — unique point ID generation in `append_inat()`
- `lubridate`, `parsedate` — date parsing in `append_inat()`
- `forcats` — factor manipulation in `map_spread()`

## Key Functions

| Function | Description |
|---|---|
| `map_spread()` | Snapshot map of SLF spread; supports `"1k"`/`"10k"` resolution and `"range"`/`"full"`/`"custom"` zoom |
| `map_yearly()` | Faceted map of SLF density by biological or calendar year |
| `lyde_summary()` | Cross-tabulates observations by state and year |
| `append_inat(path, round)` | Reads a downloaded iNaturalist CSV and appends it to `lyde` |

## Build, Install, and Test Commands

All commands should be run from an R console with the working directory set to the package root, or from a terminal within the `lydemapr.Rproj` RStudio project.

### Install the package locally

```r
# Install all declared dependencies first
install.packages(c("sf", "tidyverse", "tigris", "knitr", "rmarkdown"))

# Install the package (without vignettes for speed)
devtools::install()

# Install including vignettes
devtools::install(build_vignettes = TRUE)
```

### Build documentation (roxygen2)

Documentation in `man/` and `NAMESPACE` is generated from inline `#'` roxygen comments. Always regenerate after editing function documentation:

```r
devtools::document()
```

### Run package checks

```r
# Full CRAN-style check (runs examples and vignettes; can be slow)
devtools::check()

# Quicker check without building vignettes
devtools::check(vignettes = FALSE)
```

### Build the pkgdown website

```r
pkgdown::build_site()
```

## Coding Conventions

- **Documentation:** All exported functions use [roxygen2](https://roxygen2.r-lib.org/) tags (`#'`). Update inline docs whenever changing function signatures or behavior, then run `devtools::document()`.
- **NAMESPACE:** Managed exclusively by roxygen2. Do not edit `NAMESPACE` by hand; add `#' @export` to export a new function.
- **Data:** `lyde` and `lyde_10k` are stored as `.rda` files in `data/`. The documentation for these datasets lives in `R/lyde.R`. The raw datasets must **never** be exported (see the `# data should NEVER be exported` comment).
- **Spatial geometry:** Both `map_spread()` and `map_yearly()` disable S2 spherical geometry (`sf::sf_use_s2(FALSE)`) to avoid edge-case errors with the planar coordinate system used in the data.
- **Coordinate grid:** The 1 km and 10 km grids are derived using Haversine distance anchored near the first SLF discovery site in Berks County, PA (lon −76 to −75, lat 40–41). Maintain this reference if modifying grid-rounding logic.
- **Biological year:** SLF's biological year runs May 1 – April 30. Code that filters or labels by year should respect `bio_year` (not `year`) by default, matching the default `year_type = "biological"` parameter.
- **iNaturalist integration:** iNaturalist data was removed from the bundled dataset in v4. Users may optionally supply their own download via `append_inat()`. The function uses a `safe_step()` helper to gracefully skip processing steps when expected columns are absent from the user's CSV.
- **Style:** Follow the existing tidyverse-style R code (pipe operators, `dplyr`/`tidyr` verbs, `ggplot2` for plotting). Suppress expected messages with `suppressMessages()` when loading dependencies inline.

## Data Schema

The primary dataset `lyde` (and its rarefied counterpart `lyde_10k`) is a data frame with the following columns:

| Column | Type | Description |
|---|---|---|
| `source` | character | Data source identifier |
| `year` | integer | Calendar year of collection |
| `bio_year` | integer | Biological year (May 1 – Apr 30) |
| `latitude` | numeric | Decimal degrees, WGS84 |
| `longitude` | numeric | Decimal degrees, WGS84 |
| `state` | character | 2-letter Census abbreviation |
| `lyde_present` | logical | SLF detected (including incidental records) |
| `lyde_established` | logical | Established population detected |
| `lyde_density` | character (ordinal) | `"Unpopulated"`, `"Low"`, `"Medium"`, `"High"` |
| `source_agency` | character | Agency/platform responsible for collection |
| `collection_method` | character | `"field_survey/management"` or `"individual_reporting"` |
| `pointID` | character | Unique identifier per data point |
| `rounded_longitude_10k` | numeric | Longitude snapped to 10 km grid centroid |
| `rounded_latitude_10k` | numeric | Latitude snapped to 10 km grid centroid |

## Important Notes for Agents

1. **Do not modify `NAMESPACE` directly.** It is fully managed by roxygen2 (`devtools::document()`).
2. **Do not expose or commit raw (non-anonymized) survey data.** The bundled `lyde` and `lyde_10k` datasets are already anonymized; any new data additions must follow the same anonymization procedure.
3. **Map functions can be slow.** `map_spread()` with `resolution = "1k"` operates on >658 000 rows. Tests and examples involving mapping should use `resolution = "10k"` or a small custom zoom region.
4. **The `download_data/` folder** contains versioned CSV exports and metadata for users who want the data without installing the package. Update it in sync with any data version bump.
5. **Coordinate rounding** uses `DescTools::RoundTo()` with a decimal-degree step derived from Haversine distances — not a simple fixed decimal rounding — to match the geographic grid. Do not substitute `round()`.
