# Release Repository Setup

This repository (`ictx-ai/release`) is the public home for downloadable ictx binary tarballs.

## How Releases Are Published

- A maintainer creates a semver tag in the private `ictx-ai/ictx` repo (via `make release`).
- CI builds for linux + darwin (x86_64 + aarch64).
- Official releases (with platform tarballs) are published here in the public `ictx-ai/release` repo.

Main branch builds produce snapshot pre-releases in the private repo only.

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
