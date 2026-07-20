#!/bin/bash
# =============================================================================
# modules/kubernetes.sh — Kubernetes Monitoring
# =============================================================================

check_kubernetes() {
  local comp_status="HEALTHY"
  local comp_color="${C_GREEN}"

  print_header "KUBERNETES MONITORING"

  # Check for kubectl or k3s
  local cmd=""
  if command -v kubectl >/dev/null 2>&1; then
    cmd="kubectl"
  elif command -v k3s >/dev/null 2>&1; then
    cmd="k3s kubectl"
  else
    print_info "Kubernetes (kubectl/k3s) is not installed — skipping."
    print_status "KUBERNETES" "SKIPPED" "${C_YELLOW}"
    return 0
  fi

  if ! $cmd get nodes >/dev/null 2>&1; then
    print_info "Kubernetes cluster is not reachable or no active context — skipping."
    print_status "KUBERNETES" "INACTIVE" "${C_YELLOW}"
    return 0
  fi

  # Cluster Type Detection
  local cluster_type="Standard"
  local ctx
  ctx=$($cmd config current-context 2>/dev/null || echo "")

  if [[ "${ctx}" == *"kind"* ]] || docker ps 2>/dev/null | grep -q "kind-control-plane"; then
    cluster_type="Kind"
  elif [[ "${ctx}" == *"minikube"* ]] || command -v minikube >/dev/null 2>&1; then
    cluster_type="Minikube"
  elif command -v k3s >/dev/null 2>&1 || pgrep k3s >/dev/null 2>&1; then
    cluster_type="k3s"
  elif pgrep kubelet >/dev/null 2>&1; then
    cluster_type="Kubeadm / Native"
  fi

  print_info "Cluster Type : ${cluster_type}"

  # Nodes
  local nodes_ready
  local nodes_not_ready
  nodes_ready=$($cmd get nodes --no-headers 2>/dev/null | grep -cw "Ready")
  nodes_not_ready=$($cmd get nodes --no-headers 2>/dev/null | grep -cv "Ready")
  print_info "Nodes        : ${nodes_ready} Ready, ${nodes_not_ready} NotReady"

  # Pods
  local pods_running
  local pods_failed
  pods_running=$($cmd get pods -A --no-headers 2>/dev/null | grep -c -E "Running|Completed")
  pods_failed=$($cmd get pods -A --no-headers 2>/dev/null | grep -cv -E "Running|Completed")
  print_info "Pods         : ${pods_running} Running, ${pods_failed} Failed/Pending"

  # Deployments
  local dep_healthy
  dep_healthy=$($cmd get deployments -A --no-headers 2>/dev/null | wc -l)
  print_info "Deployments  : ${dep_healthy} Active"

  # Namespaces
  local ns_list
  ns_list=$($cmd get ns --no-headers 2>/dev/null | awk '{print $1}' | tr '\n' ' ')
  print_info "Namespaces   : ${ns_list:-default}"

  if [[ "${nodes_not_ready}" -gt 0 || "${pods_failed}" -gt 0 ]]; then
    alert_degraded "Kubernetes cluster has ${pods_failed} non-running pods or ${nodes_not_ready} unready nodes."
    comp_status="DEGRADED"
    comp_color="${C_YELLOW}"
  fi

  print_status "KUBERNETES" "${comp_status}" "${comp_color}"
  return 0
}
