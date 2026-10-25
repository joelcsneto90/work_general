---
name: execute-roadmap
description: Execute a roadmap from D:\Joel\AIs\roadmaps task by task — dependency pre-scan, inline vs. subagent per task, independent review, fresh verification of each "Done when", ticking [x] and logging rulings in the file. Use when the user asks to executar/implementar o roadmap/plano or a range of its tasks; also /execute-roadmap (Claude Code) or $execute-roadmap (Codex).
---

# Execute roadmap

Trimmed from obra/superpowers `subagent-driven-development` for legacy codebases. Invoking this
skill is the user's explicit request to delegate to subagents **as described here** — nowhere else.
If the tool can't spawn subagents, run every task inline; the rest still applies.

## Before the first task
1. Read the roadmap whole and the project's instruction file (`CLAUDE.md` / `AGENTS.md`). Scope =
   the tasks the user named (e.g. `T2.1-T3.2`), else the unchecked ones in dependency order.
2. **Pre-scan** each task in scope against the code as it is now: files and interfaces it touches,
   files shared between tasks, contradictions (between tasks, or with code that changed since the
   plan was written), a "Done when" that can't be checked, a `Revisit if` signal already true,
   entries under `## Lessons`. Settle each with a ruling; ask only if it changes what the user
   approved.
3. **Mode per task:**
   - **Inline (default):** dependency chains, tasks that share files with another in-flight task,
     tasks that need this conversation's context, small tasks (a cold-start subagent costs more
     than the task).
   - **Subagent:** a task with its dependencies done and files no other in-flight task touches,
     or large enough that a clean context pays off. Parallel only on disjoint files, each in its
     own git worktree, merged back after review. Never two implementers on the same files.
   - Show a short table (task → mode → why) and start; no confirmation unless the pre-scan raised
     a question.

## Per task
1. Record BASE: `git rev-parse HEAD` in the target repo.
   **Migration / port / version upgrade:** current behavior is the source of truth. Tests that
   pin it must be green on BASE before any change; write characterization tests where missing
   (part of the task). Rewrite a test only for mechanical reasons (syntax, framework API);
   changing what it asserts needs a ruling with the reason.
2. **Implement** inline, or dispatch an implementer with a minimal brief: task text, files,
   "Done when", outputs/interfaces of completed tasks, rulings that affect it, the project
   instruction file. No conversation history. Prefer a project agent that owns the area over a
   generic one. Set the model explicitly: cheap for mechanical, standard for integration,
   strongest for design.
   The implementer ends with one status: `DONE`, `DONE_WITH_CONCERNS: <what>`,
   `NEEDS_CONTEXT: <what>` or `BLOCKED: <why>`. Needs context → supply it, re-dispatch. Blocked →
   change something (context, stronger model, split the task, ruling); never retry unchanged.
3. **Verify yourself.** The implementer's report is not evidence: read the diff from BASE, run
   the task's "Done when" check fresh, and tick it item by item.
4. **Review** by someone who didn't write it (a subagent given the diff + task text; the
   project's test/review agent if one exists). In order: (a) spec — does the diff do the task,
   nothing missing, nothing extra; (b) quality — project rules, layering, tests that assert real
   behavior; (c) approach — is there a clearly simpler or safer way within the task's scope?
   Simpler means less code and less change, not more abstraction. Treat findings as hypotheses:
   verify each in the code before acting, reject with a reason when wrong or YAGNI, ask the user
   when one conflicts with a decision in the roadmap. An approach change that alters what the
   user approved → stop and propose it before implementing.
5. **Fix loop:** a failing check, spec gaps, critical/important findings and accepted approach
   changes → back to step 2 for **this task only** (resume the same implementer when possible),
   then re-verify and re-review only the fix diff. Minor → log as deferred. Max 2 rounds, then
   park with a ruling or stop and report. Each round adds a lesson (below).
6. Tick `[x]` with a short note (commit range or "uncommitted", the check that ran). Keep the
   roadmap `Status` current (`in progress` / `done`).

## Rulings
Ambiguities you settle yourself go under `## Rulings` in the roadmap (create it if missing):
`- T2.2: <decision> — <why> — <cost if wrong>`.

## Lessons
What a fix round, a surprise or a dig taught you goes under `## Lessons` in the roadmap:
`- T2.2: <what went wrong or was missing> — <root cause> — <scope: task | project | global>`.
Re-read them before each remaining task. Scope `project` = true of this repo (command, convention,
trap); `global` = true of any project. Neither is written anywhere else during execution.

## Instruction proposals
At Finish, turn `project` and `global` lessons into proposals, each with the exact text and the
target: the project's instruction file, or a module under
`D:\Joel\repos\Joel\WorkGeneral\instructions\`. Propose only what would have prevented a mistake
or a search in a fresh session, and isn't already derivable from the code or already written.
Apply only on the user's yes.

## Stop and ask only for
Irreversible or outward-facing actions (push, merge, deploy, shared DB/env, publishing),
security-sensitive changes, a check still failing after 2 fix attempts, or a plan so wrong that
any continuation is a guess. Otherwise run through the scope without check-ins.

## Commits
Only if the user asked or the project instructions say so — then one commit per task, never on
the default branch without consent.

## Finish
With 2+ tasks done, one final review of the whole diff from the first BASE (strongest model)
before reporting. Report: per task done or not, mode, check run and result; rulings; deferred
findings; instruction proposals; next task.
