## Sessions, context & memory

* Handoffs are never automatic — no hook, no proactive writing. Write one only when I
  explicitly ask (`handoff` skill: `/handoff` in Claude Code, `$handoff` in Codex).
* At most, *suggest* it once — in one line — when the context is around 70% full and the work
  is mid-task. Then drop it; don't repeat the suggestion or wrap up early. (The Claude Code
  status line also shows a `/handoff?` hint from 70%.)
* When I ask for a plan / roadmap / task breakdown, use the `roadmap` skill and write the file;
  plan only, don't start implementing unless I ask.
* Durable facts about me or my preferences go to memory (when the tool has one), not just to
  the current answer.
* Don't re-derive facts already established in the conversation or re-open decisions I've made.
