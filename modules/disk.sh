#!/bin/bash
# =============================================================================
# modules/disk.sh — Disk and Storage monitoring
# =============================================================================

check_disk() {
  local comp_status="HEALTHY"
  local comp_color="${C_GREEN}"

  print_header "DISK MONITORING"

  local warned=false
  local crit=false

  # Strict filtering: exclude pseudo-filesystems and snaps
  # df -hT -x tmpfs -x devtmpfs -x overlay -x squashfs
  while read -r fs type size used avail pct mount; do
    # Extra protection to skip /snap, /dev, /run, /sys, /proc paths just in case
    if [[ "${mount}" == /snap/* || "${mount}" == /dev/* || "${mount}" == /run/* || "${mount}" == /sys/* || "${mount}" == /proc/* ]]; then
      continue
    fi

    local pct_num="${pct%\%}"
    if [[ "${pct_num}" =~ ^[0-9]+$ ]]; then
      if [[ "${pct_num}" -ge "${DISK_CRIT_THRESHOLD:-95}" ]]; then
        alert_critical "Disk usage on ${mount} (${type}) is critically high: ${pct} (${used}/${size})"
        crit=true
      elif [[ "${pct_num}" -ge "${DISK_WARN_THRESHOLD:-85}" ]]; then
        alert_warning "Disk usage on ${mount} (${type}) is high: ${pct} (${used}/${size})"
        warned=true
      else
        print_info "${mount} (${type}): ${used}/${size} used (${pct}) - OK"
      fi
    fi
  done < <(df -hT -x tmpfs -x devtmpfs -x overlay -x squashfs 2>/dev/null | awk 'NR>1 {print $1,$2,$3,$4,$5,$6,$7}')

  if ${crit}; then
    comp_status="CRITICAL"
    comp_color="${C_RED}"
  elif ${warned}; then
    comp_status="WARNING"
    comp_color="${C_YELLOW}"
  fi

  print_status "DISK" "${comp_status}" "${comp_color}"
  
  if [[ "${comp_status}" == "CRITICAL" ]]; then return 2; fi
  if [[ "${comp_status}" == "WARNING" ]]; then return 1; fi
  return 0
}
