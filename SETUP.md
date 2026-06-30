# Release Repository Setup

This repository (`ictx-ai/release`) is the public home for downloadable ictx binary tarballs.

## How Releases Are Published

1. A maintainer runs `make release` (or `BUMP=minor make release`) in the `ictx` monorepo.
   - This bumps versions, commits, tags (e.g. `0.5.0`), and pushes the tag.
2. GitHub Actions in `ictx-ai/ictx` (see `.github/workflows/release.yml`) sees the tag push.
3. It builds the three supported platforms, packages tarballs, and publishes a proper GitHub Release **in this repository** (`ictx-ai/release`).

Snapshots from `main` continue to be published as pre-releases inside the `ictx` repository for developers.

## Required Secret (in the ictx repository)

In the **ictx** repository settings → Secrets and variables → Actions, create:

- `PUBLIC_RELEASE_TOKEN`

This token must have permission to create releases and upload assets to `ictx-ai/release`.

Recommended: a fine-grained personal access token (PAT) scoped only to the `ictx-ai/release` repository with "Contents: Read and write".

You can also name it differently and update the workflow.

## Manual / Emergency Publish

Use the "Publish Release" workflow in this repository (Actions → Publish Release) and provide the version.

You can also run from a machine that has the built `dist/*.tar.gz`:

```bash
VERSION=0.5.0
gh release create "$VERSION" --repo ictx-ai/release --title "ictx $VERSION"
gh release upload "$VERSION" dist/*.tar.gz --repo ictx-ai/release --clobber
```

Or use the one-liner installer flow after the release exists:

```bash
curl -fsSL https://raw.githubusercontent.com/ictx-ai/release/main/install.sh | bash
```

## Adding a New Platform

Extend the matrix in `ictx/.github/workflows/release.yml` and update `helpers/package-dist.sh` if needed.

## Verifying a Release

After a release is published:

```bash
gh release view 0.5.0 --repo ictx-ai/release
gh release download 0.5.0 --repo ictx-ai/release --pattern '*darwin-aarch64*'
tar -tzf ictx-0.5.0-darwin-aarch64.tar.gz | head
```

Then follow the main [README](./README.md).
