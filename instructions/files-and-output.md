## Files, output & configuration

### Default temp/output directory
If a request would make you generate a file and I don't specify a directory, put it in
`D:\Joel\AIs\temp\<project>\` — not the project root, not the repo working directory.

* **`<project>`** = the project the task is about, as the lowercase basename of its repo folder
  (e.g. `estro`, `netit`, `lux`). Decide by the task, not by the cwd: a session opened in my
  home dir or any other non-project folder that works on a project still uses that project's
  subfolder. Task tied to no project → `_general`. Create the subfolder if missing.
* **Results with no path given.** E.g. "analyze this API and write the result to a JSON file"
  with no directory named — write it to `D:\Joel\AIs\temp\<project>\`.
* **Scratch/throwaway work.** Any script, intermediate file, or helper created just to carry
  out the task (not a deliverable) belongs there too, even if you intend to clean it up. This
  avoids leftover junk getting tracked by git when cleanup is forgotten.

Only place a file in the project root or another directory when I explicitly ask for that
location, or the file is an actual intended deliverable of the project. If I later ask for a
result to be "here" or elsewhere, move/copy the final result there — scratch scripts and
intermediates still stay in `D:\Joel\AIs\temp\<project>\`.

### Shared output folders
* Handoffs → `D:\Joel\AIs\handoffs` (see the `handoff` skill).
* Roadmaps / action plans → `D:\Joel\AIs\roadmaps` (see the `roadmap` skill).

### Configuration & secrets
* Never commit real secrets. When a new config section is needed, add only its shape with
  placeholder values to the project's **sample/template** config files.
* Don't edit my local or environment-specific config files (`appsettings.Development.json`,
  `.env`, local launch settings, workspace-level settings, etc.) unless I ask — those hold
  values I manage myself.
* Don't print secret values back in output; redact them.
