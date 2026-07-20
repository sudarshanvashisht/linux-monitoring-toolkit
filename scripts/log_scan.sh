#!/bin/bash
# =============================================================================
# log_scan.sh — scans configured log sources for ERROR/CRIT-type patterns
# and prints a per-source count summary. Designed to run every N minutes via
# cron and only look at NEW lines since the last run (see .offset files),
# so it doesn't re-report the same errors forever.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/toolkit.conf"
source "${SCRIPT_DIR}/alert.sh"

mkdir -p "${LOG_DIR}" "${LOG_DIR}/.offsets"

TS="$(date '+%Y-%m-%d %H:%M:%S')"
{
  echo "==================== LOG SCAN: ${TS} ===================="
} >> "${REPORT_LOG}"

total_matches=0

scan_file() {
  local file="$1"
  [[ -r "${file}" ]] || { echo "  SKIP (not readable): ${file}" >> "${REPORT_LOG}"; return; }

  # Track byte offset per file so re-runs only scan what's new.
  # This is the difference between a toy script and one that survives
  # running every 5 minutes for months without drowning you in duplicate alerts.
  local offset_file="${LOG_DIR}/.offsets/$(echo "${file}" | tr '/' '_').offset"
  local last_offset=0
  [[ -f "${offset_file}" ]] && last_offset=$(cat "${offset_file}")

  local current_size
  current_size=$(stat -c%s "${file}" 2>/dev/null || echo 0)

  # Log rotation guard: if the file shrank, it was rotated — start from 0.
  if [[ "${current_size}" -lt "${last_offset}" ]]; then
    last_offset=0
  fi

  local matches
  matches=$(tail -c +$((last_offset + 1)) "${file}" 2>/dev/null | grep -Eic "${ERROR_PATTERN}" || true)
  matches=${matches:-0}

  echo "  ${file}: ${matches} new error-pattern match(es)" >> "${REPORT_LOG}"
  total_matches=$((total_matches + matches))

  echo "${current_size}" > "${offset_file}"
}

for source in "${LOG_SOURCES[@]}"; do
  if [[ -d "${source}" ]]; then
    while IFS= read -r -d '' f; do
      scan_file "${f}"
    done < <(find "${source}" -type f -name "*.log" -print0 2>/dev/null)
  elif [[ -f "${source}" ]]; then
    scan_file "${source}"
  else
    echo "  SKIP (not found): ${source}" >> "${REPORT_LOG}"
  fi
done

echo "TOTAL NEW MATCHES THIS RUN: ${total_matches}" >> "${REPORT_LOG}"
echo "===========================================================" >> "${REPORT_LOG}"

# Alert only on new matches found in THIS run, not cumulative history
if [[ "${total_matches}" -gt 0 ]]; then
  send_alert "Log scan found ${total_matches} new ERROR/CRIT-pattern log line(s) since last run."
fi

echo "Log scan complete: ${total_matches} new matches. See ${REPORT_LOG} for details."
