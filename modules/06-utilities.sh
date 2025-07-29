#!/bin/bash

clean_description() {
    [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Cleaning description"
    echo "$1" | sed -E 's/<img[^>]*>//g; s/<br \/>//g; s/&#13;//g' | tr -d '
'
}

decode_html_entities() {
    [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Encoding HTML entities"
    echo "$1" | xmlstarlet unescape
}

add_title_to_announced() {
    [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Adding '$1' to announced file"
    local title="$1"
    echo "$title" >>"$announced_file"
    ANNOUNCED_TITLES["$title"]=1
}

check_announced_file() {
    # Optional: clean up old announced_* files older than 2 days
    find $announced_file_dir -maxdepth 1 -type f -name "announced_*" -mtime +2 -exec rm -f {} \;

    if [ ! -f "$announced_file" ]; then
        truncate -s 0 $announced_file
        sed -i '/^\s*$/d' "$announced_file"
        [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Created announced file at $announced_file."
        log "INFO" "Created announced file at $announced_file."
    else
        sed -i '/^\s*$/d' "$announced_file"
        [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Announced file already exists at $announced_file."
        log "INFO" "Announced file already exists at $announced_file."
    fi
}

is_within_time_range() {
    local pub_date="$1"
    local range_in_minutes="$2"

    pub_date_seconds=$(date --date="$pub_date" +%s)
    current_time_seconds=$(date -u +%s)
    time_difference=$((current_time_seconds - pub_date_seconds))
    range_in_seconds=$((range_in_minutes * 60))

    if ((time_difference <= range_in_seconds && time_difference >= -range_in_seconds)); then
        return 0
    else
        return 1
    fi
}

is_title_announced() {
    local keyword="$1"

    # Check if keyword is empty
    if [ -z "$keyword" ]; then
        [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Empty keyword provided to is_title_announced"
        return 1
    fi

    # Iterate through announced titles
    for announced_title in "${!ANNOUNCED_TITLES[@]}"; do
        if [[ "$announced_title" == "$keyword" ]]; then  # Use exact match
            [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Title already announced: $keyword"
            return 0
        fi
    done

    # No match found
    return 1
}

is_allowed_dub() {
    local title="$1"
    local allowed_dubs="$2"
    local lower_title=$(echo "$title" | tr '[:upper:]' '[:lower:]')
    [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Checking '$1' for allowed DUBS."

    #series_name=$(echo "$lower_title" | sed 's/(.*dub)//g' | sed 's/ - episode.*//g' | sed 's/ *$//')

    if ! [[ "$title" =~ \(.*[Dd]ub\) ]]; then
        return 0
        [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "No DUBS set, defaulting to Japanese"
    fi

    if [[ -z "$allowed_dubs" ]]; then
        return 1
    fi

    IFS=',' read -r -a allowed_dubs_array <<<"$allowed_dubs"
    for dub in "${allowed_dubs_array[@]}"; do

        if [[ "$title" == *"$(echo "$dub" | tr '[:upper:]' '[:lower:]')"*"dub"* ]]; then
            return 0
            [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "DUBS set, using '$dub'"
        fi
    done

    return 1
}

check_rsyslog_config_and_logfile() {
    local rsyslog_conf="/etc/rsyslog.d/30-crunchyroll-notify.conf"
    local logfile="/var/log/crunchyroll-notify.log"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    if [ ! -f "$rsyslog_conf" ] || ! grep -q "crunchyroll-notify.log" "$rsyslog_conf"; then
        log "INFO" "rsyslog is not yet configured for crunchyroll-notify. Skipping log check."
        return 0
    fi

    if [ ! -s "$logfile" ]; then
        log "INFO" "Log file missing. Attempting to reload rsyslog to recreate it..."
        sudo systemctl kill -s HUP rsyslog 2>/dev/null || sudo systemctl restart rsyslog
        sleep 1.1

        if [ -s "$logfile" ]; then
           log "INFO" "Log file successfully restored."
        else
            log "ERROR" "Log file could not be restored. Use --reinstall_syslog if needed."
        fi
    fi
}

# returns 0 if $lower_series_title matches any key in user_shows
matches_user_show() {
  for ut in "${!user_shows[@]}"; do
    # lowercase & escape in one go
    local pattern
    pattern=$(escape_special_characters "${ut,,}")
    [[ "$lower_series_title" == "$pattern"* ]] && return 0
  done
  return 1
}

check_rsyslog_config_and_logfile
[ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Checked logging system."

utilities_loaded=true