## Coding discipline

Based on [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills),
tightened, with a few additions. Applies to every project; the project's `CLAUDE.md` adds the
stack-specific rules. Bias toward caution over speed; for trivial tasks, use judgment.

### 1. Think before coding — don't assume, don't hide confusion
* State assumptions. Multiple readings of the request? Present them; don't pick silently.
* Simpler approach than the one asked? Say so first. Push back when warranted.
* Unclear? Stop, name what's unclear, ask.

### 2. Read before writing — the codebase already has an answer
* Look at how the codebase already solves similar problems, and follow that pattern.
* Reuse existing helpers, utilities and abstractions before writing new ones.
* No new dependency without saying why the existing ones don't cover it.

### 3. Simplicity first — minimum code, nothing speculative
* No features, options, flexibility or configurability beyond what was asked.
* No abstraction for single-use code. But when a change adds a second variant of existing
  behavior (mode, version, layout, provider) and the choice between them would be checked in
  more than one place, model the variant as an object selected once. One branch in one place
  is fine. Check: grep the new flag/condition; 2+ hits → extract.
* No error handling, null-guards, fallbacks or "just in case" calls for cases that can't
  happen. If upstream guarantees a value, trust it.
* 200 lines that could be 50? Rewrite. Test: would a senior engineer call it overcomplicated?

### 4. Surgical changes — touch only what you must, clean up only your own mess
* Every changed line traces to the request. Don't "improve" adjacent code, comments or
  formatting. Don't refactor what isn't broken. Match the existing style.
* Before changing an existing member/contract/config, find its usages; if the change alters
  behavior for callers outside the request, say so first.
* Remove imports/variables/functions that *your* change orphaned. Pre-existing dead code or
  smells: mention them, don't touch them.

### 5. Fix causes, not symptoms
* Find the root cause before fixing. Don't paper over it with a retry, a sleep, a catch-all,
  or a special case for the failing input.
* Debugging: find a similar flow that works and list the differences before changing anything.
* 3 failed fix attempts → stop and question the approach with me; no 4th try.
* Never weaken, skip or delete a test, or silence a warning, just to get green. If the test is
  wrong, say so and why.

### 6. Goal-driven execution — define success, loop until verified
* Turn the task into a check:
  "add validation" → tests for invalid input, then make them pass;
  "fix the bug" → a test that reproduces it, then make it pass;
  "refactor X" → tests green before and after.
* Multi-step work: brief plan, each step with its check (`1. step → verify: check`).
* Run the narrowest check that proves it (the touched project/test), wider only when the
  change is cross-cutting.
* Not done until the check ran. Report it straight: failed → say so with the output; skipped
  → say so. Keep "verified" and "done but unverified" apart.
* Evidence = fresh check output + the diff. A subagent's or tool's "done" is not evidence.
* A regression test must fail without the fix (red → green), or it proves nothing.
* "Requirement met" = checked item by item against the acceptance criteria, not just "tests pass".

### 7. Cheap by construction — fewest round-trips, fewest passes
* I/O (database, HTTP, filesystem, queue): no call inside a loop; batch it or load the set once
  up front. Validations and logic that need the same record load it once and reuse it, instead of
  querying again per check.
* In-memory collections: don't chain passes that one pass covers naturally (filter before map;
  combine when the language has an idiom for it). Fusing passes at the cost of readability is
  only worth it on hot paths or large collections; otherwise readability wins (section 3).

**Working if:** diffs hold only what was asked, fewer rewrites from overcomplication, and
questions come before implementation, not after mistakes.
