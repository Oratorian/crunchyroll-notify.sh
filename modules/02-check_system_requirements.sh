#!/bin/bash

install_package() {
    local package="$1"
    if [ -x "$(command -v apt)" ]; then
        sudo apt update && sudo apt install -y "$package"
    elif [ -x "$(command -v yum)" ]; then
        sudo yum install -y "$package"
    elif [ -x "$(command -v dnf)" ]; then
        sudo dnf install -y "$package"
    elif [ -x "$(command -v pacman)" ]; then
        sudo pacman -Sy --noconfirm "$package"
    elif [ -x "$(command -v zypper)" ]; then
        sudo zypper install -y "$package"
    elif [ -x "$(command -v brew)" ]; then
        brew install "$package"
    else
        [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Unsupported OS or package manager. Please install $package manually."
        log "ERROR" "Unsupported OS or package manager. Please install $package manually."
        exit 1
    fi
}

check_system_requirements() {
    local missing=false
    for tool in curl jq xmlstarlet cron bash grep sed cut date; do
        if ! command -v "$tool" &>/dev/null; then
            [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "$tool is not installed. Attempting to install it."
            log "ERROR" "$tool is not installed. Attempting to install it."
            install_package "$tool"
            if ! command -v "$tool" &>/dev/null; then
                [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "$tool is not installed. Attempting to install it."
                log "INFO" "$tool is not installed. Attempting to install it."
                missing=true
            fi
        fi
    done

    if [ "$missing" = true ]; then
        [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Some dependencies could not be installed. Please install them manually."
        log "ERROR" "Some dependencies could not be installed. Please install them manually."
        exit 1
    else
        [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "All required tools are installed."
        log "INFO" "All required tools are installed."
    fi
}

install_rsyslog_config() {
    local config_path="/etc/rsyslog.d/30-crunchyroll-notify.conf"

    if [ -f "$config_path" ]; then
        [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "rsyslog config already exists at $config_path"
        log "INFO" "rsyslog config already exists. Skipping."
        return
    fi

    log "INFO" "Installing rsyslog configuration for crunchyroll-notify"

    sudo tee "$config_path" >/dev/null <<EOF
if \$programname == 'crunchyroll-notify' then /var/log/crunchyroll-notify.log
& stop
EOF

    sudo touch /var/log/crunchyroll-notify.log
    sudo chmod 640 /var/log/crunchyroll-notify.log
    sudo chown syslog:adm /var/log/crunchyroll-notify.log

    sudo systemctl restart rsyslog
    log "INFO" "rsyslog config installed and service restarted"
}

reinstall_rsyslog_config() {
    local config_path="/etc/rsyslog.d/30-crunchyroll-notify.conf"
    local timestamp="$(date "+%Y-%m-%d %H:%M:%S")"

    if [ -f "$config_path" ]; then
        [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "rsyslog config already exists at $config_path"
        echo -e "\e[33m[$timestamp] INFO rsyslog config already exists. Skipping.\e[0m">&2
        return
    fi

    echo -e "\e[33m[$timestamp] [INFO] Installing rsyslog configuration for crunchyroll-notify.\e[0m" >&2
    sudo tee "$config_path" >/dev/null <<EOF
if \$programname == 'crunchyroll-notify' then /var/log/crunchyroll-notify.log
& stop
EOF

    sudo touch /var/log/crunchyroll-notify.log
    sudo chmod 640 /var/log/crunchyroll-notify.log
    sudo chown syslog:adm /var/log/crunchyroll-notify.log

    sudo systemctl restart rsyslog
    echo -e "\e[33m[$timestamp] [INFO] rsyslog config installed and service restarted.\e[0m" >&2
}

install_logrotate_for_crunchyroll_notify() {
    [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Checking logrotate configuration ..."
    local logrotate_config_path="/etc/logrotate.d/crunchyroll-notify"
    local target_logfile="/var/log/crunchyroll-notify.log"
    local rsyslog_conf="/etc/rsyslog.d/30-crunchyroll-notify.conf"

    # Only install logrotate if rsyslog is configured to write this log
    if [ ! -f "$rsyslog_conf" ]; then
        log "INFO" "Skipping logrotate setup. rsyslog config not found at $rsyslog_conf"
        return
    fi

    if [ -f "$logrotate_config_path" ]; then
        [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Logrotate config already exists at $logrotate_config_path"
        return
    fi

    log "INFO" "Installing logrotate configuration for Crunchyroll log at $logrotate_config_path"

    sudo tee "$logrotate_config_path" >/dev/null <<EOL
${target_logfile} {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 syslog adm
}
EOL

    [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Logrotate config installed at $logrotate_config_path"
}

install_systemd_timer() {
    local interval="$cron_time"
    local service_path="/etc/systemd/system/crunchyroll-notify.service"
    local timer_path="/etc/systemd/system/crunchyroll-notify.timer"
    local exec_path="$SCRIPT_DIR/crunchyroll-notify.sh"
    local expected_calendar="*:0/$interval"

    # Validate format
    if ! [[ "$interval" =~ ^[0-9]{1,2}$ ]]; then
        log "ERROR" "Invalid cron_time in config.json. Must be a number of minutes like \"30\""
        return 1
    fi

    # Check for existing timer and match OnCalendar value
    if [ -f "$timer_path" ]; then
        local existing_calendar
        existing_calendar=$(grep -E "^OnCalendar=" "$timer_path" | cut -d= -f2)

        if [ "$existing_calendar" = "$expected_calendar" ]; then
            log "INFO" "Systemd timer already installed and up to date (every $interval minutes)."
            [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Skipping systemd installation. OnCalendar=$existing_calendar"
            return 0
        fi

        log "INFO" "Updating systemd timer to new interval ($expected_calendar)"
    fi

    # Write .service file
    sudo tee "$service_path" >/dev/null <<EOF
[Unit]
Description=Run Crunchyroll Notify

[Service]
Type=oneshot
ExecStart=$exec_path
WorkingDirectory=$SCRIPT_DIR
EOF

    # Write .timer file
    sudo tee "$timer_path" >/dev/null <<EOF
[Unit]
Description=Run Crunchyroll Notify every $interval minutes

[Timer]
OnCalendar=$expected_calendar
Persistent=true

[Install]
WantedBy=timers.target
EOF

    # Reload and restart systemd timer
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable --now crunchyroll-notify.timer

    log "INFO" "Systemd timer installed and enabled (every $interval minutes)"
    [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Wrote systemd service and timer files"
}
check_system_requirements_loaded=true