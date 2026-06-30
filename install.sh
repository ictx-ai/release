#!/usr/bin/env bash
# install.sh — one-liner installer for ictx binary releases
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ictx-ai/release/main/install.sh | bash
#
# Options (environment):
#   VERSION=0.4.2          Install specific version (default: latest)
#   PREFIX=$HOME/bin       Install prefix (the tarball contents go under $PREFIX)
#   PLATFORM=...           Override (linux|darwin)
#   ARCH=...               Override (x86_64|aarch64)
#   NO_VERIFY=1            Skip the post-install sanity checks
#
# After install:
#   export PATH="$HOME/bin:$PATH"
#   export ICTX_RULES_ROOT="$HOME/bin/rules"
#   sense -V

set -euo pipefail

REPO="ictx-ai/release"
DEFAULT_PREFIX="${HOME}/bin"

VERSION="${VERSION:-}"
PREFIX="${PREFIX:-$DEFAULT_PREFIX}"
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

# If no version given, try to pick latest; fall back to asking user
ensure_version() {
  if [[ -z "$VERSION" ]]; then
    info "No VERSION specified, trying to detect latest release..."
    local latest
    latest="$(resolve_latest_version || true)"
    if [[ -n "$latest" ]]; then
      VERSION="$latest"
      info "Latest release: $VERSION"
    else
      die "Could not determine latest version. Set VERSION=x.y.z explicitly."
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
  info "Target prefix: ${PREFIX}"

  mkdir -p "${PREFIX}"

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

  info "Extracting to ${PREFIX}"
  tar -xzf "${tar_path}" -C "${PREFIX}"

  local extracted_dir="${PREFIX}/${pkg_name}"
  if [[ ! -d "$extracted_dir" ]]; then
    # Some releases may contain the dir at top level already
    extracted_dir="${PREFIX}/ictx-${VERSION}-${PLATFORM}-${ARCH}"
  fi

  if [[ ! -d "$extracted_dir" ]]; then
    # List what we got
    ls -la "${PREFIX}" | head -20
    die "Expected ${pkg_name}/ after extraction but did not find it under ${PREFIX}"
  fi

  # Symlink convenience: put the bins + rules at top of PREFIX when possible
  info "Creating convenience symlinks in ${PREFIX}"
  mkdir -p "${PREFIX}/bin" "${PREFIX}/rules"
  # Copy (or link) the executables
  for b in sense pulse lens config-extractor python-extractor java-extractor; do
    if [[ -f "${extracted_dir}/bin/${b}" ]]; then
      ln -sf "${extracted_dir}/bin/${b}" "${PREFIX}/bin/${b}" || cp -f "${extracted_dir}/bin/${b}" "${PREFIX}/bin/${b}"
      chmod +x "${PREFIX}/bin/${b}" || true
    fi
  done
  # java-extractor-libs
  if [[ -d "${extracted_dir}/bin/java-extractor-libs" ]]; then
    rm -rf "${PREFIX}/bin/java-extractor-libs"
    cp -R "${extracted_dir}/bin/java-extractor-libs" "${PREFIX}/bin/"
  fi
  # rules
  if [[ -d "${extracted_dir}/rules" ]]; then
    rm -rf "${PREFIX}/rules"
    cp -R "${extracted_dir}/rules" "${PREFIX}/"
  fi

  if [[ "$NO_VERIFY" != "1" ]]; then
    info "Verifying installation..."
    export PATH="${PREFIX}/bin:${PATH}"
    export ICTX_RULES_ROOT="${PREFIX}/rules"

    if command -v sense >/dev/null 2>&1; then
      sense -V || true
    else
      echo "WARN: sense not found on PATH yet"
    fi

    if [[ -f "${PREFIX}/rules/opengrep/core/ictx-rules.yaml" ]]; then
      echo "  rules present: OK"
    else
      echo "  WARN: rules/opengrep/core/ictx-rules.yaml not found under ${PREFIX}/rules"
    fi

    echo ""
    echo "Done. Add to your shell profile (if not already):"
    echo "  export PATH=\"${PREFIX}/bin:\$PATH\""
    echo "  export ICTX_RULES_ROOT=\"${PREFIX}/rules\""
    echo ""
    echo "Then run:"
    echo "  sense run /path/to/a/repo"
  else
    info "Install complete (verification skipped)."
  fi
}

main "$@"
