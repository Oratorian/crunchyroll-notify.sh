#!/bin/bash

check_config() {
  local config_path="$SCRIPT_DIR/cfg/config.json"
  local default_config='{
    "cron_time": "15",
    "animes": {
      "Example Anime": "ExampleDub"
    },
    "notification_services": {
      "email": false,
      "pushover": false,
      "ifttt": false,
      "slack": false,
      "discord": false,
      "echo": true
    },
    "announcerange": 60,
    "announced_file_dir": "/tmp",
    "email_recipient": "your_email@example.com",
    "pushover": {
      "user_key": "your_pushover_user_key",
      "app_token": "your_pushover_app_token"
    },
    "ifttt": {
      "event": "your_ifttt_event",
      "key": "your_ifttt_key"
    },
    "slack": {
      "webhook_url": "https://hooks.slack.com/services/your/slack/webhook/url"
    },
    "discord": {
      "webhook_url": "https://discord.com/your/discord/channel/webhook/"
    },
    "debug": {
      "enabled": false
    },
    "user_trap": "⚠️ IMPORTANT: After you’ve updated your settings, please delete this entire line from config.json. Crunchyroll_notify.sh will not run until you do."
  }'

  log "INFO" "Checking if config file exists at: $config_path"

  if [ ! -f "$config_path" ]; then
    log "INFO" "Config file not found. Creating default config at $config_path..."
    [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Config file not found. Creating default config at $config_path..."
    mkdir -p "$SCRIPT_DIR/cfg"
    echo "$default_config" >"$config_path"
    [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Default config created."
  fi

# Merge default config with user config, applying animes fallback and dropping user_trap
updated_config=$(jq -n \
  --argjson default "$default_config" \
  --argfile user "$config_path" \
  '$default as $d | $user as $u |
   $d * $u
   | del(.user_trap)
   | .animes = if ($u.animes // {} | length) > 0 then $u.animes else $d.animes end'
)

# Canonicalize both sides
existing=$(jq -S 'del(.user_trap)' "$config_path")
merged=$(echo "$updated_config" | jq -S .)

# Only write if actual structure changed
if [ "$existing" != "$merged" ]; then
    log "INFO" "Config file was missing some keys. Adding missing keys..."
    echo "$merged" >"$config_path"
    log "INFO" "Config updated with missing keys."
fi

}
check_config_loaded=true