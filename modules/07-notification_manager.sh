#!/bin/bash

notify_via_email() {
    [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Sending email notification for series title: $1"
    log "INFO" "Sending email notification for series title: $1"
    echo "Series Title $1 found in RSS feed!" | mail -s "Crunchyroll Series Title Alert" "$email_recipient"
}

notify_via_pushover() {

    [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Sending Pushover notification for series title: $1"
    log "INFO" "Sending Pushover notification for series title: $1"

    curl -sS \
        --form-string "token=$pushover_app_token" \
        --form-string "user=$pushover_user_key" \
        --form-string "message=Anime release"$'

'"Title: $1"$'
'"Watch now on $2:"$'

'"$3" \
        https://api.pushover.net/1/messages.json >/dev/null 2>&1
}

notify_via_ifttt() {
    [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Sending IFTTT notification for series title: $1"
    log "INFO" "Sending IFTTT notification for series title: $1"
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"value1\":\"Series Title $1 found in RSS feed!\"}" \
        https://maker.ifttt.com/trigger/$ifttt_event/with/key/$ifttt_key
}

notify_via_slack() {
    [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Sending Slack notification for series title: $1"
    log "INFO" "Sending Slack notification for series title: $1"
    curl -s -X POST \
        -H 'Content-type: application/json' \
        --data "{\"text\":\"Series Title $1 found in RSS feed!\"}" \
        "$slack_webhook_url"
}

notify_via_echo() {
    [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Echoing notification for series title: $1"
    log "INFO" "Echoing notification for series title: $1"
    local series_title="$1"
    local title="$2"
    local link="$3"
    local description=$(clean_description "$(decode_html_entities "$4")")
    echo -e "New Anime release
Title: $title
Link: $link"
}

notify_via_discord() {
    [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Sending Discord notification for series title: $1"
    log "INFO" "Sending Discord notification for series title: $1"
    local discord_webhook_url=$(get_config "discord.webhook_url")
    local series_title="$1"
    local title="$2"
    local link="$3"
    local description=$(clean_description "$(decode_html_entities "$4")")
    local thumbnail_url="$5"
    #local image_url="${thumbnail_url%.*}_full.jpg"

    local markdown_link="[$title]($link)"

    json_payload=$(jq -n --arg title "$title" \
        --arg description "$description" \
        --arg url "$link" \
        --arg image_url "$thumbnail_url" \
        --arg mlink "$markdown_link" \
        '{
                              "content": null,
                              "embeds": [{
                                  "title": "New Episode Released",
                                  "description": $description,
                                  "url": $url,
                                  "color": 5814783,
                                  "fields": [{
                                    "id": 802559332,
                                    "name": "Title :",
                                    "value": " ",
                                    "inline": true
                                    },
                                    {
                                    "id": 401448333,
                                    "name": $title,
                                    "value": " ",
                                    "inline": true
                                    },
                                    {
                                    "id": 897239191,
                                    "name": " ",
                                    "value": " ",
                                    "inline": false
                                    },
                                    {
                                    "id": 469320997,
                                    "name": "Watch on",
                                    "value": " ",
                                    "inline": true
                                    },
                                    {
                                    "id": 907109677,
                                    "name": "Crunchyroll :",
                                    "value": $mlink,
                                    "inline": true
                                    }],
                                  "image": {
                                      "url": $image_url
                                  }
                              }],
                              "attachments": []
                          }')
    curl -s -X POST \
        -H 'Content-Type: application/json' \
        -d "$json_payload" \
        "$discord_webhook_url"
}
notification_manager_loaded=true