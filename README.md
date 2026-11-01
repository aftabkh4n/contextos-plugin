# ContextOS Claude Code Plugin

Gives Claude Code persistent memory across sessions.

## Install

```
/plugin marketplace add aftabkh4n/contextos
/plugin install contextos@contextos
```

The plugin downloads the right binary for your platform on first use.

After updating, if contextos shows as failed in `/mcp`, choose Reconnect.
This happens once per update while the new version downloads.

## What it does

- Stores decisions, todos, notes, and skills in a local SQLite database
- Injects workspace context at session start (auto-hydration)
- Searches memory with hybrid BM25 + vector search
- Supports cross-workspace search with `scope="global"`

## Platform support

The plugin works on macOS, Linux and Windows. Git Bash is not required
on Windows.

The SessionStart hook runs one command that every shell Claude Code uses
can read: `sh` on macOS and Linux, Git Bash on Windows when it is
installed, and PowerShell on Windows when it is not.

- `scripts/ensure-binary.sh` installs the binary on macOS, Linux and
  Git Bash.
- `scripts/ensure-binary.ps1` installs it on Windows through Windows
  PowerShell 5.1, which every Windows 10 and 11 machine has.

Both scripts use the same folders and the same `.version` file, so when
both run on a Windows machine with Git Bash, the second one sees the
install is done and exits.

## Manual install (alternative)

If you prefer not to use the plugin system:

macOS / Linux:
```
curl -fsSL https://raw.githubusercontent.com/aftabkh4n/contextos/main/install.sh | bash
```

Windows (PowerShell):
```
irm https://raw.githubusercontent.com/aftabkh4n/contextos/main/install.ps1 | iex
```

## Privacy

ContextOS keeps your data on your machine and collects no telemetry. See
[PRIVACY.md](PRIVACY.md) for what it stores, reads, and sends.

## Source

ContextOS source code and binary releases live in
https://github.com/aftabkh4n/contextos. This repository holds only the
plugin, and the install commands above read it through the marketplace in
that repository.

## Releasing

1. Publish the ContextOS release in the main repository first.
2. Then bump `version` in `.claude-plugin/plugin.json` and the matching
   `bin/<version>` folder in the MCP command.

CI fails if the MCP command does not match the version, or if the
release for that version has no `contextos-win-x64.zip` asset.
