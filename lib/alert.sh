#!/bin/bash
# =============================================================================
# lib/alert.sh — Advanced alerting engine (WARNING, DEGRADED, CRITICAL)
# =============================================================================

# Global status tracking:
# 0 = HEALTHY, 1 = WARNING, 2 = DEGRADED, 3 = CRITICAL
export GLOBAL_STATUS=0

route_alert() {
  local severity="$1"  # "WARNING", "DEGRADED", or "CRITICAL"
  local message="$2"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"

  # Update global status
  if [[ "${severity}" == "CRITICAL" ]]; then
    GLOBAL_STATUS=3
  elif [[ "${severity}" == "DEGRADED" && ${GLOBAL_STATUS} -lt 2 ]]; then
    GLOBAL_STATUS=2
  elif [[ "${severity}" == "WARNING" && ${GLOBAL_STATUS} -lt 1 ]]; then
    GLOBAL_STATUS=1
  fi

  # Local Logging
  echo "[${ts}] [${severity}] ${message}" >> "${ALERT_LOG}"

  # Terminal Output (if not quiet)
  if [[ "${QUIET:-false}" == "false" ]]; then
    if [[ "${severity}" == "CRITICAL" ]]; then
      print_critical "${message}"
    elif [[ "${severity}" == "DEGRADED" ]]; then
      print_warning "${message}"
    else
      print_warning "${message}"
    fi
  fi

  # Webhook Dispatch
  if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
    local icon="⚠️"
    [[ "${severity}" == "DEGRADED" ]] && icon="🟠"
    [[ "${severity}" == "CRITICAL" ]] && icon="🚨"
    local escaped_message="${message//\"/\\\"}"
    curl -sS -X POST -H 'Content-type: application/json' \
      --data "{\"text\":\"${icon} *[$(hostname)] [${severity}]* ${escaped_message}\"}" \
      --max-time 10 \
      "${SLACK_WEBHOOK_URL}" >/dev/null 2>&1 || true
  fi

  # Email Dispatch
  if [[ -n "${ALERT_EMAIL:-}" ]]; then
    if command -v mail >/dev/null 2>&1; then
      echo "${message}" | mail -s "[${severity}] [$(hostname)] Monitoring Alert" "${ALERT_EMAIL}" 2>/dev/null || true
    fi
  fi
}

alert_warning() { route_alert "WARNING" "$1"; }
alert_degraded() { route_alert "DEGRADED" "$1"; }
alert_critical() { route_alert "CRITICAL" "$1"; }
