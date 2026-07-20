#!/bin/bash
# =============================================================================
# modules/network.sh — Network Statistics and Monitoring
# =============================================================================

check_network() {
  local comp_status="HEALTHY"
  local comp_color="${C_GREEN}"

  print_header "NETWORK MONITORING"

  # IP Address
  local ip_addrs
  if command -v hostname >/dev/null 2>&1; then
    ip_addrs=$(hostname -I 2>/dev/null | awk '{print $1}')
  fi

  if [[ -z "${ip_addrs}" ]] && command -v ip >/dev/null 2>&1; then
    ip_addrs=$(ip a 2>/dev/null | awk '/inet / && !/127.0.0.1/ {print $2}' | cut -d'/' -f1 | head -n 1)
  fi

  print_info "IP Address             : ${ip_addrs:-127.0.0.1}"

  # Listening Ports
  local listening_ports=""
  if command -v ss >/dev/null 2>&1; then
    listening_ports=$(ss -tuln 2>/dev/null | awk 'NR>1 {print $5}' | awk -F':' '{print $NF}' | grep -E '^[0-9]+$' | sort -nu | tr '\n' ' ')
  elif command -v netstat >/dev/null 2>&1; then
    listening_ports=$(netstat -tuln 2>/dev/null | awk 'NR>2 {print $4}' | awk -F':' '{print $NF}' | grep -E '^[0-9]+$' | sort -nu | tr '\n' ' ')
  fi

  print_info "Listening Ports        : ${listening_ports:-None}"

  # Established Connections
  local estab_conn=0
  if command -v ss >/dev/null 2>&1; then
    estab_conn=$(ss -tun state established 2>/dev/null | awk 'NR>1' | wc -l)
  elif command -v netstat >/dev/null 2>&1; then
    estab_conn=$(netstat -tun 2>/dev/null | grep -c "ESTABLISHED" || true)
  fi

  print_info "Established Connections: ${estab_conn}"

  print_status "NETWORK" "${comp_status}" "${comp_color}"
  return 0
}
