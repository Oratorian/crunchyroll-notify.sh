# Crunchyroll Notify

**crunchyroll-notify.sh** is a modular Bash script that checks the Crunchyroll calendar RSS feed for new anime releases matching titles you define in a `config.json` file. When a match is found, it sends notifications via various services like Discord, Slack, Email, IFTTT, Pushover, or simply echoes to the terminal.

It is intended for self-hosted use on Linux systems and runs well from `cron`. Built for extensibility and maintainability, it is split into modular components under the `modules/` directory.

---

## Features

* 🔁 Periodically checks Crunchyroll's calendar feed
* 🔍 Filters titles by user-defined matches
* 🌐 Multi-service notifications: Discord, Email, Slack, IFTTT, Pushover
* ⚙️ Simple configuration via `config.json`
* 📜 Automatic log handling and rotation via `rsyslog` and `logrotate`
* 💡 Smart cron installer and file validation
* 📦 Modular architecture
* 💬 Supports dub language filtering

---

## Installation

1. Clone or copy the script and modules:

```bash
chmod +x crunchyroll-notify.sh
```

2. Run once to generate a starter config:

```bash
./crunchyroll-notify.sh
```

3. Edit the config file:

```bash
nano cfg/config.json
```

4. Set up cron (done automatically unless disabled):

```bash
crontab -e
```

5. To manually reinstall log routing:

```bash
./crunchyroll-notify.sh --reinstall_syslog
```

6. To cleanly uninstall system integration:

```bash
./crunchyroll-notify.sh --uninstall
```

---

## Usage

```bash
./crunchyroll-notify.sh
```

You’ll see color-coded output and log entries appear in `/var/log/crunchyroll-notify.log` if `rsyslog` is configured correctly.

---

## Module System

Modules are named using a Linux-style numeric prefix for strict load ordering:

```
01-logging.sh
02-get_config.sh
03-check_config.sh
04-set_config.sh
05-check_system_requirements.sh
06-utilities.sh
07-notification_manager.sh
08-check_title.sh
09-get_showid.sh
```

Each module sets a variable like `logging_loaded=true` at the end.

After all modules are sourced, a validation check ensures all required modules were loaded correctly. If any module fails to load or does not set its `_loaded` flag, the script exits immediately with an error.


## Project Layout

```text
.
├── CHANGELOG.md
├── README.md
├── crunchyroll-notify.sh    # Main entry point
├── cfg                     # Configuration directory
│   └── config.json
└── modules                 # Modular components in load order
    ├── 01-logging.sh
    ├── 02-check_system_requirements.sh
    ├── 03-get_config.sh
    ├── 04-check_config.sh
    ├── 05-set_config.sh
    ├── 06-utilities.sh
    ├── 07-notification_manager.sh
    ├── 08-check_title.sh
    └── 09-get_showid.sh
```

## Changelog

### 3.0.0 - 28.July.2025

### Fixed
- Full episode titles are now persisted (not just series names), so each EP (e.g. “SomeAnime – EP5”) is stored and recognized individually

### Added

- `--uninstall` argument to remove systemd service/timer, rsyslog, and logrotate integrations
- `--reinstall_syslog` argument to restore rsyslog config and force log recovery
- Timestamped and color-coded visual banners for uninstall clarity
- Automatic rsyslog log file recovery if deleted mid-run
- Fallback handling if log file is missing and rsyslog is not yet configured
- Dynamic `check_announced_file()` that auto-cleans old files
- Systemd `.service` and `.timer` support replacing cron
- Timer interval is now defined by `cron_time` in minutes (e.g. `"30"`) and used via `OnCalendar=*:0/30`
- Batch announcement mode: collects all new episodes into a `new_announcements` array during feed parsing, then performs notifications in a single pass
- `matches_user_show()` helper function to consolidate and simplify the user-shows matching logic

### Changed

- `install_cron_job()` fully replaced by `install_systemd_timer()` with OnCalendar interval control
- Early command handling (e.g. `--uninstall`) now prevents unnecessary module loading
- `01-logging.sh` no longer fails on first run or deleted logfiles; detection is deferred and guarded
- Log rotation now only installed if rsyslog is configured
- Removed dependency on static `announced_file` in config.json — now derived daily at runtime
- Reordered module load sequence: `check_system_requirements` now loads before config
- No more manual cleanup: announced titles are now stored in a daily auto-resetting temporary file
- Refactored announcement loop into a two-phase workflow (collect → announce), replacing on-the-fly notifications
- Replaced inline `for … user_shows` loop with the new `matches_user_show()` call for clarity and maintainability

### Removed

- Old cronjob integration for announced file cleanup
- Static log file reference in `config.json
- Inline episode matching code (now handled by `matches_user_show()`)
- Legacy behavior that wrote only series names to the announced cache
---

### 2.3.1 - 24.November.2024

#### Fixed

* Removed empty lines in announced file
* Handled empty keyword check early

### 2.3.0 - 18.November.2024

#### Added

* Debug logging in config
* Logrotate setup
* Config key auto-patching

#### Improved

* Title filtering efficiency
---

### 📄 Full Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and details.
---

## License

GPL-3.0 License. Credit: Oration "Mahesvara" (@Oratorian)

---

## Support

Feel free to fork or contribute improvements. Bug reports welcome via GitHub or direct message.