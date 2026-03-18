# Contributing to KEEL

KEEL is intentionally minimal. That's a feature, not a limitation.

## The One Rule

Before proposing a change, ask: **"Does this add a file, or does this add machinery?"**

KEEL is a files-only framework. If your proposal requires a runtime, a CLI tool, a package dependency, or a build step, it doesn't belong in KEEL.

## What's Welcome

- **Bug fixes** in CLAUDE.md logic or workflow gaps
- **Wording improvements** that make agent instructions clearer or more robust
- **Agent compatibility guides** — how to set up KEEL with a new AI coding agent
- **Documentation** — examples, walkthroughs, FAQs
- **Edge case handling** — scope changes, crash recovery, multi-developer workflows

## What's Not

- CLIs, scripts, or tooling that KEEL "needs" to work
- Config file formats (JSON, YAML, TOML) replacing markdown
- Custom command systems of any kind
- Dependency on any specific AI agent's features
- Anything that requires a package manager to use

## How to Contribute

1. Fork the repo
2. Create a branch: `git checkout -b fix/clear-description`
3. Make your changes
4. Test by actually using the modified CLAUDE.md on a real project
5. Submit a PR with a clear description of what changed and why

## Testing Your Changes

The only real test for KEEL is using it. Copy your modified `template/` into a fresh project directory, open your AI agent, and run through a full SCOPE → BUILD → SHIP cycle. If the agent follows the instructions correctly and the output files make sense, it works.

## Code of Conduct

Be direct. Be constructive. Respect that simplicity is a design choice, not a deficiency.
