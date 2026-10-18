<#
.SYNOPSIS
  Installs pieces of work_general into a Claude Code config dir (default: ~/.claude).

.DESCRIPTION
  - Instructions: writes @imports (pointing at this repo) inside a marked block of CLAUDE.md.
  - Skills:       directory junctions ~/.claude/skills/<name> -> repo/skills/<name> (no admin needed).
  - Agents:       copies repo/agents/<name>.md into ~/.claude/agents/.
  - Statusline:   merges entries into settings.json, pointing at this repo.
  Anything replaced is backed up to <ClaudeDir>/backups/work_general-<timestamp>/.
  Re-running is idempotent.

.EXAMPLE
  ./scripts/install.ps1 -List
  ./scripts/install.ps1 -All
  ./scripts/install.ps1 -Instructions communication,coding-discipline -Skills handoff
  ./scripts/install.ps1 -Statusline
#>
[CmdletBinding()]
param(
  [switch]$All,
  [string[]]$Instructions = @(),
  [string[]]$Skills = @(),
  [string[]]$Agents = @(),
  [switch]$Statusline,
  [switch]$List,
  [string]$ClaudeDir = (Join-Path $HOME '.claude')
)

$ErrorActionPreference = 'Stop'
$Repo      = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$RepoFwd   = $Repo -replace '\\', '/'
$Stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupDir = Join-Path $ClaudeDir "backups/work_general-$Stamp"
$Begin     = '<!-- work_general:begin -->'
$End       = '<!-- work_general:end -->'

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
  'Extras: -Statusline'
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
  $rel  = [IO.Path]::GetRelativePath($ClaudeDir, $path)
  $dest = Join-Path $BackupDir $rel
  New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
  Copy-Item $path $dest -Recurse -Force
  "  backup: $dest"
}

New-Item -ItemType Directory -Force $ClaudeDir | Out-Null

# ── Instructions ──────────────────────────────────────────────────────────────
if ($Instructions.Count) {
  Assert-Known 'Instructions' $Instructions
  $md = Join-Path $ClaudeDir 'CLAUDE.md'
  $content = if (Test-Path $md) { Get-Content $md -Raw } else { '' }
  $imports = $Instructions | ForEach-Object { "@$RepoFwd/instructions/$_.md" }
  $block = (@($Begin) + $imports + @($End)) -join "`n"
  $pattern = [regex]::Escape($Begin) + '[\s\S]*?' + [regex]::Escape($End)
  if ($content -match $pattern) {
    $new = [regex]::Replace($content, $pattern, $block)
  } else {
    $new = ($content.TrimEnd() + "`n`n$block`n").TrimStart()
  }
  if ($new -ne $content) {
    if (Test-Path $md) { Backup $md }
    Set-Content $md $new -NoNewline
  }
  "Instructions -> $md : $($Instructions -join ', ')"
}

# ── Skills (junctions) ────────────────────────────────────────────────────────
if ($Skills.Count) {
  Assert-Known 'Skills' $Skills
  $skillsDir = Join-Path $ClaudeDir 'skills'
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

# ── Agents (copies) ───────────────────────────────────────────────────────────
if ($Agents.Count) {
  Assert-Known 'Agents' $Agents
  $agentsDir = Join-Path $ClaudeDir 'agents'
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

# ── settings.json (statusline) ────────────────────────────────────────────────
if ($Statusline) {
  $settingsPath = Join-Path $ClaudeDir 'settings.json'
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
  "Statusline -> $settingsPath"

  $before = if (Test-Path $settingsPath) { (Get-Content $settingsPath -Raw).TrimEnd() } else { '' }
  $after  = $settings | ConvertTo-Json -Depth 20
  if ($after -ne $before) {
    if (Test-Path $settingsPath) { Backup $settingsPath }
    Set-Content $settingsPath $after
  }
}
