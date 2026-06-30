# ICTX

Binary releases for the ictx security tooling suite.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ictx-ai/release/main/install.sh | bash
```

## Prerequisites

- Java 17+
- opengrep or semgrep in `$PATH`

## After install

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Verify:

```bash
sense -V
```

## Usage

```bash
sense run /path/to/source
```

See `sense --help` for details.

## Updating

Re-run the one-liner installer.

## Troubleshooting

- Java 17+ required.
- opengrep/semgrep must be installed and in PATH.
- Rules are shipped next to the binaries.

## License

ICTX is licensed under the MIT License.
