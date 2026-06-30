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

```bash
curl -fsSL https://raw.githubusercontent.com/ictx-ai/release/main/install.sh | bash
```

The installer always downloads the latest release and installs the tools **directly** into `~/.local/bin/`.

No versioned directories. The `rules/` directory is placed next to the binaries (`~/.local/bin/rules/`) so sense finds them automatically.

### After install

Add to your shell profile (e.g. `~/.zshrc` or `~/.bash_profile`):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then:

```bash
sense -V
```

### Manual install (without the script)

1. Download a **platform tarball** from [Releases](https://github.com/ictx-ai/release/releases) — the file named `ictx-<version>-<platform>-<arch>.tar.gz`. Ignore any GitHub **Source code (zip/tar.gz)** entries; those are auto-generated repo snapshots, not the binary distribution.

2. Extract the contents and place them directly (rules go next to the binaries):

```bash
tar -xzf ictx-*-darwin-aarch64.tar.gz
cd ictx-*-darwin-aarch64

mkdir -p ~/.local/bin
cp bin/* ~/.local/bin/
cp -r bin/java-extractor-libs ~/.local/bin/
cp -r rules ~/.local/bin/

chmod +x ~/.local/bin/sense ~/.local/bin/pulse ~/.local/bin/lens \
         ~/.local/bin/config-extractor ~/.local/bin/python-extractor \
         ~/.local/bin/java-extractor
```

3. Set the environment as above.

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

Just re-run the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/ictx-ai/release/main/install.sh | bash
```

It replaces the binaries in `~/.local/bin/` with the latest version.

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

The installer puts `rules/` directly next to the binaries in `~/.local/bin/rules/`.
Sense looks there automatically (next to the executable).

**Permission denied on binaries**

```bash
chmod +x ~/.local/bin/sense ~/.local/bin/pulse ~/.local/bin/lens ...
```

## Release Process (for maintainers)

See [SETUP.md](./SETUP.md).

## License

See the ictx source repository for license information.
