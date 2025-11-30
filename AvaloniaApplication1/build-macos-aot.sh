#!/usr/bin/env bash

set -euo pipefail

if [[ "${MACOS_AOT_ALLOW_NO_SUDO:-0}" != "1" && "${MACOS_AOT_SUDO:-0}" != "1" && "${EUID}" -ne 0 ]]; then
  if ! command -v sudo >/dev/null 2>&1; then
    echo "Error: script requires elevated permissions but 'sudo' is not available. Set MACOS_AOT_ALLOW_NO_SUDO=1 to continue without sudo." >&2
    exit 1
  fi
  echo "[macos-aot] Re-running with sudo..."
  exec sudo -E MACOS_AOT_SUDO=1 "$0" "$@"
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="${PROJECT:-}"
RUNTIME="${RUNTIME:-osx-arm64}"
CONFIGURATION="${CONFIGURATION:-Release}"
APP_NAME="${APP_NAME:-}"
APP_EXECUTABLE="${APP_EXECUTABLE:-}"
ICON_SOURCE="${ICON_SOURCE:-}"
ICON_NAME="${ICON_NAME:-AppIcon}"
BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER:-com.avalonia.protoparse}"
APP_VERSION="${APP_VERSION:-1.0.0}"
PUBLISH_DIR="${PUBLISH_DIR:-}"
BUNDLE_NAME=""
ARCHIVE_NAME=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options (also configurable via env vars of the same name):
  --project <path>            Path to .csproj file (required if PROJECT env not set)
  --runtime <rid>             Runtime identifier (default: ${RUNTIME})
  --configuration <config>    Build configuration (default: ${CONFIGURATION})
  --app-name <name>           Display/bundle name (default: derive from project)
  --app-executable <name>     Executable name inside bundle (default: derive from project)
  --bundle-identifier <id>    CFBundleIdentifier (default: ${BUNDLE_IDENTIFIER})
  --icon <path>               Path to .icns file (default: project Assets/*.icns if found)
  --publish-dir <path>        Output directory for dotnet publish (default: ${ROOT_DIR}/publish/<runtime>)
  --app-version <version>     Version for Info.plist (default: ${APP_VERSION})
  --icon-name <name>          Icon file name placed in bundle (default: ${ICON_NAME})
  -h, --help                  Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT="$2"
      shift 2
      ;;
    --runtime)
      RUNTIME="$2"
      shift 2
      ;;
    --configuration)
      CONFIGURATION="$2"
      shift 2
      ;;
    --app-name)
      APP_NAME="$2"
      shift 2
      ;;
    --app-executable)
      APP_EXECUTABLE="$2"
      shift 2
      ;;
    --bundle-identifier)
      BUNDLE_IDENTIFIER="$2"
      shift 2
      ;;
    --icon)
      ICON_SOURCE="$2"
      shift 2
      ;;
    --publish-dir)
      PUBLISH_DIR="$2"
      shift 2
      ;;
    --app-version)
      APP_VERSION="$2"
      shift 2
      ;;
    --icon-name)
      ICON_NAME="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

PUBLISH_DIR="${PUBLISH_DIR:-${ROOT_DIR}/publish/${RUNTIME}}"

log() {
  echo "[macos-aot] $*"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' not found in PATH." >&2
    exit 1
  fi
}

require_command dotnet
require_command codesign
require_command tar

if [[ -z "${PROJECT}" ]]; then
  echo "Error: 未能自动找到 .csproj，请通过 --project 指定。" >&2
  exit 1
fi
if [[ ! -f "${PROJECT}" ]]; then
  echo "Error: could not locate project file at ${PROJECT}" >&2
  exit 1
fi

PROJECT_PATH="$(cd "$(dirname "${PROJECT}")" && pwd)/$(basename "${PROJECT}")"
PROJECT="${PROJECT_PATH}"
PROJECT_DIR="$(cd "$(dirname "${PROJECT_PATH}")" && pwd)"
PROJECT_BASENAME="$(basename "${PROJECT_PATH}" .csproj)"

if [[ -z "${APP_NAME}" ]]; then
  APP_NAME="${PROJECT_BASENAME}"
fi

if [[ -z "${APP_EXECUTABLE}" ]]; then
  APP_EXECUTABLE="${PROJECT_BASENAME}"
fi

BUNDLE_NAME="${APP_NAME}.app"
ARCHIVE_NAME="${APP_NAME}-${RUNTIME}.tar.gz"

if [[ -z "${ICON_SOURCE}" ]]; then
  DEFAULT_ICON="${PROJECT_DIR}/Assets/Goescat-Macaron-Gimp.icns"
  if [[ -f "${DEFAULT_ICON}" ]]; then
    ICON_SOURCE="${DEFAULT_ICON}"
  elif [[ -d "${PROJECT_DIR}/Assets" ]]; then
    FIRST_ICON="$(find "${PROJECT_DIR}/Assets" -maxdepth 1 -name '*.icns' -print -quit 2>/dev/null || true)"
    if [[ -n "${FIRST_ICON}" ]]; then
      ICON_SOURCE="${FIRST_ICON}"
    fi
  fi
fi

if [[ -n "${ICON_SOURCE}" && ! -f "${ICON_SOURCE}" ]]; then
  echo "Error: could not locate icon file at ${ICON_SOURCE}" >&2
  exit 1
fi

log "Project: ${PROJECT}"
log "Runtime: ${RUNTIME}"
log "App bundle: ${BUNDLE_NAME} (executable: ${APP_EXECUTABLE})"
log "Bundle identifier: ${BUNDLE_IDENTIFIER}"
if [[ -n "${ICON_SOURCE}" ]]; then
  log "Icon: ${ICON_SOURCE} (bundle name: ${ICON_NAME})"
else
  log "Icon: <none>"
fi

log "Restoring dependencies"
dotnet restore "${PROJECT}"

log "Publishing ${APP_NAME} (${RUNTIME}) with AOT (configuration: ${CONFIGURATION})"
dotnet publish "${PROJECT}" \
  -r "${RUNTIME}" \
  -c "${CONFIGURATION}" \
  --self-contained true \
  -p:PublishAot=true \
  -o "${PUBLISH_DIR}"

BUNDLE_ROOT="${ROOT_DIR}/${BUNDLE_NAME}"
log "Creating app bundle at ${BUNDLE_ROOT}"
rm -rf "${BUNDLE_ROOT}" "${ROOT_DIR}/${ARCHIVE_NAME}"
mkdir -p "${BUNDLE_ROOT}/Contents/MacOS"
mkdir -p "${BUNDLE_ROOT}/Contents/Resources"

cp -R "${PUBLISH_DIR}/." "${BUNDLE_ROOT}/Contents/MacOS/"
ICON_PLIST_ENTRY=""
if [[ -n "${ICON_SOURCE}" ]]; then
  cp "${ICON_SOURCE}" "${BUNDLE_ROOT}/Contents/Resources/${ICON_NAME}.icns"
  ICON_PLIST_ENTRY="    <key>CFBundleIconFile</key>
    <string>${ICON_NAME}</string>"
else
  log "Skipping icon copy (no icon specified)"
fi

cat > "${BUNDLE_ROOT}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_EXECUTABLE}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_IDENTIFIER}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleVersion</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
${ICON_PLIST_ENTRY}
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

chmod +x "${BUNDLE_ROOT}/Contents/MacOS/${APP_EXECUTABLE}"

find "${BUNDLE_ROOT}/Contents/MacOS" -name "*.dSYM" -type d -exec rm -rf {} + 2>/dev/null || true

log "Codesigning bundle (ad-hoc)"
codesign --force --deep --sign - "${BUNDLE_ROOT}"

log "Creating archive ${ARCHIVE_NAME}"
(cd "${ROOT_DIR}" && tar -czf "${ARCHIVE_NAME}" "${BUNDLE_NAME}")

log "Done. Bundle: ${BUNDLE_ROOT}"
log "Archive: ${ROOT_DIR}/${ARCHIVE_NAME}"

if [[ "${MACOS_AOT_OPEN_FINDER:-1}" != "0" ]]; then
  if command -v open >/dev/null 2>&1; then
    TARGET="${ROOT_DIR}"
    if [[ -n "${SUDO_USER:-}" && "${EUID}" -eq 0 ]]; then
      sudo -u "${SUDO_USER}" open "${TARGET}" >/dev/null 2>&1 || log "Failed to open Finder for ${TARGET}"
    else
      open "${TARGET}" >/dev/null 2>&1 || log "Failed to open Finder for ${TARGET}"
    fi
    log "Opened Finder at ${TARGET}"
  else
    log "'open' command not available; skip Finder launch"
  fi
fi
