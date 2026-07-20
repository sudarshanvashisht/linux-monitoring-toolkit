#!/bin/bash
# =============================================================================
# scripts/run_all.sh — Master Orchestrator for Linux Monitoring Toolkit
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# --- Load Configuration ---
if [[ -f "${TOOLKIT_DIR}/config/toolkit.conf" ]]; then
  # shellcheck source=../config/toolkit.conf
  source "${TOOLKIT_DIR}/config/toolkit.conf"
else
  echo "Error: Configuration file toolkit.conf not found!" >&2
  exit 1
fi

# --- Concurrency Lock ---
LOCK_FILE="/tmp/linux-monitoring-toolkit.lock"
if [[ -e "${LOCK_FILE}" ]] && kill -0 "$(cat "${LOCK_FILE}" 2>/dev/null)" 2>/dev/null; then
  echo "Previous run (PID $(cat "${LOCK_FILE}")) still in progress — skipping this cycle." >&2
  exit 0
fi
echo $$ > "${LOCK_FILE}"
trap 'rm -f "${LOCK_FILE}"' EXIT

# --- Load Libraries ---
# shellcheck source=../lib/utils.sh
source "${TOOLKIT_DIR}/lib/utils.sh"
# shellcheck source=../lib/os_detect.sh
source "${TOOLKIT_DIR}/lib/os_detect.sh"
# shellcheck source=../lib/alert.sh
source "${TOOLKIT_DIR}/lib/alert.sh"

# --- Initialization ---
mkdir -p "${LOG_DIR}"
QUIET=false
[[ "${1:-}" == "--quiet" ]] && QUIET=true

# Create an FD for the report log so modules can redirect output easily if needed
# We'll just append globally via shell redirections or module logging

TS="$(date '+%Y-%m-%d %H:%M:%S')"
OS_INFO=$(detect_os)

# Print Header
if ! ${QUIET}; then
  echo -e "\n${C_BOLD}${C_MAGENTA}================================================================${C_RESET}"
  echo -e "${C_BOLD}${C_MAGENTA}          LINUX MONITORING TOOLKIT - SYSTEM REPORT              ${C_RESET}"
  echo -e "${C_BOLD}${C_MAGENTA}================================================================${C_RESET}"
  echo -e "${C_BOLD}Timestamp:${C_RESET} ${TS}"
  echo -e "${C_BOLD}Hostname :${C_RESET} $(hostname)"
  echo -e "${C_BOLD}OS       :${C_RESET} ${OS_INFO}"
  local up="N/A"
  if command -v uptime >/dev/null 2>&1; then
    up=$(uptime -p 2>/dev/null || uptime)
  fi
  echo -e "${C_BOLD}Uptime   :${C_RESET} ${up}"
  echo ""
fi

# Append to log
echo "==================== SYSTEM REPORT: ${TS} ====================" >> "${REPORT_LOG}"
echo "OS: ${OS_INFO} | Hostname: $(hostname)" >> "${REPORT_LOG}"

# --- Execute Modules ---
# We use standard outputs and append everything to REPORT_LOG using process substitution
exec > >(tee -a "${REPORT_LOG}" >&2)

if [[ "${ENABLE_CPU_MEM:-true}" == "true" ]] && [[ -f "${TOOLKIT_DIR}/modules/cpu_mem.sh" ]]; then
  source "${TOOLKIT_DIR}/modules/cpu_mem.sh"
  check_cpu_mem
fi

if [[ "${ENABLE_DISK:-true}" == "true" ]] && [[ -f "${TOOLKIT_DIR}/modules/disk.sh" ]]; then
  source "${TOOLKIT_DIR}/modules/disk.sh"
  check_disk
fi

if [[ "${ENABLE_SERVICES:-true}" == "true" ]] && [[ -f "${TOOLKIT_DIR}/modules/services.sh" ]]; then
  source "${TOOLKIT_DIR}/modules/services.sh"
  check_services
fi

if [[ "${ENABLE_LOGS:-true}" == "true" ]] && [[ -f "${TOOLKIT_DIR}/modules/logs.sh" ]]; then
  source "${TOOLKIT_DIR}/modules/logs.sh"
  check_logs
fi

if [[ "${ENABLE_DOCKER:-true}" == "true" ]] && [[ -f "${TOOLKIT_DIR}/modules/docker.sh" ]]; then
  source "${TOOLKIT_DIR}/modules/docker.sh"
  check_docker
fi

if [[ "${ENABLE_KUBERNETES:-true}" == "true" ]] && [[ -f "${TOOLKIT_DIR}/modules/kubernetes.sh" ]]; then
  source "${TOOLKIT_DIR}/modules/kubernetes.sh"
  check_kubernetes
fi

if [[ "${ENABLE_SECURITY:-true}" == "true" ]] && [[ -f "${TOOLKIT_DIR}/modules/security.sh" ]]; then
  source "${TOOLKIT_DIR}/modules/security.sh"
  check_security
fi

# We must close the tee process properly if needed, but exec redirection handles it until exit.

# --- Summary Output ---
if ! ${QUIET}; then
  print_header "OVERALL STATUS"
  
  if [[ "${GLOBAL_STATUS}" -eq 2 ]]; then
    print_status "SYSTEM" "CRITICAL" "${C_RED}"
  elif [[ "${GLOBAL_STATUS}" -eq 1 ]]; then
    print_status "SYSTEM" "WARNING" "${C_YELLOW}"
  else
    print_status "SYSTEM" "HEALTHY" "${C_GREEN}"
  fi
  
  echo -e "\n${C_BOLD}${C_MAGENTA}================================================================${C_RESET}\n"
fi

exit "${GLOBAL_STATUS}"
