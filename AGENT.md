# AGENT.md

Guidance for AI coding agents working in this repository.

## Project Overview

`lydemapr` is an **R package** (not a general application) that provides an
aggregated, anonymized dataset of Spotted Lanternfly (*Lycorma delicatula*,
SLF) spread across the United States, along with functions to summarize and
map the data.

- Type: R package (uses `devtools` / `roxygen2` conventions)
- Version: 4.1.0 (see `DESCRIPTION`)
- License: CC-BY
- Maintainers: Seba De Bona, Matt Helmus
- Docs site: https://ieco-lab.github.io/lydemapr/ (built via pkgdown)
- Related publication: De Bona et al. 2023, NeoBiota

## Repository Structure

- `R/` — package source code (exported functions), e.g. `map_spread.R`,
  `map_alphahull.R`, `map_yearly.R`, `lyde.R`, `lyde_summary.R`,
  `alphahull_sf.R`, `append_inat.R`, `sampling_effort.R`, `scale_selection.R`.
- `data/` — package datasets (`.rda` files), loaded lazily (`LazyData: true`).
- `man/` — **auto-generated** documentation from roxygen2 comments. Do not
  hand-edit; regenerate with `devtools::document()`.
- `NAMESPACE` — **auto-generated** by roxygen2. Do not hand-edit.
- `vignettes/` — package vignette(s), built with `knitr`/`rmarkdown`.
- `download_data/` — versioned, user-facing data export folders (e.g.
  `v4.1.0_2025/`, `older_data_versions/`), each tied to a released version and
  archived on Zenodo. Treat as published releases; avoid casual edits.
- `DESCRIPTION` — package metadata, dependencies (`Imports`, `Suggests`).
- `_pkgdown.yml` — configuration for the pkgdown documentation site.
- `.github/workflows/pkgdown.yaml` — CI workflow that builds and deploys the
  pkgdown site on pushes to the default branch. There is currently no
  `R CMD check` CI workflow.
- `lydemapr.Rproj` — RStudio project file.

## Common Commands

Run these from an R console with `devtools` installed:

- Load package for interactive development: `devtools::load_all()`
- Regenerate docs/NAMESPACE from roxygen comments: `devtools::document()`
- Install locally (with vignettes): `devtools::install(build_vignettes = TRUE)`
- Run package checks: `devtools::check()`
- Build the pkgdown site locally: `pkgdown::build_site()`

## Coding Conventions

- Every exported function in `R/` must have a roxygen2 (`#'`) documentation
  block above it (title, `@param`, `@return`, `@export`, etc.).
- Follow the tidyverse style already used throughout `R/` (the package
  imports `tidyverse`, `dplyr`, `purrr`, `ggplot2`, etc.).
- Spatial functions rely on `sf`, `sp`, `raster`, `geosphere`, `tigris`,
  and `alphahull` — keep new spatial code consistent with existing patterns
  in files like `map_alphahull.R` and `alphahull_sf.R`.
- After changing any function signature, roxygen comments, or exports, run
  `devtools::document()` so `man/` and `NAMESPACE` stay in sync. Do not edit
  those generated files directly.

## Data Handling Caution

- The core value of this package is that survey data has been **aggregated
  and anonymized**. Do not add code or data that could re-identify raw,
  non-aggregated, or location-sensitive survey records.
- `download_data/` folders correspond to published, versioned data releases
  (also archived on Zenodo). Avoid modifying existing released folders;
  new data releases should be added as new versioned subfolders.

## Before Submitting Changes (Pull Requests)

- If you changed anything in `R/`, run `devtools::document()` and
  `devtools::check()` and include the regenerated `man/`/`NAMESPACE` changes.
- Update the version in `DESCRIPTION` (and relevant docs/citation info) if
  the change affects package functionality or data content.
- Do not modify `.github/workflows/pkgdown.yaml` unless the change is
  specifically about documentation site deployment.
