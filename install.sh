#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="tang730125633"
REPO_NAME="alwayshaveaplan"
APP_NAME="AlwaysHaveAPlan"
APP_BUNDLE="${APP_NAME}.app"
INSTALL_DIR="/Applications"
TMP_DIR="$(mktemp -d)"

cleanup() {
  if [[ -n "${DMG_MOUNT:-}" ]] && mount | grep -q "$DMG_MOUNT"; then
    hdiutil detach "$DMG_MOUNT" -quiet || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

log() {
  printf '%s\n' "$*"
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || fail "AlwaysHaveAPlan only runs on macOS."

  local major
  major="$(sw_vers -productVersion | awk -F. '{print $1}')"
  if [[ "${major:-0}" -lt 14 ]]; then
    fail "macOS 14.0 or newer is required. Current version: $(sw_vers -productVersion)"
  fi
}

download_latest_dmg() {
  local api_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
  local dmg_url

  dmg_url="$(
    curl -fsSL "$api_url" 2>/dev/null \
      | awk -F '"' '/browser_download_url/ && /\.dmg"/ { print $4; exit }'
  )"

  [[ -n "$dmg_url" ]] || return 1

  log "Downloading latest release DMG..."
  curl -fL "$dmg_url" -o "$TMP_DIR/${APP_NAME}.dmg"
}

install_from_dmg() {
  local dmg_path="$1"
  DMG_MOUNT="$TMP_DIR/mount"
  mkdir -p "$DMG_MOUNT"

  log "Mounting DMG..."
  hdiutil attach "$dmg_path" -mountpoint "$DMG_MOUNT" -nobrowse -quiet

  local source_app="$DMG_MOUNT/$APP_BUNDLE"
  [[ -d "$source_app" ]] || fail "DMG does not contain $APP_BUNDLE."

  log "Installing to ${INSTALL_DIR}/${APP_BUNDLE}..."
  rm -rf "${INSTALL_DIR}/${APP_BUNDLE}"
  cp -R "$source_app" "$INSTALL_DIR/"
}

build_from_source() {
  local source_dir="$TMP_DIR/source"

  command -v git >/dev/null 2>&1 || fail "git is required for source install."
  command -v swift >/dev/null 2>&1 || fail "Swift is required for source install. Install Xcode or Command Line Tools."

  log "No release DMG found. Building from source..."
  git clone --depth 1 "https://github.com/${REPO_OWNER}/${REPO_NAME}.git" "$source_dir"
  cd "$source_dir"
  ./build-release.sh

  [[ -d "run/release/${APP_BUNDLE}" ]] || fail "Build did not produce run/release/${APP_BUNDLE}."

  log "Installing to ${INSTALL_DIR}/${APP_BUNDLE}..."
  rm -rf "${INSTALL_DIR}/${APP_BUNDLE}"
  cp -R "run/release/${APP_BUNDLE}" "$INSTALL_DIR/"
}

main() {
  require_macos

  if download_latest_dmg; then
    install_from_dmg "$TMP_DIR/${APP_NAME}.dmg"
  else
    build_from_source
  fi

  log ""
  log "Installed: ${INSTALL_DIR}/${APP_BUNDLE}"
  log "Next steps:"
  log "1. Open ${APP_NAME} from Applications."
  log "2. Grant Calendar permission when macOS asks."
  log "3. If macOS blocks the app, open System Settings > Privacy & Security and allow it."
}

main "$@"
