#!/usr/bin/env bash

INSTALL_PLAN=()

install_build_plan() {
  INSTALL_PLAN=()
  reset_summary_counters

  local entry
  while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    INSTALL_PLAN+=("$entry")
  done < <(manifest_emit_enabled_packages)

  if [[ "${#INSTALL_PLAN[@]}" -eq 0 ]]; then
    log_warn "No enabled packages were found in the manifest."
  else
    log_info "Found ${#INSTALL_PLAN[@]} enabled package(s) to review for installation."
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
    log_info "There are no packages to install."
    return 0
  fi

  for item in "${INSTALL_PLAN[@]}"; do
    IFS='|' read -r manager name version <<<"$item"

    installed_version="$(detect_installed_package_version "$manager" "$name" || true)"

    if [[ -n "$installed_version" ]]; then
      version_relation="$(compare_versions "$installed_version" "$version")"

      case "$version_relation" in
        eq|gt)
          increment_summary_counter SUMMARY_SATISFIED
          log_info "Package OK: $name $installed_version already meets the required version $version."
          continue
          ;;
        lt)
          if [[ "$DRY_RUN" == "true" ]]; then
            increment_summary_counter SUMMARY_UPDATES
            if [[ "$AUTO_YES" == "true" ]]; then
              log_info "Dry run: would update $name from $installed_version to $version via $manager."
            else
              log_info "Dry run: would ask before updating $name from $installed_version to $version via $manager."
            fi
            continue
          fi

          if ! ask_yes_no "$name $installed_version is below the required version $version. Update now?" "yes"; then
            increment_summary_counter SUMMARY_SKIPPED
            log_warn "Skipped: $name update was declined."
            continue
          fi

          increment_summary_counter SUMMARY_UPDATES
          log_info "Update planned: $name from $installed_version to $version via $manager."
          ;;
      esac
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
      increment_summary_counter SUMMARY_INSTALLS
      log_info "Dry run: would install $name $version via $manager."
      continue
    fi

    increment_summary_counter SUMMARY_INSTALLS
    # Placeholder execution path: package-specific command adapters will be added later.
    log_info "Install action placeholder: $name $version via $manager."
  done
}

install_print_summary() {
  print_action_summary "Installation review"
}
