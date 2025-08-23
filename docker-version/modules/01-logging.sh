#!/bin/bash

log() {
    local loglevel="$1"
    shift
    local message="$*"
    local timestamp="$(date "+%Y-%m-%d %H:%M:%S")"
    local tag="crunchyroll-notify"
    local facility="user"

    # Disable colors in Docker or if NO_COLOR is set
    local use_colors=true
    if [[ "$container" == "docker" ]] || [[ -n "$NO_COLOR" ]] || [[ ! -t 1 ]]; then
        use_colors=false
    fi

    local color_reset=""
    local color_red=""
    local color_yellow=""
    local color_blue=""
    local color_grey=""
    
    if [[ "$use_colors" == "true" ]]; then
        color_reset="\e[0m"
        color_red="\e[31m"
        color_yellow="\e[33m"
        color_blue="\e[34m"
        color_grey="\e[90m"
    fi

    # Log to appropriate streams for Docker compatibility
    case "$loglevel" in
        "ERROR") echo -e "${color_red}[$timestamp] [ERROR] $message${color_reset}" >&2 ;;
        "INFO")  echo -e "${color_yellow}[$timestamp] [INFO]  $message${color_reset}" ;;
        "DEBUG") echo -e "${color_blue}[$timestamp] [DEBUG] $message${color_reset}" ;;
        *)       echo -e "${color_grey}[$timestamp] [UNKNOWN] $message${color_reset}" ;;
    esac
}

logging_loaded=true