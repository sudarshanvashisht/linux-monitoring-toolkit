#!/bin/bash
# =============================================================================
# lib/os_detect.sh — OS and environment detection
# =============================================================================

detect_os() {
  local os_name="Unknown"
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    os_name="${PRETTY_NAME:-${NAME}}"
  elif command -v lsb_release >/dev/null 2>&1; then
    os_name=$(lsb_release -d -s)
  fi

  # WSL detection
  if grep -qi microsoft /proc/version 2>/dev/null; then
    os_name="${os_name} (WSL)"
  fi

  echo "${os_name}"
}

has_systemd() {
  # systemd is usually PID 1, or systemctl is available and working
  if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-system-running >/dev/null 2>&1 || [[ $? -eq 1 ]]; then
      # Exit code 1 for is-system-running means 'degraded', which still means systemd is active
      return 0
    elif pidof systemd >/dev/null 2>&1; then
       return 0
    fi
  fi
  return 1
}

has_docker() {
  command -v docker >/dev/null 2>&1
}

has_kubectl() {
  command -v kubectl >/dev/null 2>&1
}
