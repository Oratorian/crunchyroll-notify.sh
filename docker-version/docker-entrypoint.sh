#!/bin/bash
set -e

# Set working directory and ensure paths are properly quoted
WORKDIR="/app"
CONFIG_FILE="$WORKDIR/cfg/config.json"
TMP_CFG="$WORKDIR/cfg/tmp_config.json"

# Handle PUID/PGID for user management
PUID=${PUID:-1000}
PGID=${PGID:-1000}

# Handle timezone
if [[ -n "$TZ" ]]; then
    echo "[INFO] Setting timezone to: $TZ"
    if [[ -f "/usr/share/zoneinfo/$TZ" ]]; then
        ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime
        echo "$TZ" > /etc/timezone
    else
        echo "[WARNING] Timezone '$TZ' not found, using default"
    fi
fi

# Only modify user if running as root and PUID/PGID are set
if [[ $(id -u) == "0" ]]; then
  echo "[INFO] Setting up user with PUID=${PUID} PGID=${PGID}"

  # Modify the crunchyroll user to match PUID/PGID
  groupmod -o -g "$PGID" crunchyroll 2>/dev/null || echo "[INFO] Group already has GID $PGID"
  usermod -o -u "$PUID" crunchyroll 2>/dev/null || echo "[INFO] User already has UID $PUID"

  # Ensure directories exist and fix ownership
  mkdir -p "$WORKDIR/cfg" /tmp
  chown -R crunchyroll:crunchyroll "$WORKDIR" 2>/dev/null || echo "[WARNING] Could not change ownership of some directories"
else
  echo "[INFO] Running as non-root user $(id -un) (UID: $(id -u), GID: $(id -g))"
  # Ensure directories exist
  mkdir -p "$WORKDIR/cfg" /tmp
fi

# Change to working directory
cd "$WORKDIR"

# --- Init config.json if missing ---
if [ ! -f "$CONFIG_FILE" ]; then
  echo "[INFO] config.json missing. Running once to initialize..."
  ./crunchyroll-notify.sh --install || true
fi

# --- Remove user_trap if present ---
echo "[INFO] Removing user_trap key from config.json (if present)..."
if jq 'del(.user_trap)' "$CONFIG_FILE" >"$TMP_CFG" 2>/dev/null; then
  mv "$TMP_CFG" "$CONFIG_FILE"
else
  echo "[WARNING] Failed to process config.json with jq, continuing anyway..."
fi

# --- Parse ANIMES if present ---
if [ -n "$ANIMES" ]; then
  echo "[INFO] Parsing ANIMES override..."
  cp "$CONFIG_FILE" "$TMP_CFG"
  echo "$ANIMES" | tr ';' '\n' | while IFS='=' read -r title dub; do
    if [ -n "$title" ] && [ -n "$dub" ]; then
      if jq --arg title "$title" --arg dub "$dub" \
        '.animes[$title] = $dub' "$TMP_CFG" >"$TMP_CFG.tmp" 2>/dev/null; then
        mv "$TMP_CFG.tmp" "$TMP_CFG"
      else
        echo "[WARNING] Failed to update anime config for: $title"
      fi
    fi
  done
  mv "$TMP_CFG" "$CONFIG_FILE"
fi

# --- Apply ENV overrides ---
declare -A map_simple=(
  [CRON_TIME]=cron_time
  [ANNOUNCERANGE]=announcerange
  [ANNOUNCED_FILE]=announced_file
  [EMAIL_RECIPIENT]=email_recipient
  [DEBUG_ENABLED]=debug.enabled
)

declare -A map_nested=(
  [PUSHOVER_USER_KEY]=pushover.user_key
  [PUSHOVER_APP_TOKEN]=pushover.app_token
  [IFTTT_EVENT]=ifttt.event
  [IFTTT_KEY]=ifttt.key
  [SLACK_WEBHOOK_URL]=slack.webhook_url
  [DISCORD_WEBHOOK_URL]=discord.webhook_url
)

declare -A map_notifiers=(
  [NOTIFY_EMAIL]=notification_services.email
  [NOTIFY_PUSHOVER]=notification_services.pushover
  [NOTIFY_IFTTT]=notification_services.ifttt
  [NOTIFY_SLACK]=notification_services.slack
  [NOTIFY_DISCORD]=notification_services.discord
  [NOTIFY_ECHO]=notification_services.echo
)

jq_args=()
jq_vars=()

for var in "${!map_simple[@]}"; do
  val="${!var}"
  if [ -n "$val" ]; then
    jq_key="${map_simple[$var]}"
    jq_varname="${jq_key//./_}"
    jq_args+=(--arg "$jq_varname" "$val")
    jq_vars+=(".${jq_key} = \$$jq_varname")
  fi
done

for var in "${!map_nested[@]}"; do
  val="${!var}"
  if [ -n "$val" ]; then
    jq_key="${map_nested[$var]}"
    jq_varname="${jq_key//./_}"
    jq_args+=(--arg "$jq_varname" "$val")
    jq_vars+=(".${jq_key} = \$$jq_varname")
  fi
done

for var in "${!map_notifiers[@]}"; do
  val="${!var,,}"
  if [[ "$val" == "true" || "$val" == "false" ]]; then
    jq_key="${map_notifiers[$var]}"
    jq_varname="${jq_key//./_}"
    jq_args+=(--argjson "$jq_varname" "$val")
    jq_vars+=(".${jq_key} = \$$jq_varname")
  fi
done

# Apply all jq var overrides
if [ "${#jq_vars[@]}" -gt 0 ]; then
  echo "[INFO] Applying environment variable overrides..."
  if echo "${jq_vars[*]}" | paste -sd ' | ' - >"$WORKDIR/override.jq" 2>/dev/null; then
    if jq -S "${jq_args[@]}" -f "$WORKDIR/override.jq" "$CONFIG_FILE" >"$WORKDIR/tmp_config.json" 2>/dev/null; then
      mv "$WORKDIR/tmp_config.json" "$CONFIG_FILE"
    else
      echo "[WARNING] Failed to apply jq overrides, using existing config"
    fi
    rm -f "$WORKDIR/override.jq"
  else
    echo "[WARNING] Failed to create jq override file"
  fi
fi

# --- Fallback cron setup if systemd is not present ---
# Determine effective cron_time (now expects full cron expression)
if [ -n "$CRON_TIME" ]; then
  cron_time="$CRON_TIME"
else
  cron_time=$(jq -r '.cron_time // empty' "$CONFIG_FILE" 2>/dev/null || echo "*/20 * * * *")
  cron_time="${cron_time:-*/20 * * * *}"
fi

# Convert old numeric format to proper cron format if needed
if [[ "$cron_time" =~ ^[0-9]+$ ]]; then
  echo "[INFO] Converting legacy numeric cron_time '$cron_time' to proper cron format"
  cron_time="*/${cron_time} * * * *"
  echo "[INFO] Using cron schedule: $cron_time"
fi

# Cron installation removed - we use custom runner instead

# --- Final exec ---
if [[ "$1" == "crunch-runner" ]]; then
  echo "[INFO] Starting custom cron-like runner for crunchyroll-notify"

  # Parse cron expression to get interval in seconds
  parse_cron_interval() {
    local cron_expr="$1"
    local minute_part=$(echo "$cron_expr" | cut -d' ' -f1)

    if [[ "$minute_part" == *"/"* ]]; then
      # Extract interval from */N format
      local interval=$(echo "$minute_part" | cut -d'/' -f2)
      echo $((interval * 60)) # Convert minutes to seconds
    else
      echo 300 # Default 5 minutes
    fi
  }

  interval_seconds=$(parse_cron_interval "$cron_time")
  echo "[INFO] Running crunchyroll-notify every ${interval_seconds} seconds (${cron_time})"

  # Function to run the script with proper user context
  run_script() {
    local exit_code=0
    if [[ $(id -u) == "0" ]]; then
      # Running as root, use gosu to drop privileges
      echo "[INFO] Running as root, dropping to crunchyroll user"
      gosu crunchyroll bash -c "cd '$WORKDIR' && '$WORKDIR/crunchyroll-notify.sh'" || exit_code=$?
    else
      # Already running as non-root, execute directly
      echo "[INFO] Running as user $(id -un) (UID: $(id -u))"
      bash -c "cd '$WORKDIR' && '$WORKDIR/crunchyroll-notify.sh'" || exit_code=$?
    fi
    echo "[INFO] Script exit code: $exit_code"
    return $exit_code
  }

  # Run initial check immediately
  echo "[INFO] Running initial check..."
  if run_script; then
    echo "[INFO] Initial check completed successfully"
  else
    echo "[WARNING] Initial check failed (exit code: $?), but continuing..."
  fi

  # Then run in loop
  echo "[INFO] Starting scheduled loop (interval: ${interval_seconds}s)..."
  counter=1
  while true; do
    echo "[INFO] Sleeping for ${interval_seconds} seconds until next check..."
    sleep "$interval_seconds"
    echo "[INFO] Running scheduled check #${counter}..."
    if run_script; then
      echo "[INFO] Scheduled check #${counter} completed successfully"
    else
      echo "[WARNING] Scheduled check #${counter} failed (exit code: $?), continuing anyway..."
    fi
    ((counter++))
  done
else
  # For other commands, handle privilege switching based on current user
  current_uid=$(id -u)
  if [[ "$current_uid" == "0" ]]; then
    echo "[INFO] Switching to crunchyroll user for command: $*"
    exec gosu crunchyroll "$@"
  else
    echo "[INFO] Running command as current user (UID: $current_uid): $*"
    exec "$@"
  fi
fi
