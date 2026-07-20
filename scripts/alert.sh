#!/bin/bash
# =============================================================================
# alert.sh — shared alerting functions.
# This file is meant to be SOURCED by other scripts, not run directly.
# Usage from another script:
#   source "$(dirname "$0")/alert.sh"
#   send_alert "Disk usage on / is at 92%"
# =============================================================================

# Guard against being run directly by accident
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "alert.sh is a library — source it from another script, don't run it directly." >&2
  exit 1
fi

send_alert() {
  local message="$1"
  local timestamp
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

  # Always log locally first — this must never fail silently even if
  # Slack/email are down. Local log is the source of truth.
  echo "[${timestamp}] ALERT: ${message}" >> "${ALERT_LOG}"

  # --- Slack webhook (optional) ---
  if [[ -n "${SLACK_WEBHOOK_URL}" ]]; then
    # Escape double quotes in the message so it doesn't break the JSON payload
    local escaped_message="${message//\"/\\\"}"
    if ! curl -sS -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"🚨 *[$(hostname)]* ${escaped_message}\"}" \
        --max-time 10 \
        "${SLACK_WEBHOOK_URL}" > /dev/null 2>&1; then
      echo "[${timestamp}] WARN: Slack webhook call failed, alert only recorded locally." >> "${ALERT_LOG}"
    fi
  fi

  # --- Email (optional) ---
  if [[ -n "${ALERT_EMAIL}" ]]; then
    if command -v mail > /dev/null 2>&1; then
      echo "${message}" | mail -s "[$(hostname)] Monitoring Alert" "${ALERT_EMAIL}" \
        || echo "[${timestamp}] WARN: email alert failed, alert only recorded locally." >> "${ALERT_LOG}"
    else
      echo "[${timestamp}] WARN: ALERT_EMAIL is set but 'mail' command not found — skipping email." >> "${ALERT_LOG}"
    fi
  fi
}
