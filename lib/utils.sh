#!/bin/bash
# =============================================================================
# lib/utils.sh — Common utilities, color output, and formatting functions
# =============================================================================

# --- Colors ---
if [[ -t 1 ]]; then
  C_RESET="\e[0m"
  C_RED="\e[31m"
  C_GREEN="\e[32m"
  C_YELLOW="\e[33m"
  C_BLUE="\e[34m"
  C_MAGENTA="\e[35m"
  C_CYAN="\e[36m"
  C_BOLD="\e[1m"
else
  C_RESET=""
  C_RED=""
  C_GREEN=""
  C_YELLOW=""
  C_BLUE=""
  C_MAGENTA=""
  C_CYAN=""
  C_BOLD=""
fi

# --- Logging Functions ---
print_header() {
  echo -e "\n${C_BOLD}${C_CYAN}=== $1 ===${C_RESET}"
}

print_info() {
  echo -e "${C_BLUE}[INFO]${C_RESET} $1"
}

print_success() {
  echo -e "${C_GREEN}[OK]${C_RESET}   $1"
}

print_warning() {
  echo -e "${C_YELLOW}[WARN]${C_RESET} $1"
}

print_critical() {
  echo -e "${C_RED}[CRIT]${C_RESET} $1"
}

# Prints a formatted status line for the summary
# Usage: print_status "COMPONENT" "STATUS_STRING" "COLOR_VARIABLE"
print_status() {
  local comp="$1"
  local stat="$2"
  local col="$3"
  printf "${C_BOLD}%-15s${C_RESET} : ${col}%s${C_RESET}\n" "${comp}" "${stat}"
}
