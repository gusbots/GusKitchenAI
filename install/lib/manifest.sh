#!/usr/bin/env bash

manifest_validate() {
  require_command python3

  [[ -f "$MANIFEST_PATH" ]] || die "Manifest not found: $MANIFEST_PATH"

  python3 - "$MANIFEST_PATH" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])

try:
    data = json.loads(path.read_text(encoding="utf-8"))
except Exception as exc:
    raise SystemExit(f"Manifest is not valid JSON: {exc}")

if not isinstance(data, dict):
    raise SystemExit("Manifest root must be an object")

if "manifest_version" not in data:
    raise SystemExit("Manifest missing required field: manifest_version")

packages = data.get("packages")
if not isinstance(packages, dict):
    raise SystemExit("Manifest field 'packages' must be an object")

for manager, entries in packages.items():
    if not isinstance(entries, list):
        raise SystemExit(f"packages.{manager} must be a list")
    for idx, entry in enumerate(entries):
        if not isinstance(entry, dict):
            raise SystemExit(f"packages.{manager}[{idx}] must be an object")
        for required in ("name", "version", "enabled"):
            if required not in entry:
                raise SystemExit(
                    f"packages.{manager}[{idx}] missing required field: {required}"
                )

print("Manifest validation passed")
PY

  log_info "Manifest is valid: $MANIFEST_PATH"
}

manifest_emit_enabled_packages() {
  require_command python3

  python3 - "$MANIFEST_PATH" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))

for manager, entries in data.get("packages", {}).items():
    for entry in entries:
        if bool(entry.get("enabled", False)):
            name = str(entry.get("name", ""))
            version = str(entry.get("version", ""))
            print(f"{manager}|{name}|{version}")
PY
}
