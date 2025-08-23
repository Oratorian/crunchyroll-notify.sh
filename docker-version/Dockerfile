FROM debian:bookworm-slim

# OCI Labels for better package display
LABEL org.opencontainers.image.title="Crunchyroll Notify"
LABEL org.opencontainers.image.description="Monitor Crunchyroll RSS feed for new anime episodes and send notifications via Discord, Slack, Pushover, IFTTT, or email"
LABEL org.opencontainers.image.vendor="Crunchyroll Notify Project"
LABEL org.opencontainers.image.licenses="GPL-3.0"
LABEL org.opencontainers.image.source="https://github.com/Oratorian/crunchyroll-notify.sh"
LABEL org.opencontainers.image.documentation="https://github.com/Oratorian/crunchyroll-notify.sh/blob/main/README.md"

ENV container=docker
WORKDIR /app

# Install required packages (removed cron, rsyslog, logrotate since we use custom runner)
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    xmlstarlet \
    bash \
    gosu \
    tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /app/cfg /app/modules /tmp

# Copy application files
COPY crunchyroll-notify.sh /app/
COPY modules/ /app/modules/
COPY cfg/ /app/cfg/
COPY docker-entrypoint.sh /usr/local/bin/

# Set proper permissions
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /app/crunchyroll-notify.sh \
    && chmod +x /app/modules/*.sh

# Create non-root user for security (UID 1000 for compatibility)
RUN groupadd -r crunchyroll -g 1000 && useradd -r -u 1000 -g crunchyroll crunchyroll \
    && chown -R crunchyroll:crunchyroll /app

# Make config mountable
VOLUME ["/app/cfg"]


ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["crunch-runner"]
