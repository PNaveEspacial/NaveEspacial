#!/usr/bin/env bash
# Runs the GUT test suite headlessly via the pinned console Godot binary.
#
# Resolves GODOT_BIN (env var, else the pinned default path), imports
# project resources, then runs the GUT suite headlessly. Exits 2 with a
# named remediation message if the Godot binary or the GUT addon is
# missing. Propagates GUT's exit code so a failing test fails this command.
#
# Usage: run_tests.sh [extra GUT CLI args, e.g. -gdir=res://tests/unit/core]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

DEFAULT_GODOT_BIN="/c/Users/jose2/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe"
GODOT_BIN="${GODOT_BIN:-$DEFAULT_GODOT_BIN}"

info() { echo "[run_tests] $*"; }
err() { echo "[run_tests] ERROR: $*" >&2; }

if [ ! -f "$GODOT_BIN" ]; then
  err "Godot binary not found at '$GODOT_BIN'. Set the GODOT_BIN environment variable to the Godot 4.7.2 console executable."
  exit 2
fi

PLUGIN_CFG="$GAME_DIR/addons/gut/plugin.cfg"
if [ ! -f "$PLUGIN_CFG" ]; then
  err "GUT addon not found at 'addons/gut/plugin.cfg'. Run tools/install_gut.sh first."
  exit 2
fi

info "Importing project resources ..."
"$GODOT_BIN" --headless --path "$GAME_DIR" --import
import_status=$?
if [ $import_status -ne 0 ]; then
  err "Import step failed with exit code $import_status."
  exit $import_status
fi

info "Running GUT suite headlessly ..."
"$GODOT_BIN" --headless --path "$GAME_DIR" -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit "$@"
exit $?
