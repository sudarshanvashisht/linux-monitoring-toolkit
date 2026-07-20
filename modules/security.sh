#!/bin/bash
# =============================================================================
# modules/security.sh — Basic Security Monitoring
# =============================================================================

check_security() {
  local comp_status="HEALTHY"
  local comp_color="${C_GREEN}"

  print_header "SECURITY MONITORING"

  local auth_log="/var/log/auth.log"
  local warn=false

  if [[ ! -r "${auth_log}" ]]; then
    # Some distros (like RHEL/CentOS) use /var/log/secure
    if [[ -r "/var/log/secure" ]]; then
      auth_log="/var/log/secure"
    else
      print_warning "Auth logs not readable (checked /var/log/auth.log, secure). Cannot scan for failed logins."
      print_status "SECURITY" "SKIPPED" "${C_YELLOW}"
      return 0
    fi
  fi

  # Only scanning the tail to avoid massive disk I/O, realistically should use byte offsets like logs.sh
  # For demonstration, checking last 1000 lines
  
  local failed_ssh
  local failed_sudo
  
  failed_ssh=$(tail -n 1000 "${auth_log}" 2>/dev/null | grep -ic "Failed password" || true)
  failed_sudo=$(tail -n 1000 "${auth_log}" 2>/dev/null | grep -ic "COMMAND=.*sudo.*" | grep -ic "pam_unix(sudo:auth): authentication failure" || true)
  
  # A better way for sudo failures:
  failed_sudo=$(tail -n 1000 "${auth_log}" 2>/dev/null | grep -ic "sudo:auth): authentication failure" || true)

  print_info "Recent Failed SSH Attempts : ${failed_ssh}"
  print_info "Recent Failed Sudo Attempts: ${failed_sudo}"

  if [[ "${failed_ssh}" -gt 10 ]]; then
    alert_warning "High number of failed SSH attempts detected (${failed_ssh} in last 1000 auth logs)."
    warn=true
  fi

  if [[ "${failed_sudo}" -gt 5 ]]; then
    alert_warning "Multiple failed sudo attempts detected (${failed_sudo}). Possible unauthorized escalation."
    warn=true
  fi

  if ${warn}; then
    comp_status="WARNING"
    comp_color="${C_YELLOW}"
  fi

  print_status "SECURITY" "${comp_status}" "${comp_color}"
  
  if [[ "${comp_status}" == "CRITICAL" ]]; then return 2; fi
  if [[ "${comp_status}" == "WARNING" ]]; then return 1; fi
  return 0
}
