#!/usr/bin/env bash

SHOW_HELP="false"
DRY_RUN="false"
VERBOSE="false"
AUTO_YES="false"
STEP_BY_STEP="false"

ACTION=""
STARTED_AT=""
MANIFEST_PATH=""
ROOT_DIR=""
INSTALL_DIR=""
STATE_DIR=""
STATE_FILE=""

OS_ID="unknown"
OS_NAME="unknown"
OS_PRETTY_NAME="unknown"
OS_LIKE=""
ARCH="unknown"
PLATFORM_KIND="unknown"
PI_MODEL_RAW=""
PI_MODEL_CLASS="none"
MEM_TOTAL_KB="0"

COLOR_RESET=""
COLOR_INFO=""
COLOR_WARN=""
COLOR_ERROR=""
COLOR_DEBUG=""
COLOR_STEP=""
COLOR_EMPHASIS=""

SUMMARY_SATISFIED="0"
SUMMARY_INSTALLS="0"
SUMMARY_UPDATES="0"
SUMMARY_SKIPPED="0"

init_output_style() {
  if [[ -n "${NO_COLOR:-}" ]] || [[ "${TERM:-}" == "dumb" ]]; then
    return 0
  fi

  if ! [[ -t 1 || -t 2 ]]; then
    return 0
  fi

  if command -v tput >/dev/null 2>&1; then
    local colors
    colors="$(tput colors 2>/dev/null || printf '0')"
    if [[ "$colors" =~ ^[0-9]+$ ]] && [[ "$colors" -ge 8 ]]; then
      COLOR_RESET="$(tput sgr0)"
      COLOR_INFO="$(tput setaf 2)"
      COLOR_WARN="$(tput setaf 3)"
      COLOR_ERROR="$(tput setaf 1)"
      COLOR_DEBUG="$(tput setaf 6)"
      COLOR_STEP="$(tput bold)$(tput setaf 4)"
      COLOR_EMPHASIS="$(tput bold)"
    fi
  fi
}

log_with_level() {
  local stream="$1"
  local color="$2"
  local level="$3"
  shift 3

  if [[ "$stream" == "stderr" ]]; then
    printf '%s[%s]%s %s\n' "$color" "$level" "$COLOR_RESET" "$*" >&2
  else
    printf '%s[%s]%s %s\n' "$color" "$level" "$COLOR_RESET" "$*"
  fi
}

log_info() {
  log_with_level stdout "$COLOR_INFO" "INFO " "$*"
}

log_warn() {
  log_with_level stderr "$COLOR_WARN" "WARN " "$*"
}

log_error() {
  log_with_level stderr "$COLOR_ERROR" "ERROR" "$*"
}

log_verbose() {
  if [[ "$VERBOSE" == "true" ]]; then
    log_with_level stdout "$COLOR_DEBUG" "DEBUG" "$*"
  fi
}

die() {
  log_error "$*"
  exit 1
}

require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

extract_version_token() {
  local raw_value="$1"

  printf '%s\n' "$raw_value" | grep -Eo '[0-9]+([.][0-9]+)+' | head -n1 || true
}

compare_versions() {
  local installed_version="$1"
  local target_version="$2"

  if [[ "$installed_version" == "$target_version" ]]; then
    printf 'eq'
    return 0
  fi

  if [[ "$(printf '%s\n%s\n' "$installed_version" "$target_version" | sort -V | head -n1)" == "$installed_version" ]]; then
    printf 'lt'
    return 0
  fi

  printf 'gt'
}

detect_installed_package_version() {
  local manager="$1"
  local package_name="$2"
  local version_output=""
  local version_token=""

  if command -v "$package_name" >/dev/null 2>&1; then
    version_output="$($package_name --version 2>/dev/null | head -n1 || true)"
    version_token="$(extract_version_token "$version_output")"
    if [[ -n "$version_token" ]]; then
      printf '%s' "$version_token"
      return 0
    fi
  fi

  if [[ "$manager" == "apt" ]] && command -v dpkg-query >/dev/null 2>&1; then
    version_output="$(dpkg-query -W -f='${Version}' "$package_name" 2>/dev/null || true)"
    version_token="$(extract_version_token "$version_output")"
    if [[ -n "$version_token" ]]; then
      printf '%s' "$version_token"
      return 0
    fi
  fi

  return 1
}

parse_common_args() {
  MANIFEST_PATH=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help)
        SHOW_HELP="true"
        shift
        ;;
      --dry-run)
        DRY_RUN="true"
        shift
        ;;
      --verbose)
        VERBOSE="true"
        shift
        ;;
      --yes)
        AUTO_YES="true"
        shift
        ;;
      --step-by-step)
        STEP_BY_STEP="true"
        shift
        ;;
      --manifest)
        [[ $# -ge 2 ]] || die "--manifest requires a path"
        MANIFEST_PATH="$2"
        shift 2
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
  done
}

init_runtime() {
  ACTION="$1"
  STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  init_output_style

  ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  INSTALL_DIR="$ROOT_DIR/install"
  STATE_DIR="$INSTALL_DIR/state"
  STATE_FILE="$STATE_DIR/runtime_state.json"

  if [[ -z "$MANIFEST_PATH" ]]; then
    MANIFEST_PATH="$INSTALL_DIR/packages.json"
  elif [[ "$MANIFEST_PATH" != /* ]]; then
    MANIFEST_PATH="$ROOT_DIR/$MANIFEST_PATH"
  fi

  mkdir -p "$STATE_DIR"

  log_verbose "Action: $ACTION"
  log_verbose "Root directory: $ROOT_DIR"
  log_verbose "Install directory: $INSTALL_DIR"
  log_verbose "State file: $STATE_FILE"
  log_verbose "Manifest path: $MANIFEST_PATH"
  log_verbose "Dry-run mode: $DRY_RUN"
  log_verbose "Step-by-step mode: $STEP_BY_STEP"
  log_verbose "Auto-yes mode: $AUTO_YES"
}

step_pause_if_needed() {
  if [[ "$STEP_BY_STEP" == "true" ]]; then
    printf '%sPress Enter to continue to the next step, or Ctrl+C to cancel.%s ' "$COLOR_EMPHASIS" "$COLOR_RESET"
    read -r _
  fi
}

run_step() {
  local step_id="$1"
  local step_desc="$2"
  local step_fn="$3"

  printf '\n%sStep:%s %s\n' "$COLOR_STEP" "$COLOR_RESET" "$step_desc"
  log_verbose "Step id: $step_id"
  log_verbose "Running step function: $step_fn"
  "$step_fn"
  step_pause_if_needed
}

ask_yes_no() {
  local question="$1"
  local default_answer="${2:-no}"

  if [[ "$AUTO_YES" == "true" ]]; then
    log_info "Auto-yes enabled: $question"
    return 0
  fi

  local prompt="[y/N]"
  if [[ "$default_answer" == "yes" ]]; then
    prompt="[Y/n]"
  fi

  while true; do
    printf '%s %s: ' "$question" "$prompt"
    read -r reply

    if [[ -z "$reply" ]]; then
      if [[ "$default_answer" == "yes" ]]; then
        return 0
      fi
      return 1
    fi

    case "${reply,,}" in
      y|yes)
        return 0
        ;;
      n|no)
        return 1
        ;;
      *)
        log_warn "Please answer y or n."
        ;;
    esac
  done
}

reset_summary_counters() {
  SUMMARY_SATISFIED="0"
  SUMMARY_INSTALLS="0"
  SUMMARY_UPDATES="0"
  SUMMARY_SKIPPED="0"
}

increment_summary_counter() {
  local counter_name="$1"
  printf -v "$counter_name" '%s' "$(( ${!counter_name} + 1 ))"
}

print_action_summary() {
  local label="$1"

  log_info "$label complete: ${SUMMARY_SATISFIED} already satisfied, ${SUMMARY_UPDATES} scheduled for update, ${SUMMARY_INSTALLS} scheduled for install, ${SUMMARY_SKIPPED} skipped."
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "Dry run only. No changes were made."
  fi
  if [[ "$VERBOSE" == "true" ]]; then
    log_verbose "Mode summary: dry_run=$DRY_RUN verbose=$VERBOSE step_by_step=$STEP_BY_STEP auto_yes=$AUTO_YES"
  fi
}

load_os_release() {
  OS_ID="unknown"
  OS_NAME="unknown"
  OS_PRETTY_NAME="unknown"
  OS_LIKE=""

  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_NAME="${NAME:-unknown}"
    OS_PRETTY_NAME="${PRETTY_NAME:-$OS_NAME}"
    OS_LIKE="${ID_LIKE:-}"
  fi
}

read_pi_model_raw() {
  if [[ -r /proc/device-tree/model ]]; then
    tr -d '\0' </proc/device-tree/model
    return 0
  fi

  if [[ -r /sys/firmware/devicetree/base/model ]]; then
    tr -d '\0' </sys/firmware/devicetree/base/model
    return 0
  fi

  return 1
}

classify_pi_model() {
  local model="${1,,}"

  if [[ "$model" == *"raspberry pi 5"* ]]; then
    printf 'pi5'
    return 0
  fi
  if [[ "$model" == *"raspberry pi 4"* ]]; then
    printf 'pi4'
    return 0
  fi
  if [[ "$model" == *"raspberry pi 3"* ]]; then
    printf 'pi3'
    return 0
  fi

  printf 'unsupported'
}

is_raspberry_pi_os() {
  local combined
  combined="${OS_ID,,} ${OS_NAME,,} ${OS_PRETTY_NAME,,} ${OS_LIKE,,}"

  [[ "$combined" == *"raspbian"* ]] || [[ "$combined" == *"raspberry pi os"* ]]
}

detect_memory_kb() {
  local mem_kb
  mem_kb="$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || true)"

  if [[ -z "$mem_kb" ]]; then
    MEM_TOTAL_KB="0"
  else
    MEM_TOTAL_KB="$mem_kb"
  fi
}

memory_in_gb_text() {
  awk -v kb="$MEM_TOTAL_KB" 'BEGIN { if (kb <= 0) { print "unknown"; exit 0 } printf "%.2f", kb / 1024 / 1024 }'
}

check_low_memory_warning() {
  if [[ "$MEM_TOTAL_KB" -le 0 ]]; then
    log_warn "Unable to determine total RAM."
    return 0
  fi

  # 1 GB systems usually report around 900000-1100000 KB.
  if [[ "$MEM_TOTAL_KB" -le 1200000 ]]; then
    log_warn "Detected about 1 GB of RAM. The system may feel slow or laggy on this machine."
    if ! ask_yes_no "Continue with installation on a low-memory system?" "no"; then
      die "Installation cancelled due to low-memory warning."
    fi
  fi
}

preflight_detect_and_validate() {
  local uname_s

  uname_s="$(uname -s)"
  ARCH="$(uname -m)"
  [[ "$uname_s" == "Linux" ]] || die "Unsupported operating system: $uname_s. Linux is required."

  load_os_release

  PI_MODEL_RAW=""
  if PI_MODEL_RAW="$(read_pi_model_raw 2>/dev/null || true)"; then
    if [[ -n "$PI_MODEL_RAW" ]]; then
      PLATFORM_KIND="raspberry-pi"
    else
      PLATFORM_KIND="linux-pc"
    fi
  else
    PLATFORM_KIND="linux-pc"
  fi

  if [[ "$PLATFORM_KIND" == "raspberry-pi" ]]; then
    PI_MODEL_CLASS="$(classify_pi_model "$PI_MODEL_RAW")"
    [[ "$PI_MODEL_CLASS" != "unsupported" ]] || die "Unsupported Raspberry Pi model: $PI_MODEL_RAW"

    if ! is_raspberry_pi_os; then
      die "Raspberry Pi hardware must run Raspberry Pi OS. Detected: $OS_PRETTY_NAME"
    fi
  else
    PI_MODEL_CLASS="none"
  fi

  detect_memory_kb

  log_info "Environment detected:"
  log_info "  Platform: $PLATFORM_KIND"
  log_info "  OS: $OS_PRETTY_NAME"
  log_verbose "OS id: $OS_ID"
  log_verbose "OS like: $OS_LIKE"
  log_info "  Architecture: $ARCH"

  if [[ "$PLATFORM_KIND" == "raspberry-pi" ]]; then
    log_info "  Raspberry Pi model: $PI_MODEL_RAW ($PI_MODEL_CLASS)"
  fi

  log_info "  RAM: $(memory_in_gb_text) GB"

  check_low_memory_warning
}

write_runtime_state() {
  require_command python3

  local manifest_checksum=""
  local py_dry_run="False"
  local py_verbose="False"
  local py_auto_yes="False"
  local py_step_by_step="False"

  if [[ "$DRY_RUN" == "true" ]]; then py_dry_run="True"; fi
  if [[ "$VERBOSE" == "true" ]]; then py_verbose="True"; fi
  if [[ "$AUTO_YES" == "true" ]]; then py_auto_yes="True"; fi
  if [[ "$STEP_BY_STEP" == "true" ]]; then py_step_by_step="True"; fi

  if [[ -f "$MANIFEST_PATH" ]]; then
    manifest_checksum="$(sha256sum "$MANIFEST_PATH" | awk '{print $1}')"
  fi

  python3 - <<PY
import json
from pathlib import Path

state = {
    "action": "${ACTION}",
    "started_at": "${STARTED_AT}",
  "dry_run": ${py_dry_run},
  "verbose": ${py_verbose},
  "auto_yes": ${py_auto_yes},
  "step_by_step": ${py_step_by_step},
    "manifest_path": "${MANIFEST_PATH}",
    "manifest_sha256": "${manifest_checksum}",
    "platform": {
        "kind": "${PLATFORM_KIND}",
        "architecture": "${ARCH}",
        "os_id": "${OS_ID}",
        "os_name": "${OS_NAME}",
        "os_pretty_name": "${OS_PRETTY_NAME}",
        "os_like": "${OS_LIKE}",
        "pi_model_raw": "${PI_MODEL_RAW}",
        "pi_model_class": "${PI_MODEL_CLASS}",
        "mem_total_kb": int("${MEM_TOTAL_KB}" or 0),
    },
}

path = Path("${STATE_FILE}")
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
PY

  log_info "Runtime state saved."
  log_verbose "Runtime state path: $STATE_FILE"
}
