# Release Repository Setup

This repository (`ictx-ai/release`) is the public home for downloadable ictx binary tarballs.

## How Releases Are Published

1. Maintainer runs `make release` in the private `ictx-ai/ictx` repo (bumps version, tags, pushes).
2. Tag push triggers CI in `ictx-ai/ictx` — builds three platform tarballs:
   - `ictx-<ver>-linux-x86_64.tar.gz`
   - `ictx-<ver>-darwin-aarch64.tar.gz`
   - `ictx-<ver>-darwin-x86_64.tar.gz`
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

Or from a checkout with built tarballs:

```bash
gh release create "0.5.0" --repo ictx-ai/release --title "ictx 0.5.0"
gh release upload "0.5.0" dist/*.tar.gz --repo ictx-ai/release --clobber
```

After publishing, users can run the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/ictx-ai/release/main/install.sh | bash
```

## Verifying a Release

```bash
gh release view 0.5.0 --repo ictx-ai/release
gh release download 0.5.0 --repo ictx-ai/release --pattern '*darwin-aarch64*'
```

See the installer behavior in [README](./README.md).
