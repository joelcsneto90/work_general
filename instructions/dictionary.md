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
| `macfup` | Checkout the main branch (`main`, `master` or `develop`, whichever the repo uses), pull to update it, then checkout back to the branch I was on and merge the main branch into it, resolving any conflicts: keep both sides' intent, build/test the touched code, and ask me when a conflict needs a business decision. Uncommitted changes → stop and ask before switching. A clean merge commits as usual; after resolving conflicts, never commit — leave the resolved merge uncommitted for me to review. |
| `repo global` | The work_general repository holds the shared source of the global config for every machine. Its `instructions/`, `skills/`, … are copied into each machine's `diretório global` only when `scripts/install.ps1` is re-run for that target (default, `-Codex`, or `-Copilot`); existing local copies are backed up before replacement. |
| `diretório global` | The installed global config dirs — `~/.claude`, `~/.codex`, `~/.copilot` — with their instructions, skills, agents and settings. They belong to this machine: self-contained copies, never links, `@` imports or paths into the `repo global`. A change asked "in the global dir" is made there only and affects only this machine; to share it with other machines, change the `repo global` and reinstall. |
