#!/bin/bash

log() {
    local loglevel="$1"
    shift
    local message="$*"
    local timestamp="$(date "+%Y-%m-%d %H:%M:%S")"

    # Define tag and facility
    local tag="crunchyroll-notify"
    local facility="user"

    case "$loglevel" in
        "ERROR")
            logger -p ${facility}.err -t "$tag" "[$timestamp] [ERROR] $message"
            echo -e "\e[31m[$timestamp] [ERROR] $message\e[0m" >&2
            ;;
        "INFO")
            logger -p ${facility}.info -t "$tag" "[$timestamp] [INFO] $message"
            echo -e "\e[33m[$timestamp] [INFO] $message\e[0m" >&2
            ;;
        "DEBUG")
            logger -p ${facility}.debug -t "$tag" "[$timestamp] [DEBUG] $message"
            echo -e "\e[34m[$timestamp] [DEBUG] $message\e[0m" >&2
            ;;
        *)
            logger -p ${facility}.notice -t "$tag" "[$timestamp] [UNKNOWN] $message"
            echo "[$timestamp] [UNKNOWN] $message" >&2
            ;;
    esac
}
logging_loaded=true