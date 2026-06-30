#!/usr/bin/env bash
# install.sh — one-liner installer for ictx binary releases
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ictx-ai/release/main/install.sh | bash
#
# This script always installs the latest release.
#
# It detects a good location:
#   - If $HOME/.local/bin is in PATH → installs commands to $HOME/.local/bin
#   - Otherwise → installs commands directly to $HOME/bin
#
# You can override the base with PREFIX=... if needed.
#
# Options (environment):
#   PREFIX=$HOME/.local or $HOME/bin
#   PLATFORM=...       Override (linux|darwin)
#   ARCH=...           Override (x86_64|aarch64)
#   NO_VERIFY=1        Skip the post-install sanity checks
#
# After install you will see the required PATH and ICTX_RULES_ROOT exports.

set -euo pipefail

REPO="ictx-ai/release"

# Choose where to install based on what the user already has on PATH.
# Goal: make the binaries appear directly in a directory the user has in $PATH.
if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    # ~/.local/bin is on PATH → use ~/.local as base (binaries will land in ~/.local/bin)
    DEFAULT_PREFIX="$HOME/.local"
elif [[ ":$PATH:" == *":$HOME/bin:"* ]]; then
    # ~/bin is on PATH → use ~/bin directly (binaries will land in ~/bin)
    DEFAULT_PREFIX="$HOME/bin"
else
    DEFAULT_PREFIX="$HOME/bin"
fi

VERSION="${VERSION:-}"
PREFIX="${PREFIX:-$DEFAULT_PREFIX}"
PLATFORM="${PLATFORM:-}"
ARCH="${ARCH:-}"
NO_VERIFY="${NO_VERIFY:-0}"

# Where the commands and rules will actually be placed
if [[ "$PREFIX" == "$HOME/.local" ]]; then
  BIN_DIR="$PREFIX/bin"
  RULES_DIR="$PREFIX/rules"
elif [[ "$PREFIX" == "$HOME/bin" ]]; then
  BIN_DIR="$PREFIX"
  RULES_DIR="$HOME/.ictx/rules"
else
  BIN_DIR="$PREFIX/bin"
  RULES_DIR="$PREFIX/rules"
fi

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

  info "Installing ictx ${VERSION} for ${PLATFORM}-${ARCH}"
  info "Commands → ${BIN_DIR}"

  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  local tar_path="${tmpdir}/${tarball}"

  info "Downloading ${url}"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --progress-bar -o "${tar_path}" "${url}" || die "Download failed: $url"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "${tar_path}" "${url}" || die "Download failed: $url"
  else
    die "Need curl or wget to download"
  fi

  # Always extract the full versioned bundle under a hidden location
  local versions_dir="$HOME/.ictx/versions"
  mkdir -p "$versions_dir"

  info "Extracting..."
  tar -xzf "${tar_path}" -C "$versions_dir"

  local extracted_dir="$versions_dir/${pkg_name}"
  if [[ ! -d "$extracted_dir" ]]; then
    extracted_dir="$versions_dir/ictx-${VERSION}-${PLATFORM}-${ARCH}"
  fi

  if [[ ! -d "$extracted_dir" ]]; then
    ls -la "$versions_dir" | head -10
    die "Failed to find extracted package"
  fi

  info "Installing binaries to ${BIN_DIR}"
  mkdir -p "${BIN_DIR}" "${RULES_DIR}"

  # Symlink (or copy) the executables directly into the bin dir on PATH
  for b in sense pulse lens config-extractor python-extractor java-extractor; do
    if [[ -f "${extracted_dir}/bin/${b}" ]]; then
      ln -sf "${extracted_dir}/bin/${b}" "${BIN_DIR}/${b}" || cp -f "${extracted_dir}/bin/${b}" "${BIN_DIR}/${b}"
      chmod +x "${BIN_DIR}/${b}" || true
    fi
  done

  # java-extractor-libs (needed next to java-extractor or in a known place)
  if [[ -d "${extracted_dir}/bin/java-extractor-libs" ]]; then
    rm -rf "${BIN_DIR}/java-extractor-libs"
    cp -R "${extracted_dir}/bin/java-extractor-libs" "${BIN_DIR}/"
  fi

  # rules
  if [[ -d "${extracted_dir}/rules" ]]; then
    rm -rf "${RULES_DIR}"
    cp -R "${extracted_dir}/rules" "${RULES_DIR}"
  fi


  if [[ "$NO_VERIFY" != "1" ]]; then
    info "Verifying installation..."
    export PATH="${BIN_DIR}:${PATH}"
    export ICTX_RULES_ROOT="${RULES_DIR}"

    if command -v sense >/dev/null 2>&1; then
      sense -V || true
    else
      echo "WARN: sense not found on PATH yet"
    fi

    if [[ -f "${RULES_DIR}/opengrep/core/ictx-rules.yaml" ]]; then
      echo "  rules present: OK"
    else
      echo "  WARN: rules/opengrep/core/ictx-rules.yaml not found under ${RULES_DIR}"
    fi

    echo ""
    echo "Done. Add these to your shell profile (if not already present):"
    echo "  export PATH=\"${BIN_DIR}:\$PATH\""
    echo "  export ICTX_RULES_ROOT=\"${RULES_DIR}\""
    echo ""
    echo "Then run:"
    echo "  sense run /path/to/a/repo"
  else
    info "Install complete (verification skipped)."
  fi
}

main "$@"
