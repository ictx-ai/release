#!/usr/bin/env bash
# install.sh — one-liner installer for ictx binary releases
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ictx-ai/release/main/install.sh | bash
#
# Installs the latest release into $HOME/.local/bin (flat layout).
# Rules ship next to binaries so sense finds them automatically.
#
# Options (environment):
#   VERSION=...        Pin a release tag (default: latest from GitHub)
#   PLATFORM=...       Override (linux|darwin)
#   ARCH=...           Override (x86_64|aarch64)
#   NO_VERIFY=1        Skip post-install smoke checks
#   SKIP_SHA=1         Skip tarball checksum verification (not recommended)

set -euo pipefail

REPO="ictx-ai/release"
BIN_DIR="${HOME}/.local/bin"

VERSION="${VERSION:-}"
PLATFORM="${PLATFORM:-}"
ARCH="${ARCH:-}"
NO_VERIFY="${NO_VERIFY:-0}"
SKIP_SHA="${SKIP_SHA:-0}"

die() { echo "ictx install: error: $*" >&2; exit 1; }
note() { echo "ictx install: $*"; }

detect_platform() {
  local uname_s uname_m
  uname_s="$(uname -s)"
  uname_m="$(uname -m)"

  case "$uname_s" in
    Linux)  PLATFORM="linux" ;;
    Darwin) PLATFORM="darwin" ;;
    *) die "unsupported OS: $uname_s" ;;
  esac

  case "$uname_m" in
    x86_64|amd64) ARCH="x86_64" ;;
    arm64|aarch64) ARCH="aarch64" ;;
    *) die "unsupported architecture: $uname_m" ;;
  esac
}

resolve_latest_version() {
  command -v curl >/dev/null 2>&1 || return 0
  curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null \
    | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4 || true
}

ensure_version() {
  [[ -n "$VERSION" ]] && return 0
  VERSION="$(resolve_latest_version || true)"
  [[ -n "$VERSION" ]] || die "could not determine latest release from GitHub"
}

download() {
  local url="$1" dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "$dest" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$dest" "$url"
  else
    die "need curl or wget"
  fi
}

verify_sha256() {
  local file="$1" sum_file="$2"
  [[ -f "$sum_file" ]] || die "checksum file missing: $sum_file"
  local dir base
  dir="$(cd "$(dirname "$file")" && pwd)"
  base="$(basename "$file")"
  # Normalize checksum line to the local basename (publish uses tarball basename).
  local expected
  expected="$(awk '{print $1}' "$sum_file")"
  [[ -n "$expected" ]] || die "empty checksum file"
  local actual
  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$file" | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    actual="$(shasum -a 256 "$file" | awk '{print $1}')"
  else
    die "need sha256sum or shasum to verify download"
  fi
  if [[ "$actual" != "$expected" ]]; then
    die "checksum mismatch for ${base} (expected ${expected}, got ${actual})"
  fi
  note "checksum verified (${base})"
}

main() {
  [[ -z "$PLATFORM" || -z "$ARCH" ]] && detect_platform
  ensure_version

  local pkg_name="ictx-${VERSION}-${PLATFORM}-${ARCH}"
  local tarball="${pkg_name}.tar.gz"
  local url="https://github.com/${REPO}/releases/download/${VERSION}/${tarball}"
  local sha_url="${url}.sha256"

  note "installing ${VERSION} (${PLATFORM}-${ARCH}) → ${BIN_DIR}"

  local tmpdir
  tmpdir="$(mktemp -d)"
  trap "rm -rf '${tmpdir}'" EXIT

  local tar_path="${tmpdir}/${tarball}"
  local sha_path="${tmpdir}/${tarball}.sha256"

  download "$url" "$tar_path"

  if [[ "$SKIP_SHA" != "1" ]]; then
    if download "$sha_url" "$sha_path" 2>/dev/null; then
      verify_sha256 "$tar_path" "$sha_path"
    else
      note "warning: no ${tarball}.sha256 on release — skipping checksum (use SKIP_SHA=1 to silence)"
    fi
  fi

  mkdir -p "$tmpdir/extract"
  tar -xzf "$tar_path" -C "$tmpdir/extract"

  local extracted_dir="${tmpdir}/extract/${pkg_name}"
  [[ -d "$extracted_dir" ]] || die "unexpected tarball layout (missing ${pkg_name}/)"

  mkdir -p "$BIN_DIR"

  for b in sense pulse lens config-extractor python-extractor java-extractor; do
    if [[ -f "${extracted_dir}/bin/${b}" ]]; then
      cp -f "${extracted_dir}/bin/${b}" "${BIN_DIR}/${b}"
      chmod +x "${BIN_DIR}/${b}" || true
    fi
  done

  if [[ -d "${extracted_dir}/bin/java-extractor-libs" ]]; then
    rm -rf "${BIN_DIR}/java-extractor-libs"
    cp -R "${extracted_dir}/bin/java-extractor-libs" "${BIN_DIR}/"
  fi

  if [[ -d "${extracted_dir}/rules" ]]; then
    rm -rf "${BIN_DIR}/rules"
    cp -R "${extracted_dir}/rules" "${BIN_DIR}/"
  fi

  if [[ "$NO_VERIFY" != "1" ]]; then
    if [[ ! -x "${BIN_DIR}/sense" ]]; then
      die "sense binary missing after install"
    fi
    if [[ ! -d "${BIN_DIR}/rules/opengrep/core" ]]; then
      note "warning: rules/opengrep/core not found — install opengrep rules or set ICTX_RULES_ROOT"
    fi
  fi

  cat <<EOF

ictx ${VERSION} installed to ${BIN_DIR}

Add to your shell profile (if needed):
  export PATH="\$HOME/.local/bin:\$PATH"

Scan a repository (index → opengrep → investigate → ~/.ictx/<project>/):
  sense run /path/to/your/repo

Review findings after a scan (project name = repo directory basename):
  lens <project>

More help:
  sense --help
  lens --help

Prerequisites: Java 17+ (java-extractor), opengrep or semgrep on PATH.
EOF
}

main "$@"
