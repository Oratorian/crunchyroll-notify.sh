
# Changelog

### 3.0.0 - 28.July.2025

### Added

- `--uninstall` argument to remove systemd service/timer, rsyslog, and logrotate integrations
- `--reinstall_syslog` argument to restore rsyslog config and force log recovery
- Timestamped and color-coded visual banners for uninstall clarity
- Automatic rsyslog log file recovery if deleted mid-run
- Fallback handling if log file is missing and rsyslog is not yet configured
- Dynamic `check_announced_file()` that auto-cleans old files
- Systemd `.service` and `.timer` support replacing cron
- Timer interval is now defined by `cron_time` in minutes (e.g. `"30"`) and used via `OnCalendar=*:0/30`

### Changed

- `install_cron_job()` fully replaced by `install_systemd_timer()` with OnCalendar interval control
- Early command handling (e.g. `--uninstall`) now prevents unnecessary module loading
- `01-logging.sh` no longer fails on first run or deleted logfiles; detection is deferred and guarded
- Log rotation now only installed if rsyslog is configured
- Removed dependency on static `announced_file` in config.json — now derived daily at runtime
- Reordered module load sequence: `check_system_requirements` now loads before config
- No more manual cleanup: announced titles are now stored in a daily auto-resetting temporary file

### Removed

- Old cronjob integration for announced file cleanup
- Static log file reference in `config.json


## 2.3.1 - 24.November.2024

### Fixed
- Fixed the announced_file handling logic to remove empty lines using sed. This ensures the announced file remains clean and prevents issues caused by blank entries in the RSS feed processing.
- Fixed check to log and return early if the provided keyword is empty.

## 2.3.0 - 18.November.2024

### Added
- Added new Config option for debug logging.
- Added logging to logfile in /var/log/crunchyroll-notify.log.
- Added Checks to install logrotate.d configuration to rotate logfile daily.
- The script now automatically checks the `config.json` file for missing keys and adds them with default values, ensuring compatibility with new features or updates.
  - Default values are only added if the section is empty or missing.

### Improvements
- Improved series checking logic, this now eliminates unnecessary processing for unmatched series titles.


## 2.2.1 - 01.November.2024

### Fixed
- Normalized line endings: Converted Windows-style line endings (CRLF) to Unix-style (LF) across all files.
- Relative Paths : Set a path environment so the script does not try to use relative paths, and fail to initialize.


## 2.2.0 - 12.October.2024
### Added
- Added function to check for `config.json` existence and automatically create one with default values if not present.
- Added functionality to exit script if `"Example Anime"` is detected in the config, prompting the user to set up the configuration manually.
- Moved several functions into individual modules for better organization and maintainability (e.g., `utilities.sh`, `system_requirements.sh`, `notification_manager.sh`).

### Changed
- Updated `config.json` structure to allow easier customization of notification services, anime titles, and system requirements.

## 2.1.3 - 6.October.2024
### Fixed
- Fixed automatic resetting of the `announced_series_titles` list using a cron job.

## 2.1.0 - 5.October.2024
### Added
- Added handling for Japanese anime titles without dub information by default.
- Switched to `config.json` for storing user settings, including `user_media_ids`, notification services, and announcement range.

### Changed
- Converted configuration variables to JSON for easier customization and better scalability.
- Introduced the ability to configure multiple notification services like Slack, IFTTT, Discord, etc., through JSON.

## 2.0.0 - 3.October.2024
### Changed
- Major refactor to introduce support for treating Japanese anime titles as the default language.
- Script now assumes titles without explicit dub information are in Japanese by default.

### Fixed
- Fixed issue where dubless titles were being skipped, ensuring proper processing of Japanese anime releases.

## 1.4.0 - 27.September.2024
### Added
- Added support for parsing Crunchyroll RSS feed with multiple notification services.

### Changed
- Updated the notification function to allow sending alerts to multiple services based on user configuration.

## 1.3.0 - 26.September.2024
### Added
- Modularized notifications, splitting functions into separate methods for Email, Pushover, IFTTT, Slack, and Discord.
- Added flexible notification service configuration within the script.

## 1.2.1 - 24.September.2024
### Fixed
- Fixed an issue with the cron job installation where it wouldn't detect already installed cron jobs and kept installing new ones.

## 1.2.0 - 22.September.2024
### Added
- Added logging configuration options for file, console, or both.
- Added support for user-configurable time range control with the `$announceRange` variable (default set to 300 seconds).
- Introduced support for cron job installation to reset the announcement list daily.

### Changed
- Moved logging configurations to global variables.

### Fixed
- Resolved an issue where dubless titles were incorrectly skipped in RSS feed processing.

## 1.1.10 - 21.September.2024
### Changed
- Improved handling for missing or unspecified dub information in RSS feed items.

## 1.1.9 - 14.September.2024
### Added
- Introduced global variable support for allowed dubs.
- Added functionality to filter RSS entries based on language dubs, excluding English dubs while allowing others (e.g., German).

### Changed
- Updated the script to handle announcements based on dub information in titles.

## 1.0.0 - 27.August.2024
### Added
- Initial release of the `crunchyroll-notify.sh`, with basic functions.
