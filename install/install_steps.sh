#!/usr/bin/env bash

INSTALL_PLAN=()

install_build_plan() {
  INSTALL_PLAN=()

  local entry
  while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    INSTALL_PLAN+=("$entry")
  done < <(manifest_emit_enabled_packages)

  if [[ "${#INSTALL_PLAN[@]}" -eq 0 ]]; then
    log_warn "No enabled packages found in manifest."
  else
    log_info "Install plan entries: ${#INSTALL_PLAN[@]}"
  fi

  if [[ "$VERBOSE" == "true" ]]; then
    local item
    for item in "${INSTALL_PLAN[@]}"; do
      IFS='|' read -r manager name version <<<"$item"
      log_verbose "Plan entry -> manager=$manager name=$name version=$version"
    done
  fi
}

install_execute_plan() {
  local item manager name version installed_version version_relation

  if [[ "${#INSTALL_PLAN[@]}" -eq 0 ]]; then
    log_info "Nothing to install."
    return 0
  fi

  for item in "${INSTALL_PLAN[@]}"; do
    IFS='|' read -r manager name version <<<"$item"

    installed_version="$(detect_installed_package_version "$manager" "$name" || true)"

    if [[ -n "$installed_version" ]]; then
      version_relation="$(compare_versions "$installed_version" "$version")"

      case "$version_relation" in
        eq|gt)
          log_info "$name already has version $installed_version, which meets the required version $version."
          continue
          ;;
        lt)
          if [[ "$DRY_RUN" == "true" ]]; then
            if [[ "$AUTO_YES" == "true" ]]; then
              log_info "[dry-run] Would update $name from version $installed_version to $version using $manager"
            else
              log_info "[dry-run] Would ask whether to update $name from version $installed_version to $version using $manager"
            fi
            continue
          fi

          if ! ask_yes_no "$name version $installed_version is older than required version $version. Update now?" "yes"; then
            log_warn "Skipping update for $name."
            continue
          fi
          ;;
      esac
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "[dry-run] Would install $name version $version using $manager"
      continue
    fi

    # Placeholder execution path: package-specific command adapters will be added later.
    log_info "Install placeholder: $name version $version using $manager"
  done
}

install_print_summary() {
  log_info "Install flow finished."
  log_info "Mode summary: dry_run=$DRY_RUN verbose=$VERBOSE step_by_step=$STEP_BY_STEP auto_yes=$AUTO_YES"
}
