#!/bin/bash
declare -A user_shows

get_config() {
    local key="$1"
    jq -r --arg key "$key" '
    getpath($key | split(".") | map(if . == "" then null else . end)) // empty' $SCRIPT_DIR/cfg/config.json
}

get_media_array() {
    local key="$1"
    declare -A assoc_array

    while IFS="=" read -r k v; do
        assoc_array["$k"]="$v"
    done < <(jq -r --arg key "$key" '.[$key] | to_entries | map("\(.key)=\(.value)") | .[]' $SCRIPT_DIR/cfg/config.json)

    for k in "${!assoc_array[@]}"; do
        user_shows["$k"]="${assoc_array[$k]}"
    done
}
get_config_loaded=true