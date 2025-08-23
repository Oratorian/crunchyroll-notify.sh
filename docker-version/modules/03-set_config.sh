check_config

[ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Checked configuration."
log "INFO" "Setting configuration values from config.json"
get_media_array "animes"
today=$(date +%Y%m%d)
announced_file_dir=$(get_config "announced_file_dir")
announced_file="$announced_file_dir/announced_$today"
announcerange=$(get_config "announcerange")
cron_time=$(get_config "cron_time")
notify_discord=$(get_config "notification_services.discord")
notify_echo=$(get_config "notification_services.echo")
notify_slack=$(get_config "notification_services.slack")
notify_ifttt=$(get_config "notification_services.ifttt")
notify_email=$(get_config "notification_services.email")
notify_pushover=$(get_config "notification_services.pushover")
DEBUG_ENABLED=$(get_config "debug.enabled")
pushover_app_token=$(get_config "pushover.app_token")
pushover_user_key=$(get_config "pushover.user_key")

[ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Setting configuration values from config.json"
declare -A ANNOUNCED_TITLES
declare -a new_announcements=()
set_config_loaded=true
