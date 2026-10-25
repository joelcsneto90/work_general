---
name: roadmap
description: Write an action plan / implementation roadmap / task list to D:\Joel\AIs\roadmaps. Use whenever the user asks for a plano de ação, roadmap, plano de implementação, lista de tasks/tarefas para implementar, breakdown of work; also invoke with /roadmap (Claude Code) or $roadmap (Codex).
---

# Roadmap

Turn the requested work into a concrete, ordered plan saved as a file. The
reader may be the user or a fresh session with **zero** memory of this
conversation — make it self-contained.

## Where

`D:\Joel\AIs\roadmaps\YYYY-MM-DD-<project>-<short-slug>.md`

Always this absolute path, regardless of cwd. `<project>` is the basename of
the working directory the session was started in. Create the directory if it
does not exist. If access is blocked, report that exact problem instead of
writing the roadmap elsewhere. If a roadmap for the same work already exists, update
it in place (keep checked items, adjust the rest) rather than creating a
second file.

## Before writing

Ground the plan in reality: read the relevant code, configs, and docs first.
Tasks must reference real files, components, and commands — no generic
placeholders. If a decision is genuinely the user's to make and changes the
plan, ask; otherwise pick a sensible default and record it as an assumption.

Note what you had to dig for that the project's instruction file (`CLAUDE.md` / `AGENTS.md`)
should have told you: build/test commands, conventions, traps. Those become suggestions in the
report (see Rules), not edits.

## Plan loop

Draft, then critique and revise, at most 2 rounds; stop early when a round changes no task and
no decision. Critique:
- Each decision: the strongest case for the best rejected alternative, not only for the chosen
  one. Keep the choice only if it still wins.
- Premortem: assume the plan failed — what most likely caused it? Add a task, a check or a risk.
- Every file, API and command cited exists as described.
- Simplicity: can a phase or task be dropped or merged and still meet the goal?
- Migration / port / version upgrade: a first task pins current behavior (existing tests green,
  characterization tests where missing) before any change.

For a large or high-stakes plan, hand the critique to a subagent with goal, scope and tasks but
**without** the rationale, so it isn't anchored on it. Treat its findings as hypotheses.

## Format

```markdown
# Roadmap: <name>
Date: <YYYY-MM-DD> | Project: <project> | Status: <draft | approved | in progress | done>

## Goal
What we want to achieve and why. One paragraph.

## Scope
- In: ...
- Out: ...

## Assumptions & decisions
Assumptions in play and decisions made, each with the rejected alternatives and
`Revisit if: <signal seen during implementation that reopens it>`.

## Phases / Tasks
### Phase 1 — <name>
- [ ] **T1.1 <task title>** — what to do
  - Files: `path/to/file.ext`
  - Done when: <verifiable acceptance criterion>
  - Depends on: <task ids, or none>
- [ ] **T1.2 ...**

### Phase 2 — <name>
...

## Risks & open questions
Risks, unknowns, access/credentials needed, and what would change the plan.

## Validation
How to verify the whole thing works end to end (commands, tests, manual checks).
```

## Rules

- Each task small enough for one focused session, with a verifiable "done when".
- Order by dependency; the first task should be immediately executable.
- Write in the user's language (default Portuguese), headings included. Keep the task labels
  `Files` / `Done when` / `Depends on` / `Revisit if` as-is: `execute-roadmap` reads them.
- Planning only: do not start implementing unless the user asks.
- Executing it later is the `execute-roadmap` skill's job.
- After writing, report the path, a short summary of the phases, what the plan loop changed, and
  any instruction-file gaps as suggestions with the exact text and target file.
