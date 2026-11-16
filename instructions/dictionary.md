## Dictionary — expressions I use

When I use one of these terms, do exactly what it maps to. They can appear in any language or case
("faz um macfe", "MACFE", "ccp ai").

Two scopes complement each other: this global dictionary, and a project dictionary at
`<repo>/dictionary.md` (referenced by the project's `CLAUDE.md`/`AGENTS.md`). Both apply;
when the same term is in both, the project one wins.

| Term | Meaning |
| --- | --- |
| `macfe` | Checkout the main branch (`main`, `master` or `develop`, whichever the repo uses), pull to update it, then create and checkout a new branch from it, named per the branch-naming rule in Tooling → Git. Uncommitted changes → stop and ask before switching. |
| `ccp` | Commit and push the current changes on the current branch. |
| `marge` | Checkout the main branch (`main`, `master` or `develop`, whichever the repo uses), pull to update it, then checkout back to the branch I was on and merge the main branch into it. Uncommitted changes → stop and ask before switching. |
| `macup` | Same as `marge`, then resolve any merge conflicts: keep both sides' intent, build/test the touched code, and ask me when a conflict needs a business decision. A clean merge commits as usual; after resolving conflicts, never commit — leave the resolved merge uncommitted for me to review. |
| `repo global` | The work_general repo: the clone the global instructions are imported from (path in the `work_general` block of `~/.claude/CLAUDE.md`). Its `instructions/`, `skills/`, … are the source of the global config. After changing it, run `scripts/install.ps1` for each target so the change is active: Claude imports instructions live, but Codex/Copilot concatenate them, so instruction changes need the `-Codex` and `-Copilot` runs too. |
| `diretório global` | The installed global config dirs — `~/.claude`, `~/.codex`, `~/.copilot` — with their instructions, skills, agents and settings. Skills there are links into the `repo global`, so a skill created "in the global dir" is created in the `repo global` and linked with `scripts/install.ps1`. |
