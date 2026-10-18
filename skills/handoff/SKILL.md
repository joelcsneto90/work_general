---
name: handoff
description: Write an explicit session handoff document to D:\Joel\AIs\handoffs so work can resume in a fresh session. Use ONLY when the user explicitly asks for a handoff (or types /handoff) — never automatically, never on compaction. Around 70% context you may suggest it once in one line, but do not write it unless asked.
---

# Handoff

Produce a self-contained state document. The reader is a fresh session with
**zero** memory of this conversation — assume nothing.

## Where

`D:\Joel\AIs\handoffs\YYYY-MM-DD-<project>-<short-slug>.md`

Always this absolute path, regardless of cwd. `<project>` is the basename of
the working directory the session was started in, so handoffs from different
projects stay distinguishable in one shared folder.

Create the directory if it does not exist. If the D: drive is unavailable,
fall back to the session scratchpad and say so. If an unfinished handoff for
the same work already exists, update it in place rather than creating a
second file.

## Format

```markdown
# Handoff: <task name>
Date: <YYYY-MM-DD> | Status: <in progress | blocked | ready for review>

## Goal
What we are actually trying to achieve, and why. One paragraph.

## Current state
What is done and verified. What is done but unverified. Be explicit about
which is which.

## Next steps
Ordered, concrete, actionable. First item should be immediately executable.

## Key files
- `path/to/file.ext:line` — what it is / what was changed and why

## Decisions made
Decisions and the reasoning, especially ones already litigated with the user.
This is the part compaction loses. Include rejected alternatives.

## User constraints & corrections
Anything the user explicitly asked for, vetoed, or corrected. Verbatim where
it matters.

## Gotchas / open questions
Environment quirks, failing tests, credentials/access needed, unresolved
ambiguities and what assumption is currently in play.

## Resume prompt
> A single paste-ready prompt for the next session.
```

## Rules

- Facts only. No optimism about untested work — if tests failed, say so with
  the output.
- Include exact commands, connection strings (redacted), env names, IDs.
- Prefer file paths + line numbers over re-pasting code.
- Anything durable about the *user* or their preferences goes to memory, not
  just the handoff.
- After writing, print the path and the resume prompt to the terminal.
