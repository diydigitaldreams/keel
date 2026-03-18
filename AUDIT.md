# KEEL Repository Audit

**Date:** 2026-03-18
**Scope:** Full repository audit — structure, code quality, security, robustness

## Overview

KEEL is a zero-install, files-only development framework for AI coding agents. It provides a structured SCOPE → BUILD → SHIP workflow via markdown files and shell scripts. The repo is small (2 commits, ~10 files) and well-focused.

## Structure & Organization — Good

- Clean, minimal file layout matching the project's "files-only" philosophy
- Logical separation: `template/` (user-facing files), `hooks/` (git hooks), root scripts
- `.gitignore` covers OS files, editors, and node_modules

## Documentation — Good

- README is comprehensive with clear examples and compatibility table
- CONTRIBUTING.md sets appropriate boundaries
- CLAUDE.md template is thorough and well-structured
- MIT License present

---

## Issues Found

### Security

#### 1. pre-commit secret pattern `PRIVATE.KEY` is incorrect
**File:** `hooks/pre-commit:29`
**Severity:** Medium

The pattern `'PRIVATE.KEY'` uses a regex dot, which matches any character. It won't match the literal string `PRIVATE KEY` (with a space) as likely intended. It also doesn't catch `PRIVATE_KEY` as an environment variable name.

#### 2. pre-commit secret patterns are incomplete
**File:** `hooks/pre-commit:28-43`
**Severity:** Medium

Missing common secret patterns:
- Google API keys (`AIza`)
- Stripe keys (`sk_live_`, `pk_live_`)
- JWT tokens
- Azure, Heroku, Twilio tokens

#### 3. Incomplete `.env` file detection
**File:** `hooks/pre-commit:65-71`
**Severity:** Medium

Only checks for `.env`, `.env.local`, `.env.production`. Missing `.env.development`, `.env.staging`, `.env.test`, and any other `.env.*` variants. Should use a pattern like `.env*` instead of enumerating specific filenames.

### Shell Script Robustness

#### 4. Unquoted `$STAGED_FILES` in loops
**File:** `hooks/pre-commit:45, 77`
**Severity:** Medium

`for file in $STAGED_FILES` will break on filenames containing spaces. Should use:
```bash
while IFS= read -r file; do ... done <<< "$STAGED_FILES"
```

#### 5. `set -e` in pre-commit hook is risky
**File:** `hooks/pre-commit:7`
**Severity:** Low

Using `set -e` in a git hook means any unexpected command failure silently aborts the hook. Since the hook already tracks `$ERRORS` manually, `set -e` adds risk without benefit. If `git diff --cached` fails unexpectedly, the hook exits without reporting anything.

#### 6. `head -1` is deprecated on some systems
**File:** `hooks/commit-msg:11`
**Severity:** Low

Should use `head -n 1` for POSIX compliance. `head -1` is deprecated on some platforms.

### Functional Issues

#### 7. validate.sh phase extraction can match non-header text
**File:** `validate.sh:69`
**Severity:** Low

The grep pattern `'Phase [0-9]+: .+'` is not anchored to markdown headers. It could match phase references in body text (e.g., "See Phase 1: Foundation for details") rather than just actual phase definitions. Consider anchoring to `^## Phase` or `^### Phase`.

#### 8. setup.sh overwrites CLAUDE.md without backup
**File:** `setup.sh:80`
**Severity:** Low

When re-installing (user confirms overwrite), the existing CLAUDE.md is overwritten with no backup. Any customizations the user added below the KEEL section are lost.

### Missing Features / Polish

#### 9. No `--help` flag on validate.sh
`setup.sh` has `--help` but `validate.sh` does not.

#### 10. Hook files in repo are not executable
The files in `hooks/` are mode `644`. While `setup.sh` sets `chmod +x` during installation, anyone manually copying hooks would need to remember to set permissions.

#### 11. No shellcheck CI
The scripts would benefit from a shellcheck pass. Several issues above (unquoted variables, deprecated `head -1`) would be caught automatically.

#### 12. No `--hooks-only` flag on setup.sh
If hook logic is improved upstream, re-running `setup.sh` also overwrites CLAUDE.md. There's no way to update just the hooks.

---

## Summary

| Category | Rating | Notes |
|----------|--------|-------|
| **Structure** | Strong | Minimal, well-organized |
| **Documentation** | Strong | Clear, comprehensive |
| **Shell scripting** | Moderate | Works but has quoting issues and edge cases |
| **Security hooks** | Moderate | Good foundation, gaps in pattern coverage |
| **Robustness** | Moderate | Fragile parsing in validate.sh, no space handling in hooks |

## Recommended Priority Fixes

1. **Quote `$STAGED_FILES`** in hooks to handle filenames with spaces
2. **Expand `.env` detection** to use a glob pattern instead of enumerating filenames
3. **Remove `set -e`** from pre-commit hook
4. **Fix `PRIVATE.KEY` pattern** to match intended strings
5. **Anchor phase regex** in validate.sh to markdown headers
