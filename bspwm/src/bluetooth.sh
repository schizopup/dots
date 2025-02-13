#!/usr/bin/env bash
# Exit immediately on errors, unset variables, and pipeline failures
set -euo pipefail

# Hardware Validation
readonly BT_CLASS_PATH="/sys/class/bluetooth"
[[ -d "$BT_CLASS_PATH" ]] || exit 0 # Silent exit if no Bluetooth hardware

# Config Handling
readonly CONFIG_DIR="${HOME}/.config/bspwm"
current_rice=$(cat "${CONFIG_DIR}/.rice" 2>/dev/null || echo "default")
config_file="${CONFIG_DIR}/rices/${current_rice}/config.ini"

# Color Extraction with Fallbacks
read_power_colors() {
  # Read both colors in single pass
  awk 'BEGIN {on=""; off=""}
        /^blue =/ {on=$3; if (off != "") exit}
        /^grey =/ {off=$3; if (on != "") exit}
        END {print on " " off}' "$config_file"
}

# Main Check Function
get_bt_status() {
  # Check systemd service state
  systemctl is-active bluetooth.service &>/dev/null || return 1

  # Get power state efficiently
  bluetoothctl show | grep -q "Powered: yes" && return 0 || return 2
}

# Execution Flow
if [[ -f "$config_file" ]]; then
  IFS=' ' read -r POWER_ON POWER_OFF <<<$(read_power_colors)
else # Fallback colors if config missing
  POWER_ON="#ffffff"
  POWER_OFF="#666666"
fi

if get_bt_status; then
  echo "%{F${POWER_ON}}󰂯%{F-}"
elif [[ $? -eq 2 ]]; then
  echo "%{F${POWER_OFF}}󰂲%{F-}"
fi

# Ensure clean exit for Polybar compatibility
exit 0
