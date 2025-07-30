# Crunchyroll Notify

**crunchyroll-notify.sh** is momentary not working.

# 30.07.2025 - New Method discovered.

## [Unreleased]

### Added
- Introduced a reliable new method for fetching and parsing Crunchyroll's simulcast release calendar.
  - Uses FlareSolverr or Bypassr to bypass Cloudflare bot protection.
  - Leverages `csplit` to split fetched HTML into per-episode blocks.
  - Parses cleanly with `htmlq` using CSS selectors and XPath to extract show titles, release times, thumbnails, and metadata.

### Changed
- Project is now Docker-only to streamline setup with required headless-solvers (FlareSolverr/Bypassr).

### Notes
- Legacy RSS support is considered deprecated due to Crunchyroll discontinuation.
- Internal rework in progress to integrate new scraping pipeline with existing notification system.
