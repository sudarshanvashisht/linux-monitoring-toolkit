#!/bin/bash
# =============================================================================
# service_health.sh — checks `systemctl status` for every service in
# SERVICES_TO_CHECK. Exits 0 if all are up, exits 1 (non-zero) if ANY are
# down — this exit code is what lets cron/CI pipelines treat this as a
# real health gate, not just a log line.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/toolkit.conf"
source "${SCRIPT_DIR}/alert.sh"

mkdir -p "${LOG_DIR}"

TS="$(date '+%Y-%m-%d %H:%M:%S')"
echo "==================== SERVICE HEALTH: ${TS} ====================" >> "${REPORT_LOG}"

any_down=false

if ! command -v systemctl > /dev/null 2>&1; then
  echo "  systemctl not found on this host (e.g. running inside a minimal container) — cannot check services." >> "${REPORT_LOG}"
  echo "systemctl not available — skipping service checks." >&2
  exit 2   # distinct exit code: "couldn't check", not "checked and found down"
fi

for svc in "${SERVICES_TO_CHECK[@]}"; do
  # is-active is the right primitive here — it returns a clean, scriptable
  # status (active/inactive/failed/unknown) instead of parsing free-text `status` output.
  status=$(systemctl is-active "${svc}" 2>/dev/null || true)

  if [[ "${status}" == "active" ]]; then
    echo "  [OK]   ${svc}: active" >> "${REPORT_LOG}"
  else
    echo "  [DOWN] ${svc}: ${status:-not found}" >> "${REPORT_LOG}"
    any_down=true
    send_alert "Service '${svc}' is NOT active (status: ${status:-not found})"
  fi
done

echo "===================================================================" >> "${REPORT_LOG}"

if ${any_down}; then
  echo "One or more services are down. See ${REPORT_LOG}."
  exit 1
else
  echo "All ${#SERVICES_TO_CHECK[@]} monitored services are active."
  exit 0
fi
