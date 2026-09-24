#!/usr/bin/env bash
# Downloads, checksum-verifies, and installs the pinned GUT test addon.
#
# Downloads the pinned GUT release archive, verifies its SHA-256 checksum
# against the value pinned below, and extracts only the addons/gut folder
# into game/addons/gut/ (gitignored). Fails closed on any checksum
# mismatch or missing plugin.cfg: no partial install, non-zero exit,
# existing addon left untouched.
#
# Usage: install_gut.sh [--force]

set -euo pipefail

# Pinned release. Update both constants together when bumping GUT.
GUT_VERSION="9.7.1"
GUT_SHA256="14969aa46adc84aa08cdd21b9f6d1a64addd92ae60b36f02d0521ed305aa4086"
GUT_URL="https://github.com/bitwes/Gut/archive/refs/tags/v${GUT_VERSION}.zip"

FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
  esac
done

# Resolve paths from this script's own location, never the caller's cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ADDONS_DIR="$GAME_DIR/addons"
GUT_DIR="$ADDONS_DIR/gut"
TMP_DIR="$ADDONS_DIR/.gut-tmp"
VERSION_FILE="$GUT_DIR/.gut-version"

info() { echo "[install_gut] $*"; }
err() { echo "[install_gut] ERROR: $*" >&2; }

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# Idempotency: skip if the pinned version is already installed, unless --force.
if [ "$FORCE" -eq 0 ] && [ -f "$VERSION_FILE" ]; then
  installed="$(cat "$VERSION_FILE")"
  if [ "$installed" = "$GUT_VERSION" ]; then
    info "GUT $GUT_VERSION already installed (use --force to reinstall)."
    exit 0
  fi
fi

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

ZIP_PATH="$TMP_DIR/gut-$GUT_VERSION.zip"

info "Downloading GUT $GUT_VERSION from $GUT_URL ..."
curl -fsSL --proto '=https' --tlsv1.2 -o "$ZIP_PATH" "$GUT_URL"

info "Verifying SHA-256 checksum ..."
if command -v sha256sum >/dev/null 2>&1; then
  actual_hash="$(sha256sum "$ZIP_PATH" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  actual_hash="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
else
  err "No SHA-256 tool found (sha256sum or shasum required)."
  exit 1
fi

actual_lower="$(echo "$actual_hash" | tr '[:upper:]' '[:lower:]')"
expected_lower="$(echo "$GUT_SHA256" | tr '[:upper:]' '[:lower:]')"

if [ "$actual_lower" != "$expected_lower" ]; then
  err "Checksum mismatch."
  err "  Expected: $expected_lower"
  err "  Actual:   $actual_lower"
  exit 1
fi
info "Checksum verified."

info "Extracting archive ..."
EXTRACT_DIR="$TMP_DIR/extracted"
mkdir -p "$EXTRACT_DIR"
unzip -q "$ZIP_PATH" -d "$EXTRACT_DIR"

SOURCE_GUT_DIR="$EXTRACT_DIR/Gut-$GUT_VERSION/addons/gut"
PLUGIN_CFG="$SOURCE_GUT_DIR/plugin.cfg"
if [ ! -f "$PLUGIN_CFG" ]; then
  err "plugin.cfg not found at expected path after extraction: $PLUGIN_CFG"
  exit 1
fi

info "Installing to $GUT_DIR ..."
rm -rf "$GUT_DIR"
mkdir -p "$ADDONS_DIR"
mv "$SOURCE_GUT_DIR" "$GUT_DIR"

echo -n "$GUT_VERSION" > "$VERSION_FILE"

info "GUT $GUT_VERSION installed successfully."
exit 0
