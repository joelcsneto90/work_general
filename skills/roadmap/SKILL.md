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
Assumptions in play and decisions made (with rejected alternatives).

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
  `Files` / `Done when` / `Depends on` as-is: `execute-roadmap` reads them.
- Planning only: do not start implementing unless the user asks.
- Executing it later is the `execute-roadmap` skill's job.
- After writing, report the path and a short summary of the phases.
