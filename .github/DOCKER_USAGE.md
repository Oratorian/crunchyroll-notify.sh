# Docker Container Usage

[![Docker Build](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/actions/workflows/docker-publish.yml)

## Quick Start

```bash
# Pull the latest image
docker pull ghcr.io/YOUR_USERNAME/YOUR_REPO_NAME:latest

# Run with basic configuration
docker run --rm -it \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -v $(pwd)/cfg:/app/cfg:rw \
  -e CRON_TIME=15 \
  -e ANIMES="Your Anime=english" \
  ghcr.io/YOUR_USERNAME/YOUR_REPO_NAME:latest
```

## Available Image Tags

| Tag | Description | Example |
|-----|-------------|---------|
| `latest` | Latest stable release from main branch | `ghcr.io/owner/repo:latest` |
| `v1.2.3` | Specific version releases | `ghcr.io/owner/repo:v1.2.3` |
| `main` | Latest from main branch (same as latest) | `ghcr.io/owner/repo:main` |
| `pr-123` | Pull request builds for testing | `ghcr.io/owner/repo:pr-123` |

## Docker Compose Example

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
      - ANIMES=Attack on Titan=english;Demon Slayer=sub
    volumes:
      - ./config:/app/cfg:rw
```

## Security & Trust

All images are:
- ✅ Built automatically from source code
- ✅ Signed with GitHub's certificate  
- ✅ Include build provenance attestation
- ✅ Scanned for vulnerabilities
- ✅ Run as non-root user

## Platform Support

Images support multiple architectures:
- `linux/amd64` - Intel/AMD 64-bit processors
- `linux/arm64` - ARM 64-bit processors (Raspberry Pi 4, Apple Silicon, etc.)

Docker will automatically pull the correct architecture for your system.

## Verification

Verify the image signature and provenance:
```bash
# Install cosign
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign

# Verify the image (replace with actual image)
cosign verify ghcr.io/YOUR_USERNAME/YOUR_REPO_NAME:latest \
  --certificate-identity-regexp="https://github.com/YOUR_USERNAME/YOUR_REPO_NAME" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com"
```

## Complete Documentation

See [DOCKER.md](../DOCKER.md) for complete environment variable reference and usage examples.