#!/bin/bash
# =============================================================================
# modules/logs.sh — Advanced Log Analysis with Byte-Offset Tracking
# =============================================================================

check_logs() {
  local comp_status="HEALTHY"
  local comp_color="${C_GREEN}"
  
  print_header "LOG ANALYSIS"

  mkdir -p "${LOG_DIR}/.offsets"

  local warn_count=0
  local crit_count=0

  scan_file() {
    local file="$1"
    [[ -r "${file}" ]] || return 0

    local offset_file="${LOG_DIR}/.offsets/$(echo "${file}" | tr '/' '_').offset"
    local last_offset=0
    [[ -f "${offset_file}" ]] && last_offset=$(cat "${offset_file}")

    local current_size
    current_size=$(stat -c%s "${file}" 2>/dev/null || echo 0)

    # Log rotation guard
    if [[ "${current_size}" -lt "${last_offset}" ]]; then
      last_offset=0
    fi

    # Check for warnings and criticals
    # Warning pattern: WARN|WARNING|TIMEOUT
    # Crit pattern: ERROR|CRIT|CRITICAL|FATAL|FAILED|OOM

    local new_warn=0
    local new_crit=0

    if [[ "${current_size}" -gt "${last_offset}" ]]; then
       new_warn=$(tail -c +$((last_offset + 1)) "${file}" 2>/dev/null | grep -Eic "WARN|WARNING|TIMEOUT" || true)
       new_crit=$(tail -c +$((last_offset + 1)) "${file}" 2>/dev/null | grep -Eic "${ERROR_PATTERN}" || true)
    fi

    if [[ "${new_warn}" -gt 0 || "${new_crit}" -gt 0 ]]; then
       print_info "${file}: ${new_crit} Critical, ${new_warn} Warning matches."
    fi

    warn_count=$((warn_count + new_warn))
    crit_count=$((crit_count + new_crit))

    echo "${current_size}" > "${offset_file}"
  }

  for source in "${LOG_SOURCES[@]}"; do
    if [[ -d "${source}" ]]; then
      while IFS= read -r -d '' f; do
        scan_file "${f}"
      done < <(find "${source}" -type f -name "*.log" -print0 2>/dev/null)
    elif [[ -f "${source}" ]]; then
      scan_file "${source}"
    fi
  done

  if [[ "${crit_count}" -gt 0 ]]; then
    alert_critical "Log scan found ${crit_count} new ERROR/CRITICAL messages."
    comp_status="CRITICAL"
    comp_color="${C_RED}"
  elif [[ "${warn_count}" -gt 0 ]]; then
    alert_warning "Log scan found ${warn_count} new WARNING messages."
    comp_status="WARNING"
    comp_color="${C_YELLOW}"
  else
    print_info "No new errors or warnings found."
  fi

  print_status "LOGS" "${comp_status}" "${comp_color}"
  
  if [[ "${comp_status}" == "CRITICAL" ]]; then return 2; fi
  if [[ "${comp_status}" == "WARNING" ]]; then return 1; fi
  return 0
}
