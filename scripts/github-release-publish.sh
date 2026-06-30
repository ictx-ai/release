#!/usr/bin/env bash
# Publish a GitHub Release and upload assets via the REST API (curl only).
#
# Usage:
#   GITHUB_TOKEN=... ./helpers/github-release-publish.sh \
#     --repo owner/repo --tag 0.5.3 --title "ictx 0.5.3" \
#     --notes-file release-notes.md dist/*.tar.gz
#
# Env:
#   GITHUB_TOKEN or PUBLIC_RELEASE_TOKEN — token with contents:write on --repo
set -euo pipefail

API_VERSION="2022-11-28"
REPO=""
TAG=""
TITLE=""
NOTES_FILE=""
PRERELEASE="false"
ASSETS=()

die() { echo "ERROR: $*" >&2; exit 1; }

usage() {
  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:?}"; shift 2 ;;
    --tag) TAG="${2:?}"; shift 2 ;;
    --title) TITLE="${2:?}"; shift 2 ;;
    --notes-file) NOTES_FILE="${2:?}"; shift 2 ;;
    --prerelease) PRERELEASE="true"; shift ;;
    -h|--help) usage ;;
    --) shift; ASSETS+=("$@"); break ;;
    -*) die "unknown option: $1" ;;
    *) ASSETS+=("$1"); shift ;;
  esac
done

[[ -n "$REPO" && -n "$TAG" && -n "$TITLE" && -n "$NOTES_FILE" ]] || usage
[[ -f "$NOTES_FILE" ]] || die "notes file not found: $NOTES_FILE"

TOKEN="${GITHUB_TOKEN:-${PUBLIC_RELEASE_TOKEN:-}}"
[[ -n "$TOKEN" ]] || die "GITHUB_TOKEN or PUBLIC_RELEASE_TOKEN is required"

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v jq >/dev/null 2>&1 || die "jq is required"

api() {
  local method="$1" url="$2"
  shift 2
  curl -fsS -X "$method" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: ${API_VERSION}" \
    "$@" \
    "$url"
}

get_release_by_tag() {
  local code body
  body="$(mktemp)"
  code="$(curl -sS -o "$body" -w '%{http_code}' \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: ${API_VERSION}" \
    "https://api.github.com/repos/${REPO}/releases/tags/${TAG}")"
  if [[ "$code" == "200" ]]; then
    cat "$body"
  elif [[ "$code" == "404" ]]; then
    return 1
  else
    echo "GitHub API GET release returned HTTP ${code}:" >&2
    cat "$body" >&2
    return 1
  fi
}

create_release() {
  local payload
  payload="$(jq -n \
    --arg tag "$TAG" \
    --arg name "$TITLE" \
    --arg body "$(<"$NOTES_FILE")" \
    --argjson prerelease "$PRERELEASE" \
    '{tag_name: $tag, name: $name, body: $body, prerelease: $prerelease, generate_release_notes: false}')"
  api POST "https://api.github.com/repos/${REPO}/releases" \
    -H "Content-Type: application/json" \
    -d "$payload"
}

delete_asset() {
  local asset_id="$1"
  api DELETE "https://api.github.com/repos/${REPO}/releases/assets/${asset_id}" >/dev/null
}

upload_asset() {
  local upload_url="$1" file="$2"
  local name size
  name="$(basename "$file")"
  [[ -f "$file" ]] || die "asset not found: $file"
  size="$(wc -c <"$file" | tr -d ' ')"
  upload_url="${upload_url%\{*}"
  echo "  uploading ${name} (${size} bytes)"
  curl -fsS -X POST \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/gzip" \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Length: ${size}" \
    --data-binary @"$file" \
    "${upload_url}?name=${name}"
}

if release_json="$(get_release_by_tag 2>/dev/null)"; then
  echo "Release ${TAG} already exists in ${REPO}"
else
  echo "Creating release ${TAG} in ${REPO} ..."
  release_json="$(create_release)"
fi

release_id="$(jq -r '.id' <<<"$release_json")"
upload_base="$(jq -r '.upload_url' <<<"$release_json")"
[[ "$release_id" != "null" && -n "$upload_base" && "$upload_base" != "null" ]] \
  || die "could not resolve release id / upload_url"

if [[ ${#ASSETS[@]} -eq 0 ]]; then
  shopt -s nullglob
  ASSETS=(dist/ictx-*.tar.gz)
fi

if [[ ${#ASSETS[@]} -eq 0 ]]; then
  die "no assets to upload"
fi

echo "Uploading ${#ASSETS[@]} asset(s) to ${REPO}@${TAG}:"
for file in "${ASSETS[@]}"; do
  name="$(basename "$file")"
  existing_id="$(jq -r --arg name "$name" '.assets[]? | select(.name == $name) | .id' <<<"$release_json" | head -1)"
  if [[ -n "$existing_id" && "$existing_id" != "null" ]]; then
    echo "  replacing existing asset ${name}"
    delete_asset "$existing_id"
  fi
  upload_asset "$upload_base" "$file"
done

echo "Published: https://github.com/${REPO}/releases/tag/${TAG}"
