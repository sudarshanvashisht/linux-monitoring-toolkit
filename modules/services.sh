#!/bin/bash
# =============================================================================
# modules/services.sh — Systemd Service Health Checks
# =============================================================================

check_services() {
  local comp_status="HEALTHY"
  local comp_color="${C_GREEN}"

  print_header "SERVICES MONITORING"

  if ! has_systemd; then
    print_warning "systemd is not available (e.g., WSL1 or minimal container)."
    print_status "SERVICES" "SKIPPED (No systemd)" "${C_YELLOW}"
    return 1
  fi

  local crit=false

  for svc in "${SERVICES_TO_CHECK[@]}"; do
    local status
    status=$(systemctl is-active "${svc}" 2>/dev/null || true)

    if [[ "${status}" == "active" ]]; then
      print_info "${svc}: active"
    else
      alert_critical "Service '${svc}' is down (status: ${status:-not found})"
      crit=true
    fi
  done

  if ${crit}; then
    comp_status="CRITICAL"
    comp_color="${C_RED}"
  fi

  print_status "SERVICES" "${comp_status}" "${comp_color}"
  
  if [[ "${comp_status}" == "CRITICAL" ]]; then return 2; fi
  return 0
}
