#!/bin/bash
# KEEL Setup — Copy template files and git hooks into your project
# Usage: ./setup.sh [target-directory]
#        ./setup.sh --help
#        ./setup.sh --no-hooks [target-directory]
#        ./setup.sh --hooks-only [target-directory]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/template"
HOOKS_DIR="$SCRIPT_DIR/hooks"
INSTALL_HOOKS=true
HOOKS_ONLY=false

# Help
if [ "${1}" = "--help" ] || [ "${1}" = "-h" ]; then
  echo "KEEL Setup"
  echo ""
  echo "Usage: ./setup.sh [options] [target-directory]"
  echo ""
  echo "Options:"
  echo "  --no-hooks    Skip git hook installation"
  echo "  --hooks-only  Only install/update git hooks (skip template files)"
  echo "  --help, -h    Show this help message"
  echo ""
  echo "Installs into your project:"
  echo "  .claude/CLAUDE.md    — AI agent instructions"
  echo "  docs/SCOPE.md        — Project spec (populated during SCOPE)"
  echo "  docs/ROADMAP.md      — Phase roadmap (populated during SCOPE)"
  echo "  docs/phases/         — Phase plans and logs (populated during BUILD)"
  echo "  .git/hooks/          — Commit format and secret detection hooks"
  echo "  validate.sh          — Project state integrity checker"
  echo ""
  echo "If no target directory is given, installs to the current directory."
  exit 0
fi

# Parse flags
if [ "${1}" = "--no-hooks" ]; then
  INSTALL_HOOKS=false
  shift
elif [ "${1}" = "--hooks-only" ]; then
  HOOKS_ONLY=true
  shift
fi

TARGET="${1:-.}"

# Validate target exists
if [ ! -d "$TARGET" ]; then
  echo "Error: Directory '$TARGET' does not exist."
  exit 1
fi

# ─── Hooks-only mode ───
if [ "$HOOKS_ONLY" = true ]; then
  if [ -d "$TARGET/.git" ]; then
    mkdir -p "$TARGET/.git/hooks"
    cp "$HOOKS_DIR/pre-commit" "$TARGET/.git/hooks/pre-commit"
    cp "$HOOKS_DIR/commit-msg" "$TARGET/.git/hooks/commit-msg"
    chmod +x "$TARGET/.git/hooks/pre-commit"
    chmod +x "$TARGET/.git/hooks/commit-msg"
    echo "KEEL git hooks updated in $TARGET"
  else
    echo "Error: $TARGET is not a git repository. Run 'git init' first."
    exit 1
  fi
  exit 0
fi

# Validate template exists
if [ ! -f "$TEMPLATE_DIR/.claude/CLAUDE.md" ]; then
  echo "Error: Template not found. Run this script from the KEEL repo root."
  exit 1
fi

# Check for existing KEEL install
if [ -f "$TARGET/.claude/CLAUDE.md" ] && grep -q "KEEL" "$TARGET/.claude/CLAUDE.md" 2>/dev/null; then
  echo "KEEL is already installed in $TARGET"
  read -p "Overwrite? (y/N): " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted."
    exit 0
  fi
fi

# Warn if .claude/CLAUDE.md exists but isn't KEEL
if [ -f "$TARGET/.claude/CLAUDE.md" ] && ! grep -q "KEEL" "$TARGET/.claude/CLAUDE.md" 2>/dev/null; then
  echo "Warning: $TARGET/.claude/CLAUDE.md already exists with non-KEEL content."
  read -p "Overwrite? (y/N): " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted. You can manually merge the KEEL instructions into your existing CLAUDE.md."
    exit 0
  fi
fi

# ─── Copy template files ───
mkdir -p "$TARGET/.claude"
mkdir -p "$TARGET/docs/phases"

# Back up existing CLAUDE.md before overwriting
if [ -f "$TARGET/.claude/CLAUDE.md" ]; then
  cp "$TARGET/.claude/CLAUDE.md" "$TARGET/.claude/CLAUDE.md.bak"
  echo "Backed up existing CLAUDE.md to CLAUDE.md.bak"
fi

cp "$TEMPLATE_DIR/.claude/CLAUDE.md" "$TARGET/.claude/CLAUDE.md"

# Only copy SCOPE.md and ROADMAP.md if they don't already exist (don't overwrite project state)
if [ ! -f "$TARGET/docs/SCOPE.md" ]; then
  cp "$TEMPLATE_DIR/docs/SCOPE.md" "$TARGET/docs/SCOPE.md"
fi

if [ ! -f "$TARGET/docs/ROADMAP.md" ]; then
  cp "$TEMPLATE_DIR/docs/ROADMAP.md" "$TARGET/docs/ROADMAP.md"
fi

# ─── Copy validation script ───
cp "$SCRIPT_DIR/validate.sh" "$TARGET/validate.sh"
chmod +x "$TARGET/validate.sh"

# ─── Install git hooks ───
if [ "$INSTALL_HOOKS" = true ]; then
  if [ -d "$TARGET/.git" ]; then
    mkdir -p "$TARGET/.git/hooks"
    cp "$HOOKS_DIR/pre-commit" "$TARGET/.git/hooks/pre-commit"
    cp "$HOOKS_DIR/commit-msg" "$TARGET/.git/hooks/commit-msg"
    chmod +x "$TARGET/.git/hooks/pre-commit"
    chmod +x "$TARGET/.git/hooks/commit-msg"
    HOOKS_STATUS="installed"
  else
    HOOKS_STATUS="skipped (not a git repo — run 'git init' first, then re-run setup)"
  fi
else
  HOOKS_STATUS="skipped (--no-hooks)"
fi

echo ""
echo "KEEL installed in $TARGET"
echo ""
echo "  .claude/CLAUDE.md    — the brain (all instructions)"
echo "  docs/SCOPE.md        — project spec"
echo "  docs/ROADMAP.md      — phase roadmap"
echo "  docs/phases/         — phase plans and logs"
echo "  validate.sh          — project state checker"
echo "  git hooks            — ${HOOKS_STATUS}"
echo ""
echo "Open your AI coding agent and say: \"Let's scope this project.\""
