# Session Workflow

How to start and execute a new development phase in WireBar.

## Phase Workflow

### 1. Plan

Run `/prd-to-plan` scoped to the target phase. Reference `PRD.md` as the source and specify which phase to plan (e.g., "Create a plan for Phase 4 — VPN Management using PRD.md").

The skill produces a plan file in `plans/` with tracer-bullet vertical slices.

### 2. Execute

Start a **new chat session**. Point it at the plan file and ask it to execute. The fresh session keeps context focused on implementation.

Use `/mattpocock-tdd` for test-driven development during implementation. Use `/mattpocock-diagnosing-bugs` when debugging.

### 3. Review

When a phase step is complete, use `/code-review` to review the work against the plan.

### 4. Finish

When all plan steps pass, use `/mattpocock-handoff` to save a handoff doc to `handoffs/`, then merge the phase branch to `main` per the Git Workflow in CLAUDE.md.

## Skills We Use

| Skill | When |
|-------|------|
| `/prd-to-plan` | Start of a phase — turn PRD section into an implementation plan |
| `/mattpocock-tdd` | During implementation — test-driven development |
| `/mattpocock-diagnosing-bugs` | Debugging issues |
| `/mattpocock-handoff` | End of session — create handoff doc |
| `/code-review` | After completing a chunk of work |
| `/mattpocock-grilling` | Stress-test a design decision |

## What We Don't Use

- No superpowers plugin (removed 2026-06-23).
- No separate per-phase PRDs — `PRD.md` is the single source of truth. Plans are derived from it via `/prd-to-plan`.
