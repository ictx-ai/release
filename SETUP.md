# Release Repository Setup

This repository (`ictx-ai/release`) is the public home for downloadable ictx binary tarballs.

**No repository secrets are required.** Publishing uses this repo's built-in `GITHUB_TOKEN`.

## How Releases Are Published

1. Maintainer runs `make release` in `ictx-ai/ictx` (bumps version, tags, pushes).
2. Tag push triggers CI in `ictx-ai/ictx` — builds three platform tarballs and uploads them as workflow artifacts.
3. That workflow sends `repository_dispatch` to **this repo**.
4. The **Publish Release** workflow here downloads those artifacts and creates the GitHub Release.

Pushes to `main` alone do **not** publish. Only semver tags do.

### One-time org setting (if artifact download fails)

In **ictx-ai/release** → Settings → Actions → General → **Workflow permissions**:

- Allow GitHub Actions to read **actions** and **contents** from other repositories in the organization (so this workflow can download artifacts from `ictx-ai/ictx`).

No `PUBLIC_RELEASE_TOKEN` or other secrets on either repository.

## Manual / Emergency Publish

Actions → **Publish Release** → enter version, with tarballs already in `dist/` from a manual upload step.

Or from a checkout with built tarballs:

```bash
export GITHUB_TOKEN="<your token with contents:write on this repo>"
./scripts/github-release-publish.sh \
  --repo ictx-ai/release \
  --tag 0.5.0 \
  --title "ictx 0.5.0" \
  --notes-file /tmp/notes.md \
  dist/ictx-0.5.0-*.tar.gz
```

## Verifying a Release

```bash
curl -fsSL "https://api.github.com/repos/ictx-ai/release/releases/tags/0.5.0" | jq '.assets[].name'
curl -fL -o /tmp/ictx.tgz \
  "https://github.com/ictx-ai/release/releases/download/0.5.0/ictx-0.5.0-darwin-aarch64.tar.gz"
```

See [README](./README.md) for install instructions.