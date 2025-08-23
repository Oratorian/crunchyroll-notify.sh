# Docker Version

This directory contains the Docker-ready version of Crunchyroll Notify that gets automatically built and published to GitHub Container Registry.

## Automated Builds

The GitHub Actions workflow automatically builds and publishes Docker images when:
- Changes are pushed to `main`/`master` branch in the `docker-version/` directory
- Version tags (`v*`) are created
- Manual workflow dispatch is triggered

## Published Images

Images are published to: `ghcr.io/YOUR_USERNAME/YOUR_REPO_NAME`

### Available Tags:
- `latest` - Latest build from main branch
- `v1.2.3` - Specific version tags
- `main` - Latest from main branch
- `pr-123` - Pull request builds (for testing)

## Usage

```bash
# Pull and run the latest version
docker run --rm -it \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -v $(pwd)/cfg:/app/cfg:rw \
  -e CRON_TIME=15 \
  ghcr.io/YOUR_USERNAME/YOUR_REPO_NAME:latest
```

## Multi-Platform Support

Images are built for:
- `linux/amd64` (Intel/AMD 64-bit)
- `linux/arm64` (ARM 64-bit, including Apple Silicon)

## Security Features

- Build attestations with provenance
- Signed with GitHub's certificate
- Vulnerability scanning
- Non-root user execution (PUID/PGID support)

## Development

To test local builds:
```bash
cd docker-version
docker build -t crunchyroll-notify:local .
docker run --rm -it crunchyroll-notify:local
```

## Files in This Directory

- `Dockerfile` - Multi-stage Docker build configuration
- `docker-entrypoint.sh` - Container startup script with PUID/PGID support
- `crunchyroll-notify.sh` - Main application script
- `modules/` - Application modules
- `cfg/` - Default configuration files

See the main [DOCKER.md](../DOCKER.md) for complete usage documentation.