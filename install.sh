#!/usr/bin/env bash
# install.sh — one-liner installer for ictx binary releases
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ictx-ai/release/main/install.sh | bash
#
# This script always installs the latest release directly into
# $HOME/.local/bin (no versioned directories). Rules are placed next
# to the binaries so sense finds them automatically.
#
# Options (environment):
#   PLATFORM=...       Override (linux|darwin)
#   ARCH=...           Override (x86_64|aarch64)
#   NO_VERIFY=1        Skip the post-install sanity checks
#
# After install:
#   export PATH="$HOME/.local/bin:$PATH"

set -euo pipefail

REPO="ictx-ai/release"

# Always install into ~/.local/bin (flat, no versioned folders).
# Rules are placed next to the binaries (where sense expects them).
BIN_DIR="$HOME/.local/bin"

VERSION="${VERSION:-}"
PLATFORM="${PLATFORM:-}"
ARCH="${ARCH:-}"
NO_VERIFY="${NO_VERIFY:-0}"

die() { echo "ERROR: $*" >&2; exit 1; }
info() { echo ">> $*"; }

# Detect platform/arch if not provided
detect_platform() {
  local uname_s uname_m
  uname_s="$(uname -s)"
  uname_m="$(uname -m)"

  case "$uname_s" in
    Linux)  PLATFORM="linux" ;;
    Darwin) PLATFORM="darwin" ;;
    *) die "Unsupported OS: $uname_s" ;;
  esac

  case "$uname_m" in
    x86_64|amd64) ARCH="x86_64" ;;
    arm64|aarch64) ARCH="aarch64" ;;
    *) die "Unsupported architecture: $uname_m" ;;
  esac
}

# Resolve latest version from GitHub releases API (best effort)
resolve_latest_version() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null \
      | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4 || true
  fi
}

# Always install the latest release (unless VERSION is explicitly provided for advanced use)
ensure_version() {
  if [[ -z "$VERSION" ]]; then
    info "Fetching latest release..."
    local latest
    latest="$(resolve_latest_version || true)"
    if [[ -n "$latest" ]]; then
      VERSION="$latest"
      info "Latest release: $VERSION"
    else
      die "Could not determine latest release from GitHub. Try again later."
    fi
  fi
}

main() {
  [[ -z "$PLATFORM" || -z "$ARCH" ]] && detect_platform
  ensure_version

  local pkg_name="ictx-${VERSION}-${PLATFORM}-${ARCH}"
  local tarball="${pkg_name}.tar.gz"
  local url="https://github.com/${REPO}/releases/download/${VERSION}/${tarball}"

  info "Installing ictx ${VERSION} for ${PLATFORM}-${ARCH} into $HOME/.local/bin"

  local tmpdir
  tmpdir="$(mktemp -d)"
  # Embed path in trap — local tmpdir is out of scope when EXIT runs under set -u.
  trap "rm -rf '${tmpdir}'" EXIT

  local tar_path="${tmpdir}/${tarball}"

  info "Downloading ${url}"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --progress-bar -o "${tar_path}" "${url}" || die "Download failed: $url"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "${tar_path}" "${url}" || die "Download failed: $url"
  else
    die "Need curl or wget to download"
  fi

  info "Extracting..."
  mkdir -p "$tmpdir/extract"
  tar -xzf "${tar_path}" -C "$tmpdir/extract"

  local extracted_dir="$tmpdir/extract/${pkg_name}"
  if [[ ! -d "$extracted_dir" ]]; then
    extracted_dir="$tmpdir/extract/ictx-${VERSION}-${PLATFORM}-${ARCH}"
  fi

  if [[ ! -d "$extracted_dir" ]]; then
    ls -la "$tmpdir/extract" | head -10
    die "Failed to find extracted package inside tarball"
  fi

  info "Installing binaries to ${BIN_DIR}"
  mkdir -p "${BIN_DIR}"

  # Install executables directly (no versioned folder)
  for b in sense pulse lens config-extractor python-extractor java-extractor; do
    if [[ -f "${extracted_dir}/bin/${b}" ]]; then
      cp -f "${extracted_dir}/bin/${b}" "${BIN_DIR}/${b}"
      chmod +x "${BIN_DIR}/${b}" || true
    fi
  done

  # java-extractor-libs next to the wrapper
  if [[ -d "${extracted_dir}/bin/java-extractor-libs" ]]; then
    rm -rf "${BIN_DIR}/java-extractor-libs"
    cp -R "${extracted_dir}/bin/java-extractor-libs" "${BIN_DIR}/"
  fi

  # rules/ next to the binaries (sense auto-discovers exe_dir/rules/opengrep/core)
  if [[ -d "${extracted_dir}/rules" ]]; then
    rm -rf "${BIN_DIR}/rules"
    cp -R "${extracted_dir}/rules" "${BIN_DIR}/"
  fi


  if [[ "$NO_VERIFY" != "1" ]]; then
    info "Verifying installation..."
    export PATH="${BIN_DIR}:${PATH}"

    if command -v sense >/dev/null 2>&1; then
      sense -V || true
    else
      echo "WARN: sense not found on PATH yet"
    fi

    if [[ -d "${BIN_DIR}/rules/opengrep/core" ]]; then
      echo "  rules present: OK"
    else
      echo "  WARN: rules/opengrep/core not found next to binaries"
    fi

    echo ""
    echo "Done. Add to your shell profile:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "Then run:"
    echo "  sense run /path/to/a/repo"
  else
    info "Install complete (verification skipped)."
  fi
}

main "$@"
