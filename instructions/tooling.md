## Tooling habits

### Searching files
* Prefer the dedicated Grep/Glob tools — they respect `.gitignore`.
* Raw shell commands (`find`, `ls -R`, shell `grep`) do **not** respect `.gitignore`. Exclude
  build-output and dependency dirs up front: `bin/`, `obj/` (.NET), `node_modules/`, `dist/`,
  `build/`, `target/`, `.vs/`, `.git/`. Don't discover the noise and fix it afterwards.

### Reading web pages
* If WebFetch/curl returns only a page shell (nav/footer, empty app div, "Loading…") or the page
  looks login-gated, don't conclude it's unreadable. Use the `web-fetch-spa` skill (Playwright
  with the installed Chrome) first, then judge.

### Environment
* Windows machine; both PowerShell and Git Bash are available. Use each with its own syntax.
* Don't download large tooling (browsers, SDKs) when something already installed can do the job.
