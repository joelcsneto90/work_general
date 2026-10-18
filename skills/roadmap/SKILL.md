---
name: roadmap
description: Write an action plan / implementation roadmap / task list to D:\Joel\AIs\roadmaps. Use whenever the user asks for a plano de ação, roadmap, plano de implementação, lista de tasks/tarefas para implementar, breakdown of work, or types /roadmap.
---

# Roadmap

Turn the requested work into a concrete, ordered plan saved as a file. The
reader may be the user or a fresh session with **zero** memory of this
conversation — make it self-contained.

## Where

`D:\Joel\AIs\roadmaps\YYYY-MM-DD-<project>-<short-slug>.md`

Always this absolute path, regardless of cwd. `<project>` is the basename of
the working directory the session was started in. Create the directory if it
does not exist. If the D: drive is unavailable, fall back to the session
scratchpad and say so. If a roadmap for the same work already exists, update
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

## Objetivo
What we want to achieve and why. One paragraph.

## Escopo
- In: ...
- Out: ...

## Premissas & decisões
Assumptions in play and decisions made (with rejected alternatives).

## Fases / Tasks
### Fase 1 — <name>
- [ ] **T1.1 <task title>** — what to do
  - Files: `path/to/file.ext`
  - Done when: <verifiable acceptance criterion>
  - Depends on: <task ids, or none>
- [ ] **T1.2 ...**

### Fase 2 — <name>
...

## Riscos & questões em aberto
Risks, unknowns, access/credentials needed, and what would change the plan.

## Validação
How to verify the whole thing works end to end (commands, tests, manual checks).
```

## Rules

- Each task small enough for one focused session, with a verifiable "done when".
- Order by dependency; the first task should be immediately executable.
- Write in the user's language (default Portuguese for headings/content).
- Planning only: do not start implementing unless the user asks.
- When the user later asks to execute the roadmap, tick tasks (`[x]`) in the
  file as they are completed and verified.
- After writing, print the path and a short summary of the phases.
