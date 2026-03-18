#!/bin/bash
# KEEL Validate — Check project state integrity
# Usage: ./validate.sh [project-directory]
#
# Checks:
#   - Required files exist
#   - Every roadmap phase has a directory
#   - Every phase directory has PLAN.md and LOG.md
#   - No orphaned phase directories
#   - Phase statuses are consistent with LOG.md content

set -e

# Help
if [ "${1}" = "--help" ] || [ "${1}" = "-h" ]; then
  echo "KEEL Validate — Check project state integrity"
  echo ""
  echo "Usage: ./validate.sh [project-directory]"
  echo ""
  echo "Checks:"
  echo "  - Required files exist (.claude/CLAUDE.md, docs/SCOPE.md, docs/ROADMAP.md)"
  echo "  - Every roadmap phase has a matching directory"
  echo "  - Every phase directory has PLAN.md and LOG.md"
  echo "  - No orphaned phase directories"
  echo "  - Phase statuses are consistent with LOG.md content"
  echo ""
  echo "If no project directory is given, validates the current directory."
  exit 0
fi

TARGET="${1:-.}"

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo ""
echo -e "${BLUE}[KEEL] Validating project: ${TARGET}${NC}"
echo ""

# ─── 1. Required files ───

check_file() {
  if [ -f "$TARGET/$1" ]; then
    echo -e "  ${GREEN}✓${NC} $1"
  else
    echo -e "  ${RED}✗${NC} $1 — missing"
    ERRORS=$((ERRORS + 1))
  fi
}

echo "Core files:"
check_file ".claude/CLAUDE.md"
check_file "docs/SCOPE.md"
check_file "docs/ROADMAP.md"
echo ""

# ─── 2. CLAUDE.md contains KEEL ───

if [ -f "$TARGET/.claude/CLAUDE.md" ]; then
  if ! grep -q "KEEL" "$TARGET/.claude/CLAUDE.md" 2>/dev/null; then
    echo -e "  ${YELLOW}!${NC} .claude/CLAUDE.md exists but doesn't contain KEEL instructions"
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# ─── 3. SCOPE.md populated ───

if [ -f "$TARGET/docs/SCOPE.md" ]; then
  # Check if it's still the empty template
  if grep -q "^# Project Name$" "$TARGET/docs/SCOPE.md" 2>/dev/null; then
    echo -e "  ${YELLOW}!${NC} docs/SCOPE.md is still the empty template — run SCOPE first"
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# ─── 4. Roadmap / phase directory consistency ───

if [ -f "$TARGET/docs/ROADMAP.md" ]; then
  # Extract phase numbers and names from roadmap (anchored to markdown headers)
  ROADMAP_PHASES=$(grep -E '^#{1,3} Phase [0-9]+: .+' "$TARGET/docs/ROADMAP.md" 2>/dev/null | sed 's/^#* //' || true)

  if [ -n "$ROADMAP_PHASES" ]; then
    echo "Phases:"

    while IFS= read -r phase_line; do
      # Extract phase number
      PHASE_NUM=$(echo "$phase_line" | grep -oE '[0-9]+' | head -n 1)
      PHASE_NUM_PADDED=$(printf "%02d" "$PHASE_NUM")

      # Find matching directory
      PHASE_DIR=$(find "$TARGET/docs/phases" -maxdepth 1 -type d -name "${PHASE_NUM_PADDED}-*" 2>/dev/null | head -n 1)

      # Get status from roadmap
      STATUS=$(grep -F -A2 "$phase_line" "$TARGET/docs/ROADMAP.md" | grep -oE '(pending|active|complete)' | head -n 1)
      STATUS="${STATUS:-unknown}"

      if [ -n "$PHASE_DIR" ]; then
        PHASE_NAME=$(basename "$PHASE_DIR")
        HAS_PLAN=$( [ -f "$PHASE_DIR/PLAN.md" ] && echo "yes" || echo "no" )
        HAS_LOG=$( [ -f "$PHASE_DIR/LOG.md" ] && echo "yes" || echo "no" )

        if [ "$STATUS" = "complete" ]; then
          # Complete phase — should have both files and a phase summary in LOG
          if [ "$HAS_PLAN" = "yes" ] && [ "$HAS_LOG" = "yes" ]; then
            if grep -q "Phase Summary" "$PHASE_DIR/LOG.md" 2>/dev/null; then
              echo -e "  ${GREEN}✓${NC} Phase ${PHASE_NUM_PADDED} [complete] — ${PHASE_NAME}"
            else
              echo -e "  ${YELLOW}!${NC} Phase ${PHASE_NUM_PADDED} [complete] — LOG.md missing phase summary"
              WARNINGS=$((WARNINGS + 1))
            fi
          else
            echo -e "  ${RED}✗${NC} Phase ${PHASE_NUM_PADDED} [complete] — missing PLAN.md or LOG.md"
            ERRORS=$((ERRORS + 1))
          fi

        elif [ "$STATUS" = "active" ]; then
          echo -e "  ${BLUE}→${NC} Phase ${PHASE_NUM_PADDED} [active] — ${PHASE_NAME} (PLAN: ${HAS_PLAN}, LOG: ${HAS_LOG})"

        elif [ "$STATUS" = "pending" ]; then
          echo -e "  ${NC}○${NC} Phase ${PHASE_NUM_PADDED} [pending] — ${PHASE_NAME}"
          if [ "$HAS_PLAN" = "yes" ] || [ "$HAS_LOG" = "yes" ]; then
            echo -e "    ${YELLOW}!${NC} Phase is pending but already has files — status may need updating"
            WARNINGS=$((WARNINGS + 1))
          fi

        else
          echo -e "  ${YELLOW}?${NC} Phase ${PHASE_NUM_PADDED} [${STATUS}] — ${PHASE_NAME}"
        fi

      else
        # No directory for this phase
        if [ "$STATUS" = "pending" ]; then
          echo -e "  ${NC}○${NC} Phase ${PHASE_NUM_PADDED} [pending] — no directory yet (normal)"
        else
          echo -e "  ${RED}✗${NC} Phase ${PHASE_NUM_PADDED} [${STATUS}] — directory missing"
          ERRORS=$((ERRORS + 1))
        fi
      fi

    done <<< "$ROADMAP_PHASES"

    echo ""
  fi

  # ─── 5. Orphaned directories ───
  # Check for phase directories not referenced in roadmap

  if [ -d "$TARGET/docs/phases" ]; then
    for dir in "$TARGET/docs/phases"/[0-9][0-9]-*/; do
      [ -d "$dir" ] || continue
      DIR_NUM=$(basename "$dir" | grep -oE '^[0-9]+')
      DIR_NUM_CLEAN=$((10#$DIR_NUM))  # Remove leading zeros for comparison

      # Skip 00-research — it's expected
      [ "$DIR_NUM_CLEAN" -eq 0 ] && continue

      if ! grep -q "Phase ${DIR_NUM_CLEAN}:" "$TARGET/docs/ROADMAP.md" 2>/dev/null; then
        echo -e "  ${YELLOW}!${NC} Orphaned directory: $(basename "$dir") — not in ROADMAP.md"
        WARNINGS=$((WARNINGS + 1))
      fi
    done
  fi
fi

# ─── Result ───

echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}[KEEL] All checks passed.${NC}"
elif [ $ERRORS -eq 0 ]; then
  echo -e "${YELLOW}[KEEL] ${WARNINGS} warning(s), no errors.${NC}"
else
  echo -e "${RED}[KEEL] ${ERRORS} error(s), ${WARNINGS} warning(s).${NC}"
fi

echo ""
exit $ERRORS
