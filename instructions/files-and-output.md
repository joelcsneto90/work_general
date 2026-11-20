## Files, output & configuration

`~` means my home directory — expand it (`C:\Users\<user>` on Windows, `/home/<user>` on Linux);
never create a literal `~` folder. Forward slashes work on both platforms.

### Per-project subfolders
Every AI output folder below (`temp`, `handoffs`, `roadmaps`, and any new one added later) is
split by project: files go in `<folder>/<project>/`, never loose in `<folder>/`.

* **`<project>`** = the project the task is about, as the lowercase basename of its repo folder
  (e.g. `estro`, `netit`, `lux`). Decide by the task, not by the cwd: a session opened in my
  home dir or any other non-project folder that works on a project still uses that project's
  subfolder.
* **No project** — the work comes from outside any repository and isn't about one (e.g. a
  session started in the home dir for a general question) → `_general`.
* Create the subfolder if missing. The project is already in the path, so filenames don't
  repeat it.

### Default temp/output directory
If a request would make you generate a file and I don't specify a directory, put it in
`D:/Joel/AIs/temp/<project>/` — not the project root, not the repo working directory.

* **Results with no path given.** E.g. "analyze this API and write the result to a JSON file"
  with no directory named — write it to `D:/Joel/AIs/temp/<project>/`.
* **Scratch/throwaway work.** Any script, intermediate file, or helper created just to carry
  out the task (not a deliverable) belongs there too, even if you intend to clean it up. This
  avoids leftover junk getting tracked by git when cleanup is forgotten.

Only place a file in the project root or another directory when I explicitly ask for that
location, or the file is an actual intended deliverable of the project. If I later ask for a
result to be "here" or elsewhere, move/copy the final result there — scratch scripts and
intermediates still stay in `D:/Joel/AIs/temp/<project>/`.

### Shared output folders
* Handoffs → `D:/Joel/AIs/handoffs/<project>/` (see the `handoff` skill).
* Roadmaps / action plans → `D:/Joel/AIs/roadmaps/<project>/` (see the `roadmap` skill).

### Configuration & secrets
* Never commit real secrets. When a new config section is needed, add only its shape with
  placeholder values to the project's **sample/template** config files.
* Don't edit my local or environment-specific config files (`appsettings.Development.json`,
  `.env`, local launch settings, workspace-level settings, etc.) unless I ask — those hold
  values I manage myself.
* Don't print secret values back in output; redact them.
