#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=install/lib/common.sh
source "$SCRIPT_DIR/install/lib/common.sh"
# shellcheck source=install/lib/manifest.sh
source "$SCRIPT_DIR/install/lib/manifest.sh"
# shellcheck source=install/install_steps.sh
source "$SCRIPT_DIR/install/install_steps.sh"

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Review the system, check package versions, and prepare the installation flow.

Options:
  --help             Show help and exit
  --dry-run          Preview changes without modifying the system
  --verbose          Show additional diagnostic output
  --yes              Run non-interactively and accept prompts
  --step-by-step     Pause before each step
  --manifest <path>  Use a custom package manifest

Examples:
  ./install.sh
  ./install.sh --dry-run
  ./install.sh --yes --verbose
EOF
}

parse_common_args "$@"

if [[ "$SHOW_HELP" == "true" ]]; then
  usage
  exit 0
fi

init_runtime "install"

run_step "preflight" "Preflight checks" preflight_detect_and_validate
run_step "manifest" "Validate package manifest" manifest_validate
run_step "install-plan" "Review installation plan" install_build_plan
run_step "install-exec" "Review package actions" install_execute_plan
run_step "state" "Save runtime state" write_runtime_state
run_step "summary" "Show installation summary" install_print_summary
