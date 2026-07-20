#!/bin/bash
# =============================================================================
# modules/services.sh — Systemd Service Health Checks
# =============================================================================

check_services() {
  local comp_status="HEALTHY"
  local comp_color="${C_GREEN}"

  print_header "SERVICES MONITORING"

  if ! has_systemd; then
    print_warning "systemd is not available on this host."
    print_status "SERVICES" "SKIPPED (No systemd)" "${C_YELLOW}"
    return 0
  fi

  local any_warning=false

  for svc in "${SERVICES_TO_CHECK[@]}"; do
    # Check if unit file exists / is installed
    if ! systemctl list-unit-files "${svc}.service" "${svc}" >/dev/null 2>&1; then
      print_info "${svc} ---------- NOT INSTALLED"
      continue
    fi

    local status
    status=$(systemctl is-active "${svc}" 2>/dev/null || true)

    if [[ "${status}" == "active" ]]; then
      print_info "${svc} ---------- ACTIVE"
    else
      print_warning "${svc} ---------- INACTIVE (${status:-stopped})"
      alert_warning "Service '${svc}' is installed but INACTIVE (status: ${status:-stopped})"
      any_warning=true
    fi
  done

  if ${any_warning}; then
    comp_status="WARNING"
    comp_color="${C_YELLOW}"
  fi

  print_status "SERVICES" "${comp_status}" "${comp_color}"
  
  if [[ "${comp_status}" == "WARNING" ]]; then return 1; fi
  return 0
}
