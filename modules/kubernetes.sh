#!/bin/bash
# =============================================================================
# modules/kubernetes.sh — Kubernetes Monitoring
# =============================================================================

check_kubernetes() {
  local comp_status="HEALTHY"
  local comp_color="${C_GREEN}"

  print_header "KUBERNETES MONITORING"

  # Check for k3s, kubectl
  local cmd=""
  if command -v kubectl >/dev/null 2>&1; then
    cmd="kubectl"
  elif command -v k3s >/dev/null 2>&1; then
    cmd="k3s kubectl"
  else
    print_warning "Kubernetes (kubectl/k3s) is not installed or not in PATH."
    print_status "KUBERNETES" "SKIPPED" "${C_YELLOW}"
    return 0
  fi

  if ! $cmd get nodes >/dev/null 2>&1; then
    alert_critical "Kubernetes cluster is unreachable or credentials are invalid."
    print_status "KUBERNETES" "CRITICAL" "${C_RED}"
    return 2
  fi

  local nodes_ready
  local nodes_not_ready
  local pods_running
  local pods_failed

  nodes_ready=$($cmd get nodes --no-headers 2>/dev/null | grep -cw "Ready")
  nodes_not_ready=$($cmd get nodes --no-headers 2>/dev/null | grep -cv "Ready")

  pods_running=$($cmd get pods -A --no-headers 2>/dev/null | grep -c -E "Running|Completed")
  pods_failed=$($cmd get pods -A --no-headers 2>/dev/null | grep -cv -E "Running|Completed")

  print_info "Nodes: ${nodes_ready} Healthy, ${nodes_not_ready} NotReady"
  print_info "Pods : ${pods_running} Running, ${pods_failed} Failed/Pending"

  if [[ "${nodes_not_ready}" -gt 0 || "${pods_failed}" -gt 0 ]]; then
    alert_warning "Kubernetes cluster has failed pods or unready nodes."
    comp_status="WARNING"
    comp_color="${C_YELLOW}"
  fi

  print_status "KUBERNETES" "${comp_status}" "${comp_color}"
  
  if [[ "${comp_status}" == "CRITICAL" ]]; then return 2; fi
  if [[ "${comp_status}" == "WARNING" ]]; then return 1; fi
  return 0
}
