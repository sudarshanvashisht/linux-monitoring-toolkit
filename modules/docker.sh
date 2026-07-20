#!/bin/bash
# =============================================================================
# modules/docker.sh — Docker Monitoring
# =============================================================================

check_docker() {
  local comp_status="HEALTHY"
  local comp_color="${C_GREEN}"

  print_header "DOCKER MONITORING"

  if ! has_docker; then
    print_warning "Docker is not installed or not in PATH."
    print_status "DOCKER" "SKIPPED" "${C_YELLOW}"
    return 0
  fi

  if ! docker info >/dev/null 2>&1; then
    alert_critical "Docker is installed but the daemon is not running or accessible."
    print_status "DOCKER" "CRITICAL" "${C_RED}"
    return 2
  fi

  local running_containers
  local stopped_containers
  
  running_containers=$(docker ps -q | wc -l)
  stopped_containers=$(docker ps -q -f status=exited | wc -l)

  print_info "Docker Daemon      : ACTIVE"
  print_info "Running Containers : ${running_containers}"
  print_info "Stopped Containers : ${stopped_containers}"

  # Optionally alert if containers that should be running are stopped
  # This can be expanded based on labels or specific names

  print_status "DOCKER" "${comp_status}" "${comp_color}"
  return 0
}
