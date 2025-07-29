#!/bin/bash

log() {
    local loglevel="$1"
    shift
    local message="$*"
    local timestamp="$(date "+%Y-%m-%d %H:%M:%S")"
    local tag="crunchyroll-notify"
    local facility="user"

    local color_reset="\e[0m"
    local color_red="\e[31m"
    local color_yellow="\e[33m"
    local color_blue="\e[34m"
    local color_grey="\e[90m"

    # Safe logger fallback
    if command -v logger &>/dev/null && logger -T test >/dev/null 2>&1; then
        logger -p ${facility}.${loglevel,,} -t "$tag" "[$timestamp] [$loglevel] $message" || true
    fi

    # Always print to console with color
    case "$loglevel" in
        "ERROR") echo -e "${color_red}[$timestamp] [ERROR] $message${color_reset}" >&2 ;;
        "INFO")  echo -e "${color_yellow}[$timestamp] [INFO]  $message${color_reset}" >&2 ;;
        "DEBUG") echo -e "${color_blue}[$timestamp] [DEBUG] $message${color_reset}" >&2 ;;
        *)       echo -e "${color_grey}[$timestamp] [UNKNOWN] $message${color_reset}" >&2 ;;
    esac
}

logging_loaded=true