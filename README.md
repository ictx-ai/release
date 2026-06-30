# ICTX

Binary releases for the ictx security tooling suite.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ictx-ai/release/main/install.sh | bash
```

Downloads are verified against `ictx-*-<platform>-<arch>.tar.gz.sha256` when published with the release.

## Prerequisites

- Java 17+ (for `java-extractor` on JVM repos)
- [opengrep](https://github.com/opengrep/opengrep) or semgrep on `$PATH`

## After install

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Scan a repo

`sense` indexes the repo, runs opengrep, investigates findings, and writes artifacts under `~/.ictx/<project>/`:

```bash
sense run /path/to/your/repo
```

### Review findings

After a scan, use `lens` with the project name (usually the repo directory basename):

```bash
lens my-repo
```

## Updating

Re-run the one-liner installer.

## Troubleshooting

- Ensure `~/.local/bin` is on your `PATH`.
- Rules ship next to the binaries under `~/.local/bin/rules/`.
- Set `SKIP_SHA=1` only if installing an older release without a checksum file.

## License

MIT License.