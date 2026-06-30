# Release Repository Setup

This repository (`ictx-ai/release`) is the public home for downloadable ictx binary tarballs.

## How Releases Are Published

1. Maintainer runs `make release` in the private `ictx-ai/ictx` repo (bumps version, tags, pushes).
2. Tag push triggers CI in `ictx-ai/ictx` — builds three platform tarballs:
   - `ictx-<ver>-linux-x86_64.tar.gz`
   - `ictx-<ver>-linux-aarch64.tar.gz`
   - `ictx-<ver>-darwin-aarch64.tar.gz`
3. CI uploads those assets to a GitHub Release **here** (`ictx-ai/release`) under the same semver tag.

Pushes to `main` alone do **not** publish. Only semver tags do.

`install.sh` downloads from:

`https://github.com/ictx-ai/release/releases/download/<ver>/ictx-<ver>-<platform>-<arch>.tar.gz`

## Required Secret (in the private ictx repository)

In https://github.com/ictx-ai/ictx → Settings → Secrets and variables → Actions, create:

- `PUBLIC_RELEASE_TOKEN`

Use a fine-grained PAT with access **only** to `ictx-ai/release` and **Contents: Read and write**.

(The workflow uses it to publish tarballs to this public repo on tag.)

## Manual / Emergency Publish

In this repo: Actions → "Publish Release" workflow.

Or from a checkout with built tarballs (curl + GitHub REST API — no `gh` CLI):

```bash
export GITHUB_TOKEN="<PAT with contents:write on ictx-ai/release>"
cat > /tmp/release-notes.md <<'EOF'
ictx 0.5.0

Install:
curl -fsSL https://raw.githubusercontent.com/ictx-ai/release/main/install.sh | bash
EOF
./scripts/github-release-publish.sh \
  --repo ictx-ai/release \
  --tag 0.5.0 \
  --title "ictx 0.5.0" \
  --notes-file /tmp/release-notes.md \
  dist/ictx-0.5.0-*.tar.gz
```

After publishing, users can run the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/ictx-ai/release/main/install.sh | bash
```

## Verifying a Release

```bash
curl -fsSL "https://api.github.com/repos/ictx-ai/release/releases/tags/0.5.0" | jq '.assets[].name'
curl -fL -o /tmp/ictx.tgz \
  "https://github.com/ictx-ai/release/releases/download/0.5.0/ictx-0.5.0-darwin-aarch64.tar.gz"
```

See the installer behavior in [README](./README.md).
