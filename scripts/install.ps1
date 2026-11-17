<#
.SYNOPSIS
  Installs pieces of work_general into the user-level config of Claude Code (default), Codex (-Codex)
  or GitHub Copilot (-Copilot).

.DESCRIPTION
  Everything is COPIED into the target dir, which then belongs to the machine: nothing installed
  points back at this repo, so local edits there stay local, and a change here only reaches a
  machine when install.ps1 is re-run on it (which overwrites the copies, backing them up first).

  Claude Code (~/.claude):
  - Instructions: copies modules into ~/.claude/instructions/ and @imports them in a marked block
                  of CLAUDE.md.
  - Skills:       copies repo/skills/<name> into ~/.claude/skills/<name> (replaces old junctions).
  - Agents:       copies repo/agents/<name>.md into ~/.claude/agents/.
  - Statusline:   copies statusline.js into ~/.claude/ and merges statusLine + refresh hooks into
                  settings.json, pointing at that copy.

  Codex (~/.codex, with -Codex):
  - Instructions: module contents concatenated into a marked block of AGENTS.md (Codex has no
                  @import).
  - Skills:       same copies, into ~/.codex/skills/ (agents/openai.yaml in a skill is Codex metadata).
  - Agents:       skipped (Codex agents use a different TOML format).
  - Statusline:   sets [tui] status_line in config.toml from statusline/codex-status-line.json
                  (Codex only supports built-in items, no custom script).

  GitHub Copilot (~/.copilot, with -Copilot; read by both Copilot CLI and VS Code):
  - Instructions: module contents concatenated into a marked block of copilot-instructions.md
                  (@ references can't point outside the repo).
  - Skills:       same copies, into ~/.copilot/skills/.
  - Agents:       skipped (Copilot agents use a different *.agent.md format).
  - Statusline:   merges the footer.show* flags of statusline/copilot-footer.json into settings.json
                  (Copilot CLI built-in footer items; the Claude script reads Claude-only data).

  Anything replaced is backed up to <Dir>/backups/work_general-<timestamp>/. Re-running is idempotent.

.EXAMPLE
  ./scripts/install.ps1 -List
  ./scripts/install.ps1 -All
  ./scripts/install.ps1 -All -Codex
  ./scripts/install.ps1 -All -Copilot
  ./scripts/install.ps1 -Instructions communication,coding-discipline -Skills handoff
#>
[CmdletBinding()]
param(
  [switch]$All,
  [string[]]$Instructions = @(),
  [string[]]$Skills = @(),
  [string[]]$Agents = @(),
  [switch]$Statusline,
  [switch]$Codex,
  [switch]$Copilot,
  [switch]$List,
  [string]$Dir = (Join-Path $HOME $(if ($Codex) { '.codex' } elseif ($Copilot) { '.copilot' } else { '.claude' }))
)

$ErrorActionPreference = 'Stop'
if ($Codex -and $Copilot) { throw 'Use -Codex or -Copilot, not both (one target per run).' }
$Repo      = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$DirFwd    = $Dir -replace '\\', '/'
$Stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupDir = Join-Path $Dir "backups/work_general-$Stamp"
$Begin     = '<!-- work_general:begin -->'
$End       = '<!-- work_general:end -->'
$Tool      = if ($Codex) { 'Codex' } elseif ($Copilot) { 'GitHub Copilot' } else { 'Claude Code' }

$available = @{
  Instructions = @(Get-ChildItem (Join-Path $Repo 'instructions') -Filter *.md | ForEach-Object BaseName)
  Skills       = @(Get-ChildItem (Join-Path $Repo 'skills') -Directory | ForEach-Object Name)
  Agents       = @(Get-ChildItem (Join-Path $Repo 'agents') -Filter *.md -ErrorAction SilentlyContinue |
                   Where-Object Name -ne 'README.md' | ForEach-Object BaseName)
}

if ($List) {
  foreach ($k in 'Instructions', 'Skills', 'Agents') {
    "${k}: " + ($(if ($available[$k].Count) { $available[$k] -join ', ' } else { '(none)' }))
  }
  'Extras: -Statusline   Target: -Codex | -Copilot (default: Claude Code)'
  return
}

if ($All) {
  $Instructions = $available.Instructions
  $Skills = $available.Skills
  $Agents = $available.Agents
  $Statusline = $true
}

function Assert-Known([string]$kind, [string[]]$names) {
  $bad = $names | Where-Object { $_ -notin $available[$kind] }
  if ($bad) { throw "Unknown ${kind}: $($bad -join ', '). Available: $($available[$kind] -join ', ')" }
}

function Backup([string]$path) {
  $rel  = [IO.Path]::GetRelativePath($Dir, $path)
  $dest = Join-Path $BackupDir $rel
  New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
  Copy-Item $path $dest -Recurse -Force
  "  backup: $dest"
}

# Writes $text to $path only if it changed, backing up the previous version.
function Write-IfChanged([string]$path, [string]$text) {
  $old = if (Test-Path $path) { Get-Content $path -Raw } else { $null }
  if ($old -eq $text) { return }
  if ($null -ne $old) { Backup $path }
  Set-Content $path $text -NoNewline
}

# Copies $src over $dest only if it changed, backing up the previous version. Returns $true if copied.
function Copy-IfChanged([string]$src, [string]$dest) {
  if ((Test-Path $dest) -and (Get-FileHash $src).Hash -eq (Get-FileHash $dest).Hash) { return $false }
  if (Test-Path $dest) { Backup $dest | Out-Host }
  New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
  Copy-Item $src $dest -Force
  return $true
}

function Get-TreeHash([string]$path) {
  (Get-ChildItem $path -Recurse -File -Force | Sort-Object FullName | ForEach-Object {
    [IO.Path]::GetRelativePath($path, $_.FullName) + ':' + (Get-FileHash $_.FullName).Hash
  }) -join "`n"
}

"Target: $Tool ($Dir)"
New-Item -ItemType Directory -Force $Dir | Out-Null

# ── Instructions ──────────────────────────────────────────────────────────────
if ($Instructions.Count) {
  Assert-Known 'Instructions' $Instructions
  if ($Codex -or $Copilot) {
    $md   = Join-Path $Dir $(if ($Codex) { 'AGENTS.md' } else { 'copilot-instructions.md' })
    $flag = if ($Codex) { '-Codex' } else { '-Copilot' }
    $body = @("<!-- installed by work_general install.ps1 ${flag}: machine copy, edit here; a reinstall overwrites it (with backup) -->") +
      ($Instructions | ForEach-Object { (Get-Content (Join-Path $Repo "instructions/$_.md") -Raw).Trim() })
    $inner = $body -join "`n`n"
  } else {
    $md = Join-Path $Dir 'CLAUDE.md'
    foreach ($i in $Instructions) {
      [void](Copy-IfChanged (Join-Path $Repo "instructions/$i.md") (Join-Path $Dir "instructions/$i.md"))
    }
    $inner = ($Instructions | ForEach-Object { "@$DirFwd/instructions/$_.md" }) -join "`n"
  }
  $block   = "$Begin`n$inner`n$End"
  $content = if (Test-Path $md) { Get-Content $md -Raw } else { '' }
  $pattern = [regex]::Escape($Begin) + '[\s\S]*?' + [regex]::Escape($End)
  $new = if ($content -match $pattern) {
    [regex]::Replace($content, $pattern, { $block })
  } else {
    ($content.TrimEnd() + "`n`n$block`n").TrimStart()
  }
  Write-IfChanged $md $new
  "Instructions -> $md : $($Instructions -join ', ')"
}

# ── Skills (copies) ───────────────────────────────────────────────────────────
if ($Skills.Count) {
  Assert-Known 'Skills' $Skills
  $skillsDir = Join-Path $Dir 'skills'
  New-Item -ItemType Directory -Force $skillsDir | Out-Null
  foreach ($s in $Skills) {
    $src  = Join-Path $Repo "skills/$s"
    $dest = Join-Path $skillsDir $s
    $item = Get-Item $dest -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType) {
      $item.Delete()  # old junction into the repo: removes the link only, never its target
    } elseif ($item) {
      if ((Get-TreeHash $src) -eq (Get-TreeHash $dest)) { "Skill $s up to date"; continue }
      Backup $dest
      Remove-Item $dest -Recurse -Force
    }
    Copy-Item $src $dest -Recurse
    "Skill $s -> $dest"
  }
}

# ── Agents (copies, Claude Code only) ─────────────────────────────────────────
if ($Agents.Count) {
  Assert-Known 'Agents' $Agents
  if ($Codex -or $Copilot) {
    "Agents skipped for $Tool (different format): $($Agents -join ', ')"
  } else {
    $agentsDir = Join-Path $Dir 'agents'
    New-Item -ItemType Directory -Force $agentsDir | Out-Null
    foreach ($a in $Agents) {
      $dest = Join-Path $agentsDir "$a.md"
      if (Copy-IfChanged (Join-Path $Repo "agents/$a.md") $dest) { "Agent $a -> $dest" } else { "Agent $a up to date" }
    }
  }
}

# ── Statusline ────────────────────────────────────────────────────────────────
if ($Statusline -and $Codex) {
  $configPath = Join-Path $Dir 'config.toml'
  $items = Get-Content (Join-Path $Repo 'statusline/codex-status-line.json') -Raw | ConvertFrom-Json
  $line  = "status_line = [`n" + (($items | ForEach-Object { "  `"$_`"," }) -join "`n") + "`n]"
  $toml  = if (Test-Path $configPath) { Get-Content $configPath -Raw } else { '' }
  # [tui] section body = everything up to the next table header.
  $tui = [regex]::Match($toml, '(?ms)^\[tui\][ \t]*\r?\n(.*?)(?=^\[|\z)')
  if (-not $tui.Success) {
    $new = ($toml.TrimEnd() + "`n`n[tui]`n$line`n").TrimStart()
  } else {
    $section = $tui.Groups[1]
    $existing = [regex]::Match($section.Value, '(?ms)^status_line\s*=\s*\[.*?\]')
    $newSection = if ($existing.Success) {
      $section.Value.Remove($existing.Index, $existing.Length).Insert($existing.Index, $line)
    } else {
      "$line`n" + $section.Value
    }
    $new = $toml.Remove($section.Index, $section.Length).Insert($section.Index, $newSection)
  }
  Write-IfChanged $configPath $new
  "Statusline -> $configPath [tui] status_line"
}
elseif ($Statusline -and $Copilot) {
  $settingsPath = Join-Path $Dir 'settings.json'
  $settings = if (Test-Path $settingsPath) { Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable } else { @{} }
  if (-not $settings.ContainsKey('footer')) { $settings.footer = [ordered]@{} }
  $flags = Get-Content (Join-Path $Repo 'statusline/copilot-footer.json') -Raw | ConvertFrom-Json -AsHashtable
  foreach ($k in $flags.Keys) { $settings.footer[$k] = $flags[$k] }

  $after  = $settings | ConvertTo-Json -Depth 20
  $before = if (Test-Path $settingsPath) { (Get-Content $settingsPath -Raw).TrimEnd() } else { '' }
  if ($after -ne $before) { Write-IfChanged $settingsPath "$after`n" }
  "Statusline -> $settingsPath footer"
}
elseif ($Statusline) {
  $settingsPath = Join-Path $Dir 'settings.json'
  $settings = if (Test-Path $settingsPath) { Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable } else { @{} }
  if (-not $settings.ContainsKey('hooks')) { $settings.hooks = [ordered]@{} }

  # Drops any previous entry for this script (any path, e.g. an old one into the repo), then appends ours.
  function Set-Hook([string]$evt, [string]$marker, [hashtable]$entry) {
    $list = @($settings.hooks[$evt] | Where-Object { $_ } | Where-Object {
      -not ($_.hooks | Where-Object { $_.command -like "*$marker*" })
    })
    $settings.hooks[$evt] = @($list + $entry)
  }

  [void](Copy-IfChanged (Join-Path $Repo 'statusline/statusline.js') (Join-Path $Dir 'statusline.js'))
  $cmd = "node `"$DirFwd/statusline.js`""
  $settings.statusLine = [ordered]@{ type = 'command'; command = $cmd; padding = 2 }
  foreach ($evt in 'UserPromptSubmit', 'PreToolUse', 'PostToolUse', 'Stop') {
    Set-Hook $evt 'statusline.js' @{ hooks = @(@{ type = 'command'; command = $cmd }) }
  }

  $after  = $settings | ConvertTo-Json -Depth 20
  $before = if (Test-Path $settingsPath) { (Get-Content $settingsPath -Raw).TrimEnd() } else { '' }
  if ($after -ne $before) { Write-IfChanged $settingsPath "$after`n" }
  "Statusline -> $settingsPath"
}
