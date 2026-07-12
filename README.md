# GusKitchenAI
Open-source smart kitchen display powered by Raspberry Pi, Python, and AI. Includes calendar, recipes, voice control, and custom kitchen apps.

## Installer Infrastructure

This branch starts with installer infrastructure first.

After cloning, use one of these root commands:

- `./install.sh` for first-time setup
- `./update.sh` for later updates

All supporting installer files live in `install/`.

## Installer Options

Both `./install.sh` and `./update.sh` support:

- `--help` show command help
- `--dry-run` show planned actions without changing the system
- `--verbose` print extra context for each step
- `--yes` non-interactive mode (auto-confirm prompts)
- `--step-by-step` pause before each step and wait for Enter
- `--manifest <path>` override manifest location

## Platform Support

- Linux is required.
- Raspberry Pi installs support Pi 3, Pi 4, and Pi 5.
- On Raspberry Pi hardware, the OS must be Raspberry Pi OS.
- Linux PC installation is also supported.

## RAM Warning Policy

The installer checks total RAM on both Raspberry Pi and Linux PC.

If the machine has about 1 GB RAM, the script warns that the system may be laggy and asks for confirmation before continuing.

In `--yes` mode, prompts are auto-confirmed.

## Package Manifest

Package names and versions are defined in `install/packages.json`.

Current scripts validate and read the manifest to build an install/update plan.
Execution logic is scaffolded and intentionally minimal in this phase.

## Current File Layout

- `install.sh`
- `update.sh`
- `install/packages.json`
- `install/lib/common.sh`
- `install/lib/manifest.sh`
- `install/install_steps.sh`
- `install/update_steps.sh`
- `install/state/`
