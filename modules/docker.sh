#!/bin/bash
# =============================================================================
# modules/docker.sh — Docker Monitoring
# =============================================================================

check_docker() {
  local comp_status="HEALTHY"
  local comp_color="${C_GREEN}"

  print_header "DOCKER MONITORING"

  if ! has_docker; then
    print_info "Docker is not installed on this system — skipping."
    print_status "DOCKER" "SKIPPED" "${C_YELLOW}"
    return 0
  fi

  if ! docker info >/dev/null 2>&1; then
    alert_warning "Docker is installed but the daemon is not running."
    print_status "DOCKER" "INACTIVE" "${C_YELLOW}"
    return 0
  fi

  local running_containers
  local stopped_containers
  
  running_containers=$(docker ps -q 2>/dev/null | wc -l)
  stopped_containers=$(docker ps -q -f status=exited 2>/dev/null | wc -l)

  print_info "Docker Daemon      : ACTIVE"
  print_info "Running Containers : ${running_containers}"
  print_info "Stopped Containers : ${stopped_containers}"

  echo ""
  print_info "Container Name       Status"
  print_info "-----------------------------------"
  
  if [[ $((running_containers + stopped_containers)) -eq 0 ]]; then
    print_info "(No containers found)"
  else
    while IFS=$'\t' read -r name status; do
      printf "  %-20s %s\n" "${name}" "${status}"
    done < <(docker ps -a --format "{{.Names}}\t{{.State}}" 2>/dev/null)
  fi

  if [[ "${stopped_containers}" -gt 0 ]]; then
    comp_status="DEGRADED"
    comp_color="${C_YELLOW}"
    alert_degraded "Docker has ${stopped_containers} stopped container(s)."
  fi

  print_status "DOCKER" "${comp_status}" "${comp_color}"
  return 0
}
