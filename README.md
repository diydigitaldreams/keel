# KEEL

**The structural backbone. First thing laid down. Everything builds on it.**

KEEL is a zero-install, files-only development framework for AI coding agents. No CLI. No package manager. No update treadmill. Copy the files, start building.

## Why KEEL Exists

AI coding agents degrade over long sessions. As the context window fills up, output quality drifts — instructions get missed, code gets sloppy, details get lost. This is context rot, and it's the single biggest reliability problem in AI-assisted development.

KEEL solves it with files.

The framework IS the files. A `CLAUDE.md` that contains every instruction your AI agent needs, and a `docs/` directory that holds project state as human-readable markdown. When you clear context and start a new session, the agent reads the files and picks up exactly where it left off. No state is lost because no state lived in memory — it was always on disk.

No runtime. No dependencies. No config. If your agent can read markdown, KEEL works.

## Quick Start

```bash
git clone https://github.com/diydigitaldreams/keel.git
cp -r keel/template/.claude your-project/.claude
cp -r keel/template/docs your-project/docs
```

Or use the setup script:

```bash
git clone https://github.com/diydigitaldreams/keel.git
./keel/setup.sh /path/to/your-project
```

Then open your AI coding agent and say:

> "Let's scope this project."

KEEL takes it from there.

## How It Works

Three modes. No ceremony.

```
SCOPE  →  Interview, research, spec out what we're building
BUILD  →  Plan atomic tasks, execute, commit each one
SHIP   →  Verify success criteria, log, advance to next phase

Repeat BUILD → SHIP for each phase until the project is done.
```

Context rot is eliminated by clearing context between phases. Each phase gets its own directory with only the files that phase needs. Heavy thinking — research, planning, architectural decisions — happens once and gets written to disk. Every future context window inherits that work by reading the files, not by trying to remember a conversation.

### Project Structure

```
your-project/
├── .claude/
│   └── CLAUDE.md                ← The brain. All instructions live here.
└── docs/
    ├── SCOPE.md                 ← What we're building
    ├── ROADMAP.md               ← Phases with status tracking
    └── phases/
        ├── 00-research/
        │   └── RESEARCH.md      ← Stack, architecture, risk research
        ├── 01-foundation/
        │   ├── PLAN.md          ← Atomic tasks with success criteria
        │   └── LOG.md           ← Execution log and phase summary
        └── 02-core-features/
            ├── PLAN.md
            └── LOG.md
```

### SCOPE — Understand before building

KEEL interviews you in focused rounds until it fully understands your project — what you're building, the tech stack, boundaries, and success criteria. Then it researches your stack in parallel: best practices, architecture patterns, common pitfalls, and prior art. Everything gets written to `SCOPE.md` and `ROADMAP.md`.

You approve the spec. Clear context. Start building.

### BUILD — One phase at a time, fresh context every time

For each phase in the roadmap:

1. KEEL creates a `PLAN.md` with atomic tasks and mechanically verifiable success criteria
2. You approve the plan
3. KEEL executes each task, logs the result, and commits to git
4. If context gets heavy, you clear and resume — KEEL reads the LOG to pick up exactly where it left off

Complex tasks get delegated to subagents when the agent supports it, keeping the main context focused on orchestration rather than getting buried in implementation details.

### SHIP — Verify, commit, advance

KEEL re-checks every success criterion, runs tests, and logs a phase summary including what carries forward to the next phase. The roadmap updates. Clear context. Next phase.

Every task gets a git commit. Every phase gets a commit. Your git log reads like a changelog:

```
keel(01): task 1 — initialize project with Next.js and Supabase
keel(01): task 2 — configure auth with email/password flow
keel(01): task 3 — add protected route middleware
keel(01): phase complete — foundation with auth and routing
keel(02): task 1 — create database schema for core models
...
```

## What the Files Look Like

**SCOPE.md** (populated during SCOPE):
```markdown
# Pulse

## Vision
A real-time team health dashboard that surfaces burnout signals
from calendar and commit data before they become problems.

## Stack
Next.js 14, Supabase (auth + db), Vercel, Tailwind CSS

## Features
1. Google Calendar integration — read meeting load per person
2. GitHub integration — read commit frequency and PR cycle time
3. Health score algorithm — weighted composite of signals
4. Dashboard — team view with per-person drill-down

## Boundaries
- No Slack integration in v1
- No predictive modeling — descriptive metrics only
- Single-team scope, no multi-org

## Success Criteria
- Dashboard renders live data for a connected team of 5+
- Health scores update within 5 minutes of new data
- Page load under 2 seconds on cold start
```

**PLAN.md** (populated during BUILD):
```markdown
# Phase 1: Foundation

## Objective
Minimal app skeleton with auth and database connection.

## Tasks

### Task 1: Project scaffolding
**Do:** Initialize Next.js 14 with Tailwind, configure Supabase client
**Done when:** Dev server runs, Supabase connection returns a test query
**Files:** package.json, src/lib/supabase.ts, .env.local.example

### Task 2: Auth flow
**Do:** Implement email/password signup and login with Supabase Auth
**Done when:** User can register, log in, and see a protected /dashboard route
**Files:** src/app/login/page.tsx, src/app/signup/page.tsx, src/middleware.ts
```

## Enforcement

KEEL includes optional git hooks that enforce conventions automatically. No runtime, no dependencies — just shell scripts that git already knows how to run.

**Install with hooks (default):**
```bash
./keel/setup.sh /path/to/your-project
```

**Install without hooks:**
```bash
./keel/setup.sh --no-hooks /path/to/your-project
```

### What the hooks enforce

| Hook | What it does |
|---|---|
| **commit-msg** | Rejects commits that don't follow `keel(NN): description` format |
| **pre-commit** | Blocks commits containing secrets (API keys, .env files, private keys) |
| **pre-commit** | Warns when phase work is committed without updating LOG.md |

Hooks can be bypassed with `git commit --no-verify` when needed.

### Validation

Run `./validate.sh` at any time to check project integrity:

```bash
$ ./validate.sh

[KEEL] Validating project: .

Core files:
  ✓ .claude/CLAUDE.md
  ✓ docs/SCOPE.md
  ✓ docs/ROADMAP.md

Phases:
  ✓ Phase 01 [complete] — 01-foundation
  → Phase 02 [active] — 02-core-features (PLAN: yes, LOG: yes)
  ○ Phase 03 [pending] — no directory yet (normal)

[KEEL] All checks passed.
```

It verifies that required files exist, every roadmap phase has a matching directory, phase statuses are consistent with LOG.md content, and no orphaned directories exist.

## Design Principles

1. **Files are the framework.** No runtime. No CLI. No lock-in. If your agent reads markdown, KEEL works.
2. **Three modes, not a command palette.** SCOPE, BUILD, SHIP. That's the entire interface. You talk to your agent in natural language.
3. **Context is managed, not accumulated.** Clear between phases. Each phase reads only what it needs. State lives on disk, not in memory.
4. **Atomic everything.** One task, one job, one commit. The LOG tells you exactly what happened and why.
5. **Human-readable state.** Every file is markdown you can read, edit, and understand. No proprietary formats. No config languages.
6. **Ask, then build.** Interview before planning. Plan before executing. Verify before advancing. No assumptions.

## Compatibility

KEEL works with any AI coding agent that reads an instruction file:

| Agent | Setup |
|---|---|
| **Claude Code** | Works natively — reads `.claude/CLAUDE.md` |
| **Cursor** | Copy CLAUDE.md content into `.cursor/rules/keel.md` |
| **Windsurf** | Add to `.windsurfrules` or cascade instructions |
| **Codex** | Copy to `.codex/` instructions directory |
| **Gemini CLI** | Copy to `.gemini/` instructions |
| **Any future agent** | If it reads a system prompt from a file, KEEL works |

## Contributing

KEEL is intentionally minimal. Before proposing a feature, ask: *"Does this add a file, or does this add machinery?"* If it adds machinery, it doesn't belong here.

Bug fixes, documentation improvements, and compatibility guides for new agents are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).

---

*The keel is the first thing laid down when building a ship. It's the structural backbone — everything else is built on top of it. Without it, nothing holds together.*
