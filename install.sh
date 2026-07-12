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

Options:
  --help             Show this help message
  --dry-run          Show what would happen without changing the system
  --verbose          Print additional context for each step
  --yes              Non-interactive mode (auto-confirm prompts)
  --step-by-step     Pause before each step and wait for key press
  --manifest <path>  Use a custom manifest path (default: install/packages.json)
EOF
}

parse_common_args "$@"

if [[ "$SHOW_HELP" == "true" ]]; then
  usage
  exit 0
fi

init_runtime "install"

run_step "preflight" "Detect platform and validate prerequisites" preflight_detect_and_validate
run_step "manifest" "Validate package manifest" manifest_validate
run_step "install-plan" "Build install execution plan from manifest" install_build_plan
run_step "install-exec" "Execute install plan" install_execute_plan
run_step "state" "Persist runtime metadata" write_runtime_state
run_step "summary" "Print final install summary" install_print_summary
