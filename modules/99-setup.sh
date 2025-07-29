install_environment() {
    local timestamp="$(date "+%Y-%m-%d %H:%M:%S")"
        if [ -f "$SCRIPT_DIR/.installed" ]; then
        echo -ne "\e[33m[INFO] Crunchyroll Notify appears to be already installed. Reinstall anyway? (y/N): \e[0m"
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "\e[33m[INFO] Installation aborted.\e[0m"
            exit 0
        fi
    fi

  check_system_requirements
  [ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Checked system requirements."

  # Optional logging and rotation
  if command -v systemctl &>/dev/null && [ -d /etc/systemd/system ]; then
    install_rsyslog_config
    install_logrotate_for_crunchyroll_notify
    install_systemd_timer
    log "INFO" "Systemd, rsyslog, and logrotate integration installed."
  else
    log "INFO" "Systemd or rsyslog not detected. Skipping integration."
  fi

  # Mark install complete
  truncate -s 0 "$SCRIPT_DIR/.installed"
  echo -e "\e[33m[$timestamp] [INFO] Crunchyroll Notify installation complete.\e[0m" >&2
}

uninstall_environment() {
        local timestamp="$(date "+%Y-%m-%d %H:%M:%S")"
        echo -e "\e[33m[$timestamp] [INFO] Uninstalling Crunchyroll Notify system modifications...\e[0m" >&2
        echo -e "\e[90m[$timestamp] ========= Starting Uninstall =========\e[0m" >&2
        # Remove logrotate config
        LOGROTATE_CONF="/etc/logrotate.d/crunchyroll-notify"
        if [ -f "$LOGROTATE_CONF" ]; then
            sudo rm -f "$LOGROTATE_CONF"
            echo -e "\e[33m[$timestamp] [INFO] Removed logrotate config: $LOGROTATE_CONF\e[0m" >&2
        else
            echo -e "\e[33m[$timestamp] [INFO] Logrotate config not found. Skipping.\e[0m" >&2
        fi
        # Remove logfile.
        LOGFILE="/var/log/crunchyroll-notify.log"
        if [ -f "$LOGFILE" ]; then
            sudo rm -f "$LOGFILE"
            echo -e "\e[33m[$timestamp] [INFO] Removed logfile: $LOGROTATE_CONF\e[0m" >&2
        else
            echo -e "\e[33m[$timestamp] [INFO] logfile not found. Skipping.\e[0m" >&2
        fi
        # Remove rsyslog config
        RSYSLOG_CONF="/etc/rsyslog.d/30-crunchyroll-notify.conf"
        if [ -f "$RSYSLOG_CONF" ]; then
            sudo rm -f "$RSYSLOG_CONF"
            echo -e "\e[33m[$timestamp] [INFO] Removed rsyslog config: $RSYSLOG_CONF\e[0m" >&2
            sudo systemctl restart rsyslog
            echo -e "\e[33m[$timestamp] [INFO] Restarted rsyslog." >&2
        else
            echo -e "\e[33m[$timestamp] [INFO] Rsyslog config not found. Skipping.\e[0m" >&2
        fi

        # Stop and disable systemd timer and service
        for unit in crunchyroll-notify.timer crunchyroll-notify.service; do
            if systemctl list-unit-files | grep -q "$unit"; then
                sudo systemctl stop "$unit" 2>/dev/null
                sudo systemctl disable "$unit" 2>/dev/null
                echo -e "\e[33m[$timestamp] [INFO] Stopped and disabled $unit.\e[0m" >&2
            else
                echo -e "\e[33m[$timestamp] [INFO] $unit not found. Skipping.\e[0m" >&2
            fi
        done

        # Remove systemd unit files
        for path in /etc/systemd/system/crunchyroll-notify.{service,timer}; do
            if [ -f "$path" ]; then
                sudo rm -f "$path"
                echo -e "\e[33m[$timestamp] [INFO] Removed systemd unit file: $path\e[0m" >&2
            fi
        done

        # Reload systemd daemon
        sudo systemctl daemon-reload
        echo -e "\e[33m[$timestamp] [INFO] Reloaded systemd daemon.\e[0m" >&2
}

[ "$DEBUG_ENABLED" = true ] && log "DEBUG" "Config file exists. Checking for 'TRAP'"
if [ -f "$SCRIPT_DIR/.installed" ]; then
  if jq -e 'has("user_trap")' "$SCRIPT_DIR/cfg/config.json" >/dev/null 2>&1; then
      log "ERROR" "Please edit and review '$SCRIPT_DIR/cfg/config.json' and remove the 'user_trap' line before proceeding."
      exit 1
  fi
fi
setup_loaded=true