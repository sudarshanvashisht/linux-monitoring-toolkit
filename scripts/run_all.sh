#!/bin/bash
# =============================================================================
# run_all.sh — single entry point that runs all three checks in sequence.
# This is the ONE script cron actually calls (see README for the crontab line).
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# A simple lock file so a slow run (e.g. a huge log backlog on first execution)
# can't overlap with the next cron trigger and cause duplicate alerts/races.
LOCK_FILE="/tmp/linux-monitoring-toolkit.lock"
if [[ -e "${LOCK_FILE}" ]] && kill -0 "$(cat "${LOCK_FILE}" 2>/dev/null)" 2>/dev/null; then
  echo "Previous run (PID $(cat "${LOCK_FILE}")) still in progress — skipping this cycle." >&2
  exit 0
fi
echo $$ > "${LOCK_FILE}"
trap 'rm -f "${LOCK_FILE}"' EXIT

"${SCRIPT_DIR}/system_report.sh" --quiet
"${SCRIPT_DIR}/log_scan.sh"

# Capture service_health's exit code without letting `set -e`-style behavior
# (if it were on) kill this script — we want the summary printed either way.
"${SCRIPT_DIR}/service_health.sh"
service_status=$?

exit ${service_status}
