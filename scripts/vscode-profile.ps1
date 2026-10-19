<#
.SYNOPSIS
  Creates/updates VS Code profiles per stack: extensions differ, everything else comes from Default.

.DESCRIPTION
  VS Code profiles do not layer on top of Default: each profile has its own settings,
  keybindings, snippets, etc. unless it is flagged to use Default's (useDefaultFlags).

  Default mode (VS Code may be running):
  - A missing profile is created by opening the first -Open path (or an empty window) with
    --profile, since the CLI can only install into a profile that already exists.
  - Installs $Always + the profile's extensions into it. Re-running is idempotent.
  - Writes $BaseSettings into Default's User/settings.json (other keys untouched).
  - Each -Open path is opened with --profile, which stores the workspace -> profile association.

  -ShareDefault (VS Code must be closed, it rewrites storage.json on exit):
  - Sets useDefaultFlags on every non-default profile so it uses Default's $Shared resources.
    Extensions stay per profile. Backs up storage.json first.

.EXAMPLE
  ./scripts/vscode-profile.ps1 -Name default,dotnet,angular,react
  ./scripts/vscode-profile.ps1 -Name dotnet -Open D:\path\Project.code-workspace
  ./scripts/vscode-profile.ps1 -ShareDefault     # with VS Code closed
#>
[CmdletBinding()]
param(
  [ValidateSet('default', 'dotnet', 'angular', 'react')]
  [string[]]$Name = @('default'),
  [string[]]$Open = @(),
  [switch]$ShareDefault
)

$ErrorActionPreference = 'Stop'
$UserDir = Join-Path $env:APPDATA 'Code\User'
$StoragePath = Join-Path $UserDir 'globalStorage\storage.json'

$Always = @('anthropic.claude-code', 'ms-vscode.vs-keybindings')

$BaseSettings = [ordered]@{
  'workbench.sideBar.location'   = 'right'
  'workbench.colorTheme'         = 'Visual Studio Dark'
  'claudeCode.preferredLocation' = 'sidebar'
}

# Resources a profile takes from Default. Not extensions (the point of the profile) and not
# globalState, which also holds the extension enable/disable list.
$Shared = @('settings', 'keybindings', 'snippets', 'tasks', 'prompts', 'mcp')

$Frontend = @(
  'dbaeumer.vscode-eslint',
  'esbenp.prettier-vscode',
  'ecmel.vscode-html-css',
  'christian-kohler.path-intellisense'
)

# TypeScript, JavaScript, HTML and CSS language support is built into VS Code.
$Profiles = @{
  default = @()
  dotnet  = @('ms-dotnettools.vscode-dotnet-runtime', 'ms-dotnettools.csharp', 'ms-dotnettools.csdevkit')
  angular = $Frontend + 'angular.ng-template'
  react   = $Frontend + 'dsznajder.es7-react-js-snippets'
}

if ($ShareDefault) {
  if (Get-Process Code -ErrorAction SilentlyContinue) { throw 'Close VS Code first: it rewrites storage.json on exit.' }
  Copy-Item $StoragePath "$StoragePath.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
  $storage = Get-Content $StoragePath -Raw | ConvertFrom-Json -AsHashtable
  $flags = [ordered]@{}
  foreach ($r in $Shared) { $flags[$r] = $true }
  foreach ($p in $storage.userDataProfiles) {
    $p.useDefaultFlags = $flags
    "Profile $($p.name) uses Default for: $($Shared -join ', ')"
  }
  Set-Content $StoragePath ($storage | ConvertTo-Json -Depth 20)
  return
}

function ProfileArgs([string]$p) { if ($p -eq 'default') { @() } else { @('--profile', $p) } }

function Test-Profile([string]$p) { -not ((code --list-extensions @(ProfileArgs $p) 2>&1) -match 'not found') }

# Text edit instead of a JSON round-trip: settings.json is JSONC and may hold comments.
function Set-BaseSettings([string]$path) {
  $text = Get-Content $path -Raw
  foreach ($key in $BaseSettings.Keys) {
    $value = $BaseSettings[$key] | ConvertTo-Json
    $pattern = '"' + [regex]::Escape($key) + '"\s*:\s*"[^"]*"'
    $text = if ($text -match $pattern) {
      [regex]::Replace($text, $pattern, "`"$key`": $value")
    } else {
      $comma = if ($text -match '^\s*\{\s*\}\s*$') { '' } else { ',' }
      ([regex]'\{').Replace($text, "{`n    `"$key`": $value$comma", 1)
    }
  }
  Set-Content $path $text -NoNewline
}

$created = $false
foreach ($p in $Name) {
  if (-not (Test-Profile $p)) {
    if ($Open.Count) { code --profile $p $Open[0] } else { code --profile $p --new-window }
    $deadline = (Get-Date).AddSeconds(30)
    while (-not (Test-Profile $p)) {
      if ((Get-Date) -gt $deadline) { throw "Profile '$p' was not created within 30s." }
      Start-Sleep -Seconds 1
    }
    "Profile $p created"
    $created = $true
  }

  $installed = @(code --list-extensions @(ProfileArgs $p))
  foreach ($ext in $Always + $Profiles[$p]) {
    if ($ext -in $installed) { "Extension $ext already in $p"; continue }
    code --install-extension $ext @(ProfileArgs $p)
  }

  foreach ($path in $Open) {
    code @(ProfileArgs $p) $path
    "Opened $path with profile $p"
  }
}

Set-BaseSettings (Join-Path $UserDir 'settings.json')
'Base settings -> Default settings.json'
if ($created) { 'New profile: close VS Code and run with -ShareDefault so it uses Default settings.' }
