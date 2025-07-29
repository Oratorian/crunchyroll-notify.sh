#!/bin/bash

#---------------------------------------------------------------------------------------------
# This script © 2024 by Oration 'Mahesvara' is released unter the GPL-3.0 license
# Reproduction and modifications are allowed as long as I Oratorian@github.com is credited
# as the original Author
#---------------------------------------------------------------------------------------------

## Version: 3.0.0

declare -A user_shows
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

load_modules() {

expected_modules=(
    logging_loaded
    check_system_requirements_loaded
    get_config_loaded
    check_config_loaded
    set_config_loaded
    utilities_loaded
    notification_manager_loaded
    check_title_loaded
    setup_loaded
)

# Load all modules in order
for module in "$SCRIPT_DIR/modules/"[0-9][0-9]-*.sh; do
    if [ -f "$module" ]; then
        if ! source "$module"; then
            printf "[FATAL] Failed to source module: %s\n" "$module"
            exit 1
        fi
    else
        printf "[FATAL] Expected module missing: %s\n" "$module"
        exit 1
    fi
done
# Validate that all required modules set their *_loaded flag
for var in "${expected_modules[@]}"; do
    if [ "${!var}" != true ]; then
        printf "[FATAL] Required module did not load properly: %s\n" "$var"
        exit 1
    fi
done

log "INFO" "All modules loaded and validated successfully."
}

main() {
[ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Script directory set to $SCRIPT_DIR"

if [ ! -f "$SCRIPT_DIR/.installed" ]; then
    timestamp="$(date "+%Y-%m-%d %H:%M:%S")"
    echo -e "\e[33m[$timestamp] [INFO] Please run with --install for initial setup.\e[0m" >&2
    exit 1
fi

# Ensure announced file exists and is ready
check_announced_file
[ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Loading announced titles from file: $announced_file"

while IFS= read -r line; do
    ANNOUNCED_TITLES["$line"]=1
done <"$announced_file"

rss_feed=$(curl -sL "https://www.crunchyroll.com/rss/calendar?time=$(date +%s)")
[ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Fetched RSS feed."

if ! echo "$rss_feed" | grep -q "<?xml"; then
    log "ERROR" "The fetched content is not valid XML."
    exit 1
fi

media_items=$(echo "$rss_feed" | xmlstarlet sel -N cr="http://www.crunchyroll.com/rss" -N media="http://search.yahoo.com/mrss/" -t -m "//item" -v "concat(crunchyroll:seriesTitle, '|', title, '|', pubDate, '|', link, '|', normalize-space(description), '|', media:thumbnail[1]/@url)" -n)
[ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Parsed media items from RSS feed."

while IFS= read -r line; do
    series_title=$(echo "$line" | cut -d'|' -f1)
    sanitized_stitle=$(escape_special_characters "$series_title")
    lower_series_title=$(echo "$sanitized_stitle" | tr '[:upper:]' '[:lower:]')

    title=$(echo "$line" | cut -d'|' -f2)
    sanitized_title=$(escape_special_characters "$title")
    lower_title=$(echo "$sanitized_title" | tr '[:upper:]' '[:lower:]')

    sanitized_title=$(escape_special_characters "$title")
    pub_date=$(echo "$line" | cut -d'|' -f3)
    link=$(echo "$line" | cut -d'|' -f4)
    description=$(echo "$line" | cut -d'|' -f5)
    thumbnail_url=$(echo "$line" | cut -d'|' -f6)
    allowed_dubs="${user_shows["$series_title"]}"

    [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Processing series: $title"

    if ! matches_user_show; then
        [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Skipping series: $series_title as it is not listed in user_shows"
        continue
    fi

    if is_allowed_dub "$series_title" "$allowed_dubs"; then
        [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Series $series_title has allowed dubs."

        if ! is_within_time_range "$pub_date" "$announcerange"; then
            [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Series $series_title is not within the announcement time range."
            continue
        fi

        if ! is_title_announced "$lower_title"; then
            [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Announcing new title: $series_title"
            new_announcements+=("$line")
            add_title_to_announced "$lower_title"
        fi
    else
        [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Series $series_title has no allowed dubs."
        continue
    fi
done <<<"$(echo "$media_items" | tr -d '\r')"

if [ "${#new_announcements[@]}" -gt 0 ]; then
    log "INFO" "Announcing ${#new_announcements[@]} new release(s)…"
    for item in "${new_announcements[@]}"; do
        # unpack the 6 fields
        IFS='|' read -r series_title title pub_date link description thumbnail <<< "$item"

        # log and notify using the correct variables
        log "INFO" "📢 $title"
        [ "$notify_email"    = true ] && notify_via_email     "$title"
        [ "$notify_pushover" = true ] && notify_via_pushover  "$(decode_html_entities "$series_title")" "Crunchyroll" "$link"
        [ "$notify_ifttt"    = true ] && notify_via_ifttt    "$title"
        [ "$notify_slack"    = true ] && notify_via_slack     "$title"
        [ "$notify_discord"  = true ] && notify_via_discord   "$(decode_html_entities "$series_title")" "$(decode_html_entities "$title")" "$link" "$description" "$thumbnail_url"
        [ "$notify_echo"     = true ] && notify_via_echo      "$series_title" "$title" "$link" "$description" "$thumbnail"
    done
else
    [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "No new releases to announce."
fi
}

case "$1" in
    --install)
        load_modules
        install_environment
        exit 0
        ;;
    --uninstall)
        rm -f "$SCRIPT_DIR/.installed"
        load_modules
        uninstall_environment
        exit 0
        ;;
    --reinstall_syslog)
        echo "[INFO] Forcing reinstall of rsyslog config..."
        sudo rm -f /etc/rsyslog.d/30-crunchyroll-notify.conf
        if [ -f "$SCRIPT_DIR/modules/02-check_system_requirements.sh" ]; then
            source "$SCRIPT_DIR/modules/02-check_system_requirements.sh"
        else
            echo -e "\e[31m[$timestamp] [FATAL] Required module missing: 02-check_system_requirements.sh\e[0m" >&2
            exit 1
        fi
        reinstall_rsyslog_config
        exit 0
        ;;
    *)
    load_modules
    main
    ;;
esac