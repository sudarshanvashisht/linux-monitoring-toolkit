#!/bin/bash
# =============================================================================
# modules/cpu_mem.sh — CPU, Memory, Swap, and Process monitoring
# =============================================================================

check_cpu_mem() {
  local comp_status="HEALTHY"
  local comp_color="${C_GREEN}"

  print_header "CPU & MEMORY MONITORING"

  # --- CPU ---
  if [[ -r /proc/loadavg ]]; then
    read -r load1 load5 load15 _ < /proc/loadavg
    cores=$(nproc 2>/dev/null || echo "1")
    print_info "Load Average (1/5/15m): ${load1} / ${load5} / ${load15} (Cores: ${cores})"

    # Very basic threshold check: if 15m load > cores * 2
    if awk -v l="${load15}" -v c="${cores}" 'BEGIN { if (l > c * 2) exit 0; else exit 1 }'; then
      alert_warning "High sustained CPU load: 15m load (${load15}) exceeds double core count (${cores})."
      comp_status="WARNING"
      comp_color="${C_YELLOW}"
    fi
  fi

  # --- Memory & Swap ---
  if command -v free >/dev/null 2>&1; then
    # RAM
    local mem_total
    local mem_used
    local mem_pct
    mem_total=$(free -m | awk '/^Mem:/ {print $2}')
    mem_used=$(free -m | awk '/^Mem:/ {print $3}')
    
    if [[ "${mem_total}" -gt 0 ]]; then
      mem_pct=$(( (mem_used * 100) / mem_total ))
      print_info "RAM Usage: ${mem_used}MB / ${mem_total}MB (${mem_pct}%)"

      if [[ "${mem_pct}" -ge "${MEM_CRIT_THRESHOLD:-95}" ]]; then
        alert_critical "Memory utilization critically high: ${mem_pct}%"
        comp_status="CRITICAL"
        comp_color="${C_RED}"
      elif [[ "${mem_pct}" -ge "${MEM_WARN_THRESHOLD:-85}" ]]; then
        alert_warning "Memory utilization high: ${mem_pct}%"
        [[ "${comp_status}" == "HEALTHY" ]] && { comp_status="WARNING"; comp_color="${C_YELLOW}"; }
      fi
    fi

    # Swap
    local swap_total
    local swap_used
    local swap_pct=0
    swap_total=$(free -m | awk '/^Swap:/ {print $2}')
    swap_used=$(free -m | awk '/^Swap:/ {print $3}')

    if [[ -n "${swap_total}" && "${swap_total}" -gt 0 ]]; then
      swap_pct=$(( (swap_used * 100) / swap_total ))
      print_info "Swap Usage: ${swap_used}MB / ${swap_total}MB (${swap_pct}%)"
      if [[ "${swap_pct}" -ge 80 ]]; then
        alert_warning "High Swap usage: ${swap_pct}%"
        [[ "${comp_status}" == "HEALTHY" ]] && { comp_status="WARNING"; comp_color="${C_YELLOW}"; }
      fi
    fi
  fi

  # --- Zombie Processes ---
  local zombies
  zombies=$(ps aux | awk '$8=="Z" {print $0}' | wc -l)
  if [[ "${zombies}" -gt 1 ]]; then
    # 1 is usually the header row matching Z somehow, or empty. We strictly count.
    # Actually, wc -l of ps aux matching exactly Z in stat. 
    # Let's do it safely:
    zombies=$(ps axo stat | grep -c '^Z' || true)
    if [[ "${zombies}" -gt 0 ]]; then
      print_warning "Zombie processes detected: ${zombies}"
    fi
  fi

  # --- Top Processes ---
  echo ""
  print_info "Top 3 Processes by CPU:"
  ps aux --sort=-%cpu 2>/dev/null | awk 'NR==1 || NR<=4 {printf "    %-10s %-6s %-6s %-6s %s\n", $1,$2,$3,$4,$11}' || true
  
  echo ""
  print_info "Top 3 Processes by Memory:"
  ps aux --sort=-%mem 2>/dev/null | awk 'NR==1 || NR<=4 {printf "    %-10s %-6s %-6s %-6s %s\n", $1,$2,$3,$4,$11}' || true
  echo ""

  print_status "CPU & MEMORY" "${comp_status}" "${comp_color}"
  
  if [[ "${comp_status}" == "CRITICAL" ]]; then return 2; fi
  if [[ "${comp_status}" == "WARNING" ]]; then return 1; fi
  return 0
}
