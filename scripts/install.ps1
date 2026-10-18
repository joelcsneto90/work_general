<#
.SYNOPSIS
  Installs pieces of work_general into the user-level config of Claude Code (default) or Codex (-Codex).

.DESCRIPTION
  Claude Code (~/.claude):
  - Instructions: @imports (pointing at this repo) inside a marked block of CLAUDE.md.
  - Skills:       directory junctions ~/.claude/skills/<name> -> repo/skills/<name> (no admin needed).
  - Agents:       copies repo/agents/<name>.md into ~/.claude/agents/.
  - Statusline:   merges statusLine + refresh hooks into settings.json, pointing at this repo.

  Codex (~/.codex, with -Codex):
  - Instructions: module contents concatenated into a marked block of AGENTS.md (Codex has no
                  @import, so re-run after a git pull).
  - Skills:       same junctions, into ~/.codex/skills/ (agents/openai.yaml in a skill is Codex metadata).
  - Agents:       skipped (Codex agents use a different TOML format).
  - Statusline:   sets [tui] status_line in config.toml from statusline/codex-status-line.json
                  (Codex only supports built-in items, no custom script).

  Anything replaced is backed up to <Dir>/backups/work_general-<timestamp>/. Re-running is idempotent.

.EXAMPLE
  ./scripts/install.ps1 -List
  ./scripts/install.ps1 -All
  ./scripts/install.ps1 -All -Codex
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
  [switch]$List,
  [string]$Dir = (Join-Path $HOME $(if ($Codex) { '.codex' } else { '.claude' }))
)

$ErrorActionPreference = 'Stop'
$Repo      = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$RepoFwd   = $Repo -replace '\\', '/'
$Stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupDir = Join-Path $Dir "backups/work_general-$Stamp"
$Begin     = '<!-- work_general:begin -->'
$End       = '<!-- work_general:end -->'
$Tool      = if ($Codex) { 'Codex' } else { 'Claude Code' }

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
  'Extras: -Statusline   Target: -Codex (default: Claude Code)'
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

"Target: $Tool ($Dir)"
New-Item -ItemType Directory -Force $Dir | Out-Null

# ── Instructions ──────────────────────────────────────────────────────────────
if ($Instructions.Count) {
  Assert-Known 'Instructions' $Instructions
  if ($Codex) {
    $md = Join-Path $Dir 'AGENTS.md'
    $body = @("<!-- generated from $RepoFwd — edit there, then re-run install.ps1 -Codex -->") +
      ($Instructions | ForEach-Object { (Get-Content (Join-Path $Repo "instructions/$_.md") -Raw).Trim() })
    $inner = $body -join "`n`n"
  } else {
    $md = Join-Path $Dir 'CLAUDE.md'
    $inner = ($Instructions | ForEach-Object { "@$RepoFwd/instructions/$_.md" }) -join "`n"
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

# ── Skills (junctions) ────────────────────────────────────────────────────────
if ($Skills.Count) {
  Assert-Known 'Skills' $Skills
  $skillsDir = Join-Path $Dir 'skills'
  New-Item -ItemType Directory -Force $skillsDir | Out-Null
  foreach ($s in $Skills) {
    $target = Join-Path $Repo "skills/$s"
    $link   = Join-Path $skillsDir $s
    $item   = Get-Item $link -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -and $item.Target -eq $target) { "Skill $s already linked"; continue }
    if ($item) {
      if (-not $item.LinkType) { Backup $link }
      Remove-Item $link -Recurse -Force
    }
    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
    "Skill $s -> $link"
  }
}

# ── Agents (copies, Claude Code only) ─────────────────────────────────────────
if ($Agents.Count) {
  Assert-Known 'Agents' $Agents
  if ($Codex) {
    "Agents skipped for Codex (different format): $($Agents -join ', ')"
  } else {
    $agentsDir = Join-Path $Dir 'agents'
    New-Item -ItemType Directory -Force $agentsDir | Out-Null
    foreach ($a in $Agents) {
      $src  = Join-Path $Repo "agents/$a.md"
      $dest = Join-Path $agentsDir "$a.md"
      if (Test-Path $dest) {
        if ((Get-FileHash $src).Hash -eq (Get-FileHash $dest).Hash) { "Agent $a up to date"; continue }
        Backup $dest
      }
      Copy-Item $src $dest -Force
      "Agent $a -> $dest"
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
elseif ($Statusline) {
  $settingsPath = Join-Path $Dir 'settings.json'
  $settings = if (Test-Path $settingsPath) { Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable } else { @{} }
  if (-not $settings.ContainsKey('hooks')) { $settings.hooks = [ordered]@{} }

  # Drops any previous entry for this script (old ~/.claude path or this repo), then appends ours.
  function Set-Hook([string]$evt, [string]$marker, [hashtable]$entry) {
    $list = @($settings.hooks[$evt] | Where-Object { $_ } | Where-Object {
      -not ($_.hooks | Where-Object { $_.command -like "*$marker*" })
    })
    $settings.hooks[$evt] = @($list + $entry)
  }

  $cmd = "node `"$RepoFwd/statusline/statusline.js`""
  $settings.statusLine = [ordered]@{ type = 'command'; command = $cmd; padding = 2 }
  foreach ($evt in 'UserPromptSubmit', 'PreToolUse', 'PostToolUse', 'Stop') {
    Set-Hook $evt 'statusline.js' @{ hooks = @(@{ type = 'command'; command = $cmd }) }
  }

  $after  = $settings | ConvertTo-Json -Depth 20
  $before = if (Test-Path $settingsPath) { (Get-Content $settingsPath -Raw).TrimEnd() } else { '' }
  if ($after -ne $before) { Write-IfChanged $settingsPath "$after`n" }
  "Statusline -> $settingsPath"
}
