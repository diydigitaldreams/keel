# KEEL — Context-Engineered Development System

You are operating under the KEEL workflow. KEEL is a zero-install, files-only development framework. There is no CLI. There are no slash commands. The framework IS these files. Your workflow has three modes: **SCOPE → BUILD → SHIP**. You cycle BUILD → SHIP for each phase in the roadmap until the project is complete.

---

## How Context Management Works

Context rot kills long sessions. KEEL prevents it.

- **One phase per context window.** Never work across multiple roadmap phases in the same session.
- After completing SCOPE or SHIP, tell the user to clear context (`/clear`, new chat, or equivalent) before starting the next step.
- When starting work on a roadmap phase, read ONLY:
  1. This file (CLAUDE.md)
  2. `docs/SCOPE.md` (project identity — always relevant)
  3. `docs/ROADMAP.md` (to identify the current phase)
  4. The current phase directory: `docs/phases/NN-phase-name/`
- **Do not read other phase directories.** They are not your concern.
- If you notice your responses degrading in quality, getting repetitive, or losing track of details, stop. Tell the user to commit current work, clear context, and resume with "continue phase N."

---

## SCOPE

**When:** The user says anything like "let's scope this," "new project," "what are we building," or `docs/SCOPE.md` is empty/missing.

**Goal:** Fully understand the project before any code is written.

### Interview

You drive this. Ask questions in rounds of no more than 3 questions each. Cover these areas:

1. **What** — What does this thing do? Who is it for?
2. **Stack** — Technologies, languages, frameworks, infrastructure. Any hard constraints?
3. **Shape** — Major features or surfaces. What's the MVP vs. the full vision?
4. **Boundaries** — What is explicitly NOT in scope? What already exists?
5. **Success** — How do we know it's done? What does "working" look like?

Keep going until you could explain the project to another developer cold. Then present a brief summary and get explicit approval before proceeding.

### Research

Once the interview is approved, research the project's technical landscape before writing the spec. This is where depth matters — bad research means bad plans.

**If your agent supports subagent spawning (Claude Code, Codex, etc.):** Launch these as parallel subagents. Each subagent gets a focused research brief and writes its section independently. This keeps the main context clean.

**If your agent does not support subagents:** Do this sequentially in the current context, but keep each section concise.

Research areas — each produces a clearly labeled section:

- **Stack research** — Best practices, common pitfalls, version-specific gotchas, dependency compatibility. Check for known breaking changes in the chosen versions.
- **Architecture research** — How similar projects are typically structured. Relevant patterns (monorepo vs. multi-repo, API design conventions, state management approaches). Reference implementations if they exist.
- **Risk research** — What breaks, what's hard, what people get wrong with this stack. Performance bottlenecks. Security considerations. Deployment gotchas.
- **Prior art** — Existing tools or projects that solve adjacent problems. What can be learned or reused. What to avoid repeating.

Write all findings to `docs/phases/00-research/RESEARCH.md` with clear section headers. This file is referenced during BUILD planning — it must be scannable, not a wall of text.

### Spec

Create two files from the interview and research:

**`docs/SCOPE.md`:**
```markdown
# [Project Name]

## Vision
[One paragraph. What this is and why it exists.]

## Stack
[Technologies, frameworks, languages, infrastructure.]

## Features
[Numbered list of capabilities, grouped by priority tier.]

## Boundaries
[What is explicitly out of scope.]

## Success Criteria
[Measurable outcomes that mean "this is done."]
```

**`docs/ROADMAP.md`:**
```markdown
# Roadmap

## Phase 1: [Name]
**Objective:** [One sentence]
**Delivers:** [What exists when this phase is done]
**Status:** pending

## Phase 2: [Name]
...
```

Roadmap rules:
- Each phase should be completable in 1–3 focused sessions.
- Each phase must produce something testable or demonstrable.
- Phase 1 is the minimum skeleton that proves the architecture works.
- Prefix phase numbers with two digits: 01, 02, 03.

**After writing both files:** "SCOPE complete. Clear context, then say **build phase 1** to start."

---

## BUILD

**When:** The user says "build phase N," "start phase N," "let's build," "continue phase N," or references a specific phase.

### Resuming

Before planning or executing, check if `docs/phases/NN-phase-name/LOG.md` already exists with completed tasks. If so, pick up from the first incomplete task. Do not re-do finished work.

### Plan

Read ROADMAP.md to identify the current phase. Create the phase directory:

```
docs/phases/NN-phase-name/
  PLAN.md
  LOG.md
```

**PLAN.md format:**
```markdown
# Phase N: [Name]

## Objective
[From roadmap]

## Tasks

### Task 1: [Short name]
**Do:** [Exactly what to implement — specific files, functions, components]
**Done when:** [Mechanically verifiable — tests pass, endpoint returns X, component renders Y]
**Files:** [Which files will be created or modified]

### Task 2: [Short name]
...
```

Planning rules:
- Tasks are atomic — one clear job each.
- "Done when" must be verifiable without subjective judgment.
- Order tasks so each builds on the last.
- 3–7 tasks per phase. More than 7 means the phase is too big — split it.
- Each task should be completable without exhausting context.

Present the plan. Get explicit approval before executing.

### Execute

For each task:

1. State which task you're starting.
2. Do the work. For complex tasks, consider delegating sub-tasks to subagents (e.g., "write tests for module X" or "research the best approach for Y") to keep the main context focused on orchestration.
3. Run relevant tests or verification.
4. Log the result in `LOG.md`:

```markdown
### Task N: [Name]
**Status:** done | blocked | partial
**Changes:** [files created or modified]
**Notes:** [anything the next task or phase needs to know]
```

5. Git commit: `keel(NN): task N — [short description]`

**If a task is blocked:** Log why, skip it, move to the next. Do not spiral.

**If context is getting heavy:** Stop after the current task. Tell the user: "Commit and clear context, then say **continue phase N** to resume."

---

## SHIP

**When:** All tasks in the current phase are done, or the user says "ship it," "verify," or "is this phase done?"

### Verify

- Re-read every "Done when" criterion in PLAN.md.
- Run tests, linters, type checks — whatever the stack supports.
- Confirm each criterion is met. If anything fails, fix it or flag it as blocked.

### Log

Append a phase summary to `LOG.md`:

```markdown
## Phase Summary
**Status:** complete
**Tasks completed:** [N of N]
**Carries forward:** [Context the next phase needs — patterns established, decisions made, known issues.]
```

Git commit: `keel(NN): phase complete — [one-line summary]`

Update `docs/ROADMAP.md` — set the phase status to `complete`.

### Advance

Tell the user:
- What was built
- What carries forward
- **"Clear context, then say **build phase N+1** to continue."**

If all roadmap phases are complete, say so. Suggest a final integration verification.

---

## Handling Scope Changes

If the user wants to change direction mid-project:

- **Small adjustment** (rename, tweak a feature): Update SCOPE.md and current PLAN.md. Log the change. Continue.
- **Significant change** (new feature, different architecture): Stop BUILD. Update SCOPE.md and ROADMAP.md. Re-plan the current phase. Get approval before resuming.
- **Pivot** (fundamentally different project): Start SCOPE from scratch. Existing phase work stays in git history.

Always document why the change was made in the current LOG.md.

---

## Behavioral Rules

1. **You are not a project manager.** No sprint ceremonies. No story points. No stakeholder theater. Plan, build, verify, move on.
2. **Files are the source of truth.** If it's not in SCOPE.md, ROADMAP.md, or a PLAN.md, it doesn't exist as a commitment.
3. **Atomic commits.** Every task gets its own commit. Every phase completion gets a commit. The git log reads like a changelog. Use the enforced format: `keel(NN): task N — [description]` or `keel(NN): phase complete — [description]`.
4. **Ask, don't assume.** During SCOPE, interview thoroughly. During BUILD, confirm the plan before executing. Never assume a technology choice or architectural decision the user hasn't approved.
5. **Fresh context, every phase.** Remind the user to clear context between phases. This is not optional — it's how KEEL works.
6. **Log everything.** If you did it, it's in LOG.md. If you decided something, the reasoning is in LOG.md. The LOG is how future context windows know what happened.
7. **Admit when you're stuck.** Log it, flag it, move on. Don't waste context trying to brute-force a problem that needs human input.
8. **Stay lean.** No filler. No preamble. State what you're doing, do it, state what's next.

---

## Enforcement (Git Hooks)

If the user has installed KEEL's git hooks (via `setup.sh`), the following are enforced automatically:

- **Commit messages** must follow `keel(NN): description` format. Malformed commits are rejected.
- **Secrets** (.env files, API keys, private keys) in staged files are detected and blocked.
- **LOG.md updates** — committing phase work without updating LOG.md triggers a warning.

These hooks run automatically. They can be bypassed with `git commit --no-verify` when needed.

The user can also run `./validate.sh` at any time to check project integrity — missing files, orphaned phases, inconsistent statuses.
