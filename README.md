# Crunchyroll Notify

[![Docker Build](https://github.com/Oratorian/crunchyroll_notify.sh/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/Oratorian/crunchyroll-notify.sh/actions/workflows/docker-publish.yml)

**crunchyroll-notify.sh** is a Bash script that monitors the Crunchyroll calendar RSS feed for new anime releases matching titles you define in `config.json`. When a match is found, it sends notifications via various services like Discord, Slack, Email, IFTTT, Pushover, or simply echoes to the terminal.

It is intended for self-hosted use on Linux systems and runs well with a `systemd` timer or Docker. Built for extensibility and maintainability, it is split into modular components under the `modules/` directory.

---

## 🚀 Quick Start

### 🐳 Docker (Recommended)

```bash
# Pull from GitHub Container Registry
docker pull ghcr.io/Oratorian/chrunchyroll_notify.sh:latest

# Run with basic configuration
docker run --rm -it \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -v $(pwd)/cfg:/app/cfg:rw \
  -e CRON_TIME=15 \
  -e ANIMES="Attack on Titan=english;Demon Slayer=sub" \
  -e NOTIFY_DISCORD=true \
  -e DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR/WEBHOOK" \
  ghcr.io/YOUR_USERNAME/YOUR_REPO_NAME:latest
```

### 🖥️ Native Installation

```bash
# 1. Make script executable
chmod +x crunchyroll-notify.sh

# 2. Generate starter config
./crunchyroll-notify.sh

# 3. Edit configuration
nano cfg/config.json

# 4. Install system integration (systemd, logging)
./crunchyroll-notify.sh --install
```

---

## 📋 Features

* 🔁 **Periodic monitoring** - Checks Crunchyroll's calendar feed automatically
* 🔍 **Smart filtering** - Matches user-defined anime titles with flexible dub support
* 🌐 **Multi-service notifications** - Discord, Slack, Email, IFTTT, Pushover, Echo
* ⚙️ **Simple configuration** - JSON-based config with environment variable overrides
* 📜 **Comprehensive logging** - Automatic log handling and rotation
* 💡 **System integration** - systemd timer support with smart installer
* 📦 **Modular architecture** - Clean, maintainable code structure
* 🐳 **Docker ready** - Multi-platform containers with PUID/PGID support
* 🕒 **Timezone aware** - Configurable timezone support
* 💬 **Language filtering** - Supports dub language preferences (english, spanish, etc.)

---

## 🐳 Docker Usage

### Environment Variables

#### Core Configuration
| Variable | Default | Description | Example |
|----------|---------|-------------|---------|
| `PUID` | `1000` | User ID for file permissions | `PUID=$(id -u)` |
| `PGID` | `1000` | Group ID for file permissions | `PGID=$(id -g)` |
| `TZ` | `UTC` | Timezone for logging and scheduling | `TZ=America/New_York` |
| `CRON_TIME` | `*/20 * * * *` | Schedule: number (minutes) or cron format | `CRON_TIME=15` or `CRON_TIME="*/15 * * * *"` |

#### Application Settings
| Variable | Config Path | Description | Example |
|----------|-------------|-------------|---------|
| `ANNOUNCERANGE` | `announcerange` | Time range for announcements (minutes) | `ANNOUNCERANGE=60` |
| `DEBUG_ENABLED` | `debug.enabled` | Enable debug logging | `DEBUG_ENABLED=true` |
| `EMAIL_RECIPIENT` | `email_recipient` | Email address for notifications | `EMAIL_RECIPIENT=user@example.com` |

#### Notification Services
| Variable | Config Path | Description | Example |
|----------|-------------|-------------|---------|
| `NOTIFY_EMAIL` | `notification_services.email` | Enable email notifications | `NOTIFY_EMAIL=true` |
| `NOTIFY_PUSHOVER` | `notification_services.pushover` | Enable Pushover notifications | `NOTIFY_PUSHOVER=true` |
| `NOTIFY_IFTTT` | `notification_services.ifttt` | Enable IFTTT notifications | `NOTIFY_IFTTT=true` |
| `NOTIFY_SLACK` | `notification_services.slack` | Enable Slack notifications | `NOTIFY_SLACK=true` |
| `NOTIFY_DISCORD` | `notification_services.discord` | Enable Discord notifications | `NOTIFY_DISCORD=true` |
| `NOTIFY_ECHO` | `notification_services.echo` | Enable terminal echo | `NOTIFY_ECHO=true` |

#### Service Credentials

**Pushover:**
| Variable | Config Path | Description | Example |
|----------|-------------|-------------|---------|
| `PUSHOVER_USER_KEY` | `pushover.user_key` | Pushover user key | `PUSHOVER_USER_KEY=your_user_key` |
| `PUSHOVER_APP_TOKEN` | `pushover.app_token` | Pushover app token | `PUSHOVER_APP_TOKEN=your_app_token` |

**IFTTT:**
| Variable | Config Path | Description | Example |
|----------|-------------|-------------|---------|
| `IFTTT_EVENT` | `ifttt.event` | IFTTT event name | `IFTTT_EVENT=crunchyroll_notify` |
| `IFTTT_KEY` | `ifttt.key` | IFTTT webhook key | `IFTTT_KEY=your_ifttt_key` |

**Slack:**
| Variable | Config Path | Description | Example |
|----------|-------------|-------------|---------|
| `SLACK_WEBHOOK_URL` | `slack.webhook_url` | Slack webhook URL | `SLACK_WEBHOOK_URL=https://hooks.slack.com/...` |

**Discord:**
| Variable | Config Path | Description | Example |
|----------|-------------|-------------|---------|
| `DISCORD_WEBHOOK_URL` | `discord.webhook_url` | Discord webhook URL | `DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...` |

#### Anime Configuration
| Variable | Description | Example |
|----------|-------------|---------|
| `ANIMES` | Semicolon-separated anime list with comma-separated dubs | `ANIMES="Naruto=sub;One Piece=english,spanish"` |

**Note**: Each anime entry uses format `"Anime Title=dub1,dub2,dub3"` where dubs are comma-separated.

### Docker Examples

#### Basic Setup
```bash
docker run --rm -it \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -v $(pwd)/cfg:/app/cfg:rw \
  ghcr.io/YOUR_USERNAME/YOUR_REPO_NAME:latest
```

#### Production with Docker Compose
```yaml
version: '3.8'
services:
  crunchyroll-notify:
    image: ghcr.io/YOUR_USERNAME/YOUR_REPO_NAME:latest
    container_name: crunchyroll-notify
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - CRON_TIME=30
      - DEBUG_ENABLED=false
      - NOTIFY_DISCORD=true
      - DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/your/webhook
      - ANIMES=Attack on Titan=english;Demon Slayer=sub;One Piece=
    volumes:
      - ./config:/app/cfg:rw
```

#### Complete Configuration
```bash
docker run -d \
  --name crunchyroll-notify \
  --restart unless-stopped \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -e TZ=Europe/London \
  -e CRON_TIME="*/15 * * * *" \
  -e DEBUG_ENABLED=false \
  -e ANNOUNCERANGE=120 \
  -e NOTIFY_DISCORD=true \
  -e NOTIFY_PUSHOVER=true \
  -e DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/your/webhook" \
  -e PUSHOVER_USER_KEY="your_user_key" \
  -e PUSHOVER_APP_TOKEN="your_app_token" \
  -e ANIMES="Demon Slayer=sub;My Hero Academia=english;One Piece=" \
  -v $(pwd)/cfg:/app/cfg:rw \
  ghcr.io/YOUR_USERNAME/YOUR_REPO_NAME:latest
```

### CRON_TIME Format Options

**Numeric Format (Minutes):**
| Value | Description | Equivalent Cron |
|-------|-------------|----------------|
| `1` | Every 1 minute | `*/1 * * * *` |
| `5` | Every 5 minutes | `*/5 * * * *` |
| `15` | Every 15 minutes | `*/15 * * * *` |
| `30` | Every 30 minutes | `*/30 * * * *` |

**Full Cron Format:**
| Schedule | Description |
|----------|-------------|
| `*/15 * * * *` | Every 15 minutes |
| `0 * * * *` | Every hour |
| `0 9 * * *` | Daily at 9 AM |
| `0 9 * * 1-5` | Weekdays at 9 AM |
| `0 9,21 * * *` | Daily at 9 AM and 9 PM |

---

## 🖥️ Native Installation & Usage

### Installation Steps

1. **Make script executable:**
```bash
chmod +x crunchyroll-notify.sh
```

2. **Generate starter config:**
```bash
./crunchyroll-notify.sh
```

3. **Edit configuration:**
```bash
nano cfg/config.json
```

4. **Install system integration:**
```bash
./crunchyroll-notify.sh --install
```

5. **Optional - Reinstall logging:**
```bash
./crunchyroll-notify.sh --reinstall_syslog
```

6. **Clean uninstall:**
```bash
./crunchyroll-notify.sh --uninstall
```

### Manual Usage

⚠️ **For debugging only** - Stop systemd timer first:
```bash
systemctl stop crunchyroll-notify.timer
./crunchyroll-notify.sh
systemctl start crunchyroll-notify.timer
```

You'll see color-coded output and log entries in `/var/log/crunchyroll-notify.log`.

---

## 🏗️ Architecture

### Module System

Modules load in strict numerical order with validation:

```
01-logging.sh           # Color-coded logging with syslog integration
02-check_config.sh      # Configuration validation and defaults
03-get_config.sh        # JSON configuration parsing utilities
03-set_config.sh        # Configuration variable assignment
06-utilities.sh         # HTML decoding, time range checks, file management
07-notification_manager.sh # Multi-service notification handlers
08-check_title.sh       # Special character escaping for title matching
```

Each module sets a `*_loaded=true` flag for validation.

### Project Structure

```text
.
├── CHANGELOG.md             # Version history and changes
├── README.md               # This file
├── crunchyroll-notify.sh   # Main entry point
├── cfg/                    # Configuration directory
│   └── config.json         # Main configuration file
├── modules/                # Modular components (load order)
│   ├── 01-logging.sh
│   ├── 02-check_config.sh
│   ├── 03-get_config.sh
│   ├── 03-set_config.sh
│   ├── 06-utilities.sh
│   ├── 07-notification_manager.sh
│   └── 08-check_title.sh
├── docker-version/         # Docker build context
└── .github/                # GitHub Actions workflows
    └── workflows/
        └── docker-publish.yml
```

### Data Flow

1. **Module Loading**: Load and validate all modules in order
2. **Configuration**: Parse config.json and load user anime list
3. **RSS Processing**: Fetch and validate Crunchyroll RSS feed
4. **Episode Parsing**: Extract series, episodes, dates, descriptions
5. **Filtering**: Check against user preferences and dub requirements
6. **Time Validation**: Ensure episodes are within announcement range
7. **Batch Collection**: Collect new episodes into announcement array
8. **Notifications**: Send notifications for all new episodes
9. **State Update**: Update announced file with new episode titles

---

## 🔧 Configuration

### config.json Structure

```json
{
  "cron_time": "*/15 * * * *",
  "animes": {
    "Attack on Titan": "english",
    "Demon Slayer": "sub",
    "One Piece": "english,spanish",
    "Naruto": ""
  },
  "notification_services": {
    "discord": true,
    "slack": false,
    "pushover": false,
    "email": false,
    "ifttt": false,
    "echo": true
  },
  "announcerange": 60,
  "announced_file_dir": "/tmp",
  "debug": {
    "enabled": false
  },
  "discord": {
    "webhook_url": "https://discord.com/api/webhooks/YOUR/WEBHOOK"
  }
}
```

### Key Configuration Options

- **cron_time**: Schedule format (numeric minutes or full cron)
- **animes**: Anime titles with comma-separated dub preferences
- **announcerange**: Time window in minutes for announcements
- **notification_services**: Toggle each notification method
- **debug.enabled**: Enable verbose logging

---

## 🚨 Troubleshooting

### Docker Issues

**Permission Denied:**
```bash
# Use PUID/PGID
docker run -e PUID=$(id -u) -e PGID=$(id -g) ...

# Or fix host permissions
chown -R $(id -u):$(id -g) ./cfg
```

**No Notifications:**
1. Check anime list: `ANIMES="Anime Name=sub"`
2. Verify webhook URLs
3. Enable debug: `DEBUG_ENABLED=true`
4. Increase range: `ANNOUNCERANGE=999`

### Native Issues

**systemd Timer:**
```bash
# Check status
systemctl status crunchyroll-notify.timer

# View logs
journalctl -u crunchyroll-notify.service -f

# Restart timer
systemctl restart crunchyroll-notify.timer
```

**Configuration:**
```bash
# Validate JSON
jq . cfg/config.json

# Check permissions
ls -la cfg/config.json

# Reset config
rm cfg/config.json && ./crunchyroll-notify.sh
```

---

## 🛡️ Security & Performance

### Security Best Practices
- **Non-root execution**: Docker runs as mapped user via PUID/PGID
- **Webhook protection**: Keep webhook URLs private and secure
- **Network isolation**: Use custom Docker networks in production
- **Resource limits**: Set memory/CPU limits for containers
- **Regular updates**: Keep base images and dependencies updated

### Performance Tips
- **Reasonable intervals**: Minimum 5 minutes recommended (avoid rate limiting)
- **Targeted announcements**: Use appropriate time ranges to prevent spam
- **Resource monitoring**: Monitor container resource usage in production
- **Log management**: Configure log rotation for long-running instances

---

## 🔗 Links & Resources

- **📋 [Changelog](CHANGELOG.md)** - Version history and detailed changes
- **🐳 [GitHub Packages](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/pkgs/container/YOUR_REPO_NAME)** - Pre-built Docker images
- **⚡ [GitHub Actions](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/actions)** - Automated builds and tests
- **🐛 [Issues](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/issues)** - Bug reports and feature requests
- **💬 [Discussions](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/discussions)** - Community support and ideas

---

## 📄 License

GPL-3.0 License. Original work by **Oration "Mahesvara"** ([@Oratorian](https://github.com/Oratorian))

---

## 🤝 Support & Contributing

- **Bug Reports**: Please use GitHub Issues with detailed information
- **Feature Requests**: Submit via GitHub Issues with clear use cases
- **Pull Requests**: Welcome! Please follow existing code style
- **Documentation**: Help improve docs and examples

For questions or support, feel free to open a GitHub Discussion or Issue.

---

*Happy anime watching! 🍿*