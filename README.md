# ictx

Binary releases for the ictx security tooling suite.

**Public downloads:** https://github.com/ictx-ai/release/releases

One-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/ictx-ai/release/main/install.sh | bash
```

## Prerequisites

- **Java 17+** (required for `java-extractor` and Java indexing)
- **opengrep** (or semgrep) — the SAST scanner used by default
  - Recommended: [opengrep](https://github.com/opengrep/opengrep) or official semgrep
  - Must be on your `PATH`

## Quick Install

### Using the installer (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/ictx-ai/release/main/install.sh | bash
```

This downloads the latest release for your platform, extracts it, and installs the tools where they will be found automatically:

- `~/.local/bin` (if `~/.local/bin` is already in your `PATH`)
- `~/bin` (otherwise)

It then prints the exact `PATH` and `ICTX_RULES_ROOT` lines you should add.

### Manual install

1. Download the right tarball for your platform from [Releases](https://github.com/ictx-ai/release/releases).

2. Extract into a common location on your PATH (example):

```bash
# ~/bin (common)
mkdir -p ~/bin
tar -xzf ictx-*-darwin-aarch64.tar.gz -C ~/bin

# or ~/.local (if you have ~/.local/bin in PATH)
mkdir -p ~/.local
tar -xzf ictx-*-darwin-aarch64.tar.gz -C ~/.local
```

The tarball contains a versioned directory, e.g. `ictx-0.4.2-darwin-aarch64/`.

After extraction you will have:

```
ictx-0.4.2-darwin-aarch64/
├── bin/
│   ├── sense
│   ├── pulse
│   ├── lens
│   ├── config-extractor
│   ├── python-extractor
│   ├── java-extractor
│   └── java-extractor-libs/   (JARs)
├── rules/
│   └── opengrep/
│       └── core/
│           └── ictx-rules.yaml
├── MANIFEST.txt
└── README.txt
```

3. Symlink or extend PATH + set rules (the installer does this for you):

```bash
# Example for ~/bin
export PATH="$HOME/bin:$PATH"
export ICTX_RULES_ROOT="$HOME/bin/rules"

# or for ~/.local
export PATH="$HOME/.local/bin:$PATH"
export ICTX_RULES_ROOT="$HOME/.local/rules"
```


The tarball contains a versioned directory. After manual extraction you can either:

- Add the versioned `bin/` directory to PATH temporarily, or
- Symlink the binaries into a dir that's already on your PATH (e.g. `~/bin` or `~/.local/bin`) and point `ICTX_RULES_ROOT` at the extracted `rules/`.

Verify:

```bash
sense -V
java -version
which opengrep || which semgrep
```

## Usage

### sense — main analysis engine

```bash
# Run the full pipeline on a repo (index + extract + scan + filters)
sense run /path/to/your/source

# Force fresh rebuild
sense run /path/to/source --force

# Use semgrep instead of opengrep
sense run /path/to/source --scanner semgrep

# Only selected filters
sense run /path/to/source --filters cwe-470,cwe-89
```

See `sense --help` and `sense run --help` for all options.

Common environment variables:

- `ICTX_RULES_ROOT` — directory containing `rules/opengrep/core/ictx-rules.yaml`
- `ICTX_OUTPUT_ROOT` — where sense writes per-repo artifacts (default `~/oss`)

### lens — interactive TUI viewer for findings

```bash
lens /path/to/corpus-or-findings
```

### pulse — runtime fingerprinter / agent

```bash
pulse
```

Runs as a long-lived agent (see `pulse` docs in source for control-plane usage).

### Other tools

- `config-extractor` — extracts framework configuration for analysis
- `python-extractor` — Python semantic indexer (tree-sitter based)
- `java-extractor` — Java semantic indexer (JDT based, invoked via wrapper)

## Updating

Run the installer again:

```bash
curl -fsSL https://raw.githubusercontent.com/ictx-ai/release/main/install.sh | bash
```

It will install the new version alongside the old one and update the symlinks in `~/bin` or `~/.local/bin`.

## Troubleshooting

**"Java not found"**

Install Temurin / Adoptium / your distro's OpenJDK 17+ and ensure `java` is on PATH (or set `JAVA_HOME`).

**"opengrep: command not found" / scanner failures**

```bash
# macOS example
brew install opengrep
# or
pipx install semgrep
```

Make sure the binary name is `opengrep` or `semgrep`.

**Rules not found**

Ensure `ICTX_RULES_ROOT` points at the extracted `rules/` directory (must contain `opengrep/core/ictx-rules.yaml`).

**Permission denied on binaries**

```bash
chmod +x ~/bin/ictx-*/bin/*
```

## Release Process (for maintainers)

- Creating a tag (e.g. `0.5.0`) on https://github.com/ictx-ai/ictx automatically triggers a build and creates a release here with all platform tarballs attached.
- See `SETUP.md`, `.github/workflows/publish.yml` (this repo) and `.github/workflows/release.yml` (ictx monorepo).
- The `helpers/release.sh` script (and `make release`) in the ictx repo is the official way to cut releases.

## License

See the ictx source repository for license information.
