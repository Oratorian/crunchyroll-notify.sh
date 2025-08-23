# 📦 Crunchyroll Notify Docker Container

[![Docker Build](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/actions/workflows/docker-publish.yml)

Monitor Crunchyroll RSS feed for new anime episodes and automatically send notifications via Discord, Slack, Pushover, IFTTT, or email.

## 🚀 Quick Start

```bash
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

## 🏷️ Available Tags

| Tag | Description | Stability |
|-----|-------------|-----------|
| `latest` | Latest stable release | ✅ Recommended |
| `v1.2.3` | Specific version | ✅ Production |
| `main` | Latest development | ⚠️ Testing |

## 🔧 Key Features

- **Multi-platform**: `linux/amd64`, `linux/arm64` (Raspberry Pi, Apple Silicon)
- **Secure**: Non-root execution with PUID/PGID support
- **Flexible scheduling**: Cron expressions or simple numeric intervals
- **Multiple notifications**: Discord, Slack, Pushover, IFTTT, Email
- **Timezone support**: Set your local timezone with `TZ` variable

## ⚙️ Essential Environment Variables

| Variable | Example | Description |
|----------|---------|-------------|
| `PUID` | `1000` | User ID for file permissions |
| `PGID` | `1000` | Group ID for file permissions |
| `TZ` | `America/New_York` | Timezone |
| `CRON_TIME` | `15` or `"*/15 * * * *"` | Check interval |
| `ANIMES` | `"Naruto=english;One Piece=sub"` | Anime list to monitor |

## 🔔 Notification Setup

### Discord
```bash
-e NOTIFY_DISCORD=true \
-e DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..." \
```

### Slack  
```bash
-e NOTIFY_SLACK=true \
-e SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..." \
```

### Pushover
```bash
-e NOTIFY_PUSHOVER=true \
-e PUSHOVER_USER_KEY="your_user_key" \
-e PUSHOVER_APP_TOKEN="your_app_token" \
```

## 📋 Docker Compose Example

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
      - DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/YOUR/WEBHOOK
      - ANIMES=Attack on Titan=english;Demon Slayer=sub;One Piece=
    volumes:
      - ./config:/app/cfg:rw
```

## 🛡️ Security & Trust

✅ **Signed containers** with GitHub's certificate  
✅ **Build provenance** attestation included  
✅ **Non-root execution** with user ID mapping  
✅ **Open source** - inspect the code anytime  
✅ **Automated builds** from source code only  

## 📚 Complete Documentation

- **[Complete Docker Guide](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/blob/main/DOCKER.md)** - Full environment variables reference
- **[Source Code](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME)** - View the repository
- **[Issues & Support](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/issues)** - Get help

---

**License**: GPL-3.0 | **Platforms**: linux/amd64, linux/arm64 | **Registry**: GitHub Container Registry