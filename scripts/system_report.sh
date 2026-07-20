#!/bin/bash
# =============================================================================
# system_report.sh — CPU, memory, disk and top-process snapshot.
# Run on demand:   ./system_report.sh
# Run quietly (for cron/logging):  ./system_report.sh --quiet
# =============================================================================
set -uo pipefail
# NOTE: deliberately not using `set -e` here — a single failed metric
# (e.g. a sensor unavailable in a container) should not kill the whole report.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../config/toolkit.conf
source "${SCRIPT_DIR}/../config/toolkit.conf"
source "${SCRIPT_DIR}/alert.sh"

mkdir -p "${LOG_DIR}"

QUIET=false
[[ "${1:-}" == "--quiet" ]] && QUIET=true

log() {
  # Print to stdout unless --quiet, always append to the report log
  local line="$1"
  ${QUIET} || echo "${line}"
  echo "${line}" >> "${REPORT_LOG}"
}

TS="$(date '+%Y-%m-%d %H:%M:%S')"
log "==================== SYSTEM REPORT: ${TS} ===================="

# --- CPU ---
# Load average is the most portable "how busy is this box" number.
# It works even on minimal/container images where mpstat may be missing.
if [[ -r /proc/loadavg ]]; then
  read -r load1 load5 load15 _ < /proc/loadavg
  cores=$(nproc 2>/dev/null || echo "unknown")
  log "CPU: load avg (1/5/15m) = ${load1} / ${load5} / ${load15}  (cores: ${cores})"
else
  log "CPU: /proc/loadavg not readable — skipping"
fi

# --- Memory ---
if command -v free > /dev/null 2>&1; then
  mem_line=$(free -m | awk '/^Mem:/ {printf "used=%dMB total=%dMB (%.1f%%)", $3, $2, ($3/$2)*100}')
  log "MEMORY: ${mem_line}"

  mem_pct=$(free | awk '/^Mem:/ {printf "%d", ($3/$2)*100}')
  if [[ "${mem_pct}" -ge "${MEM_ALERT_THRESHOLD}" ]]; then
    send_alert "Memory usage is at ${mem_pct}% (threshold: ${MEM_ALERT_THRESHOLD}%)"
    log "  -> ALERT triggered: memory above threshold"
  fi
else
  log "MEMORY: 'free' command not found — skipping"
fi

# --- Disk ---
# Loop every real mounted filesystem (excludes tmpfs/overlay noise), flag
# anything over the configured threshold. This is deliberately per-mount,
# not just "/", because a full /var or /data won't show up if you only check root.
log "DISK USAGE:"
while read -r fs size used avail pct mount; do
  log "  ${mount}: ${used}/${size} used (${pct})"
  pct_num="${pct%\%}"
  if [[ "${pct_num}" =~ ^[0-9]+$ ]] && [[ "${pct_num}" -ge "${DISK_ALERT_THRESHOLD}" ]]; then
    send_alert "Disk usage on ${mount} is at ${pct} (threshold: ${DISK_ALERT_THRESHOLD}%)"
    log "    -> ALERT triggered: ${mount} above threshold"
  fi
done < <(df -hT -x tmpfs -x devtmpfs -x overlay 2>/dev/null | awk 'NR>1 {print $1,$3,$4,$5,$6,$7}')

# --- Top processes by CPU and memory ---
log "TOP 5 PROCESSES BY CPU:"
ps aux --sort=-%cpu 2>/dev/null | awk 'NR==1 || NR<=6 {printf "  %-10s %-6s %-6s %-6s %s\n", $1,$2,$3,$4,$11}' \
  | while read -r line; do log "${line}"; done

log "TOP 5 PROCESSES BY MEMORY:"
ps aux --sort=-%mem 2>/dev/null | awk 'NR==1 || NR<=6 {printf "  %-10s %-6s %-6s %-6s %s\n", $1,$2,$3,$4,$11}' \
  | while read -r line; do log "${line}"; done

log "================================================================"
