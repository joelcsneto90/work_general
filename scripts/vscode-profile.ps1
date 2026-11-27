<#
.SYNOPSIS
  Creates/updates VS Code profiles with independent copies of common settings, keybindings and extensions.

.DESCRIPTION
  - A missing profile is created by opening the first -Open path (or an empty window) with
    --profile, since the CLI can only install into a profile that already exists.
  - Installs the common extensions, non-excluded extensions already installed in Default, and stack
    extensions. Existing extensions are kept.
  - Writes the common settings into each selected profile (other keys untouched).
  - Adds the common keybindings before local keybindings, which keep priority.
  - Each -Open path is opened with --profile, which stores the workspace -> profile association.
  - If a selected profile previously shared settings, keybindings or extensions with Default, close VS Code
    before running so the script can remove those flags and back up storage.json.

.EXAMPLE
  ./scripts/vscode-profile.ps1 -Name default,dotnet,angular,react
  ./scripts/vscode-profile.ps1 -Name dotnet -Open D:\path\Project.code-workspace
#>
#Requires -Version 7
[CmdletBinding()]
param(
  [ValidateSet('default', 'dotnet', 'angular', 'react')]
  [string[]]$Name = @('default'),
  [string[]]$Open = @()
)

$ErrorActionPreference = 'Stop'
$UserDir = if ($IsWindows) {
  Join-Path $env:APPDATA 'Code/User'
} else {
  Join-Path ($env:XDG_CONFIG_HOME ?? (Join-Path $HOME '.config')) 'Code/User'
}
$StoragePath = Join-Path $UserDir 'globalStorage/storage.json'

$DefaultExtensions = @(
  'anthropic.claude-code',
  'github.copilot-chat',
  'ms-vscode.vs-keybindings',
  'ms-azuretools.vscode-bicep',
  'ms-azuretools.vscode-azureappservice',
  'ms-azuretools.vscode-azurestaticwebapps',
  'ms-azuretools.vscode-azurefunctions',
  'ms-azuretools.vscode-azurestorage',
  'ms-azuretools.vscode-cosmosdb',
  'ms-azuretools.vscode-azurevirtualmachines',
  'ms-azuretools.vscode-azurecontainerapps',
  'ms-azuretools.azure-dev',
  'ms-azuretools.vscode-azure-github-copilot',
  'ms-azuretools.vscode-azure-mcp-server',
  'ms-azure-load-testing.microsoft-testing',
  'ecmel.vscode-html-css',
  'esbenp.prettier-vscode'
)

# The Azure Tools pack pulls in Foundry Toolkit; install the other Azure tools individually.
$ExcludedDefaultExtensions = @(
  'ms-vscode.vscode-node-azure-pack',
  'ms-windows-ai-studio.windows-ai-studio',
  'teamsdevapp.vscode-ai-foundry'
)

$DefaultSettings = [ordered]@{
  'workbench.sideBar.location'   = 'right'
  'workbench.colorTheme'         = 'Visual Studio Dark'
  'claudeCode.preferredLocation' = 'sidebar'
  # Don't auto-attach the active editor file to Copilot chats (may be sensitive).
  'chat.implicitContext.enabled' = [ordered]@{ panel = 'never'; 'editing-session' = 'never' }
  'github.copilot.chat.agent.currentEditorContext.enabled' = $false
  # Same for Claude Code. Application scope: user settings only, a workspace can't set it.
  'claudeCode.attachOpenFile'    = $false
  # Source Control as a folder tree with compacted single-child folders, like Visual Studio's Git Changes.
  'scm.defaultViewMode'          = 'tree'
  'scm.compactFolders'           = $true
  'scm.defaultViewSortKey'       = 'path'
}

$DefaultKeybindings = @(
  [ordered]@{ key = 'f2'; command = 'editor.action.rename'; when = 'editorHasRenameProvider && editorTextFocus && !editorReadonly' }
  [ordered]@{ key = 'f12'; command = 'editor.action.revealDefinition'; when = 'editorHasDefinitionProvider && editorTextFocus' }
  [ordered]@{ key = 'ctrl+m'; command = 'editor.fold'; when = 'editorTextFocus' }
)

# TypeScript, JavaScript, HTML and CSS language support is built into VS Code.
$Profiles = @{
  default = @()
  dotnet  = @('ms-dotnettools.vscode-dotnet-runtime', 'ms-dotnettools.csharp', 'ms-dotnettools.csdevkit')
  angular = @('dbaeumer.vscode-eslint', 'angular.ng-template')
  react   = @('dbaeumer.vscode-eslint')
}

function ProfileArgs([string]$p) { if ($p -eq 'default') { @() } else { @('--profile', $p) } }

function Read-ProfileStorage {
  if (Test-Path -LiteralPath $StoragePath) {
    Get-Content -LiteralPath $StoragePath -Raw | ConvertFrom-Json -AsHashtable
  }
}

# Text edit instead of a JSON round-trip: settings.json is JSONC and may hold comments.
function Set-BaseSettings([string]$path) {
  $text = if (Test-Path -LiteralPath $path) { Get-Content -LiteralPath $path -Raw }
  if ([string]::IsNullOrWhiteSpace($text)) { $text = "{`n}`n" }
  foreach ($key in $DefaultSettings.Keys) {
    $value = $DefaultSettings[$key] | ConvertTo-Json -Compress
    # Value: string, flat object, or scalar (bool/number).
    $pattern = '"' + [regex]::Escape($key) + '"\s*:\s*("[^"]*"|\{[^{}]*\}|[^,\s}]+)'
    $text = if ($text -match $pattern) {
      [regex]::Replace($text, $pattern, "`"$key`": $value")
    } else {
      $comma = if ($text -match '^\s*\{\s*\}\s*$') { '' } else { ',' }
      ([regex]'\{').Replace($text, "{`n    `"$key`": $value$comma", 1)
    }
  }
  Set-Content -LiteralPath $path -Value $text -NoNewline
}

function Set-BaseKeybindings([string]$path) {
  $text = if (Test-Path -LiteralPath $path) { Get-Content -LiteralPath $path -Raw }
  if ([string]::IsNullOrWhiteSpace($text)) { $text = "[]`n" }
  $begin = '// work_general:keybindings:begin'
  $end = '// work_general:keybindings:end'
  $text = $text -replace "(?ms)(?<=\n)  $begin\r?\n.*?^  $end\r?\n", ''
  $local = ConvertFrom-Json -InputObject $text -NoEnumerate
  $opening = [regex]::Match($text, '\A(?:\s|//[^\r\n]*|/\*[\s\S]*?\*/)*\[')
  if ($local -isnot [array] -or -not $opening.Success) { throw "Expected a keybindings array in '$path'." }

  $entries = ($DefaultKeybindings | ForEach-Object { '  ' + ($_ | ConvertTo-Json -Compress) }) -join ",`n"
  if ($local.Count) { $entries += ',' }
  $index = $opening.Length
  if ($text.Substring($index) -match '^\r?\n') {
    $index += $Matches[0].Length
  } else {
    $text = $text.Insert($index, "`n")
    $index++
  }
  Set-Content -LiteralPath $path -Value ($text.Insert($index, "  $begin`n$entries`n  $end`n")) -NoNewline
}

$managedResources = @('settings', 'extensions', 'keybindings')
$storage = Read-ProfileStorage
$sharedProfiles = @($storage.userDataProfiles | Where-Object {
  $profile = $_
  $profile.name -in $Name -and ($managedResources | Where-Object { $profile.useDefaultFlags -and $profile.useDefaultFlags[$_] })
})
if ($sharedProfiles.Count) {
  if (Get-Process code -ErrorAction SilentlyContinue) {
    throw 'Close VS Code before converting shared profile resources into independent copies.'
  }
  Copy-Item -LiteralPath $StoragePath -Destination "$StoragePath.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
  foreach ($profile in $sharedProfiles) {
    foreach ($resource in $managedResources) { $profile.useDefaultFlags.Remove($resource) }
    "Profile $($profile.name) now owns its settings, extensions and keybindings"
  }
  Set-Content -LiteralPath $StoragePath ($storage | ConvertTo-Json -Depth 100)
}

$installedDefault = @(code --list-extensions)
if ($LASTEXITCODE -ne 0) { throw 'Could not list extensions in Default.' }
$commonExtensions = @($DefaultExtensions + $installedDefault |
  Where-Object { $_ -notin $ExcludedDefaultExtensions } | Select-Object -Unique)
foreach ($p in $Name) {
  $profileDir = $UserDir
  $installed = $installedDefault
  if ($p -ne 'default') {
    $profile = $storage.userDataProfiles | Where-Object name -EQ $p
    if (-not $profile) {
      if ($Open.Count) { code --profile $p $Open[0] } else { code --profile $p --new-window }
      if ($LASTEXITCODE -ne 0) { throw "Could not open VS Code to create profile '$p'." }
      $deadline = (Get-Date).AddSeconds(30)
      do {
        Start-Sleep -Seconds 1
        $storage = Read-ProfileStorage
        $profile = $storage.userDataProfiles | Where-Object name -EQ $p
      } until ($profile -or (Get-Date) -ge $deadline)
      if (-not $profile) { throw "Profile '$p' was not created within 30s." }
      "Profile $p created"
    }
    if (-not $profile.location) { throw "Could not find the settings directory for profile '$p'." }
    $profileDir = Join-Path (Join-Path $UserDir 'profiles') $profile.location
    $installed = @(code --list-extensions @(ProfileArgs $p))
    if ($LASTEXITCODE -ne 0) { throw "Could not list extensions in profile '$p'." }
  }

  $installArgs = foreach ($ext in $commonExtensions + $Profiles[$p] | Select-Object -Unique) {
    if ($ext -notin $installed) { '--install-extension'; $ext }
  }
  if ($installArgs) {
    "Installing missing extensions in $p"
    code @installArgs @(ProfileArgs $p)
    if ($LASTEXITCODE -ne 0) { throw "Could not install extensions in profile '$p'." }
  } else {
    "Extensions already up to date in $p"
  }

  $null = New-Item -Path $profileDir -ItemType Directory -Force
  Set-BaseSettings (Join-Path $profileDir 'settings.json')
  "Base settings -> $p settings.json"
  Set-BaseKeybindings (Join-Path $profileDir 'keybindings.json')
  "Base keybindings -> $p keybindings.json"

  foreach ($path in $Open) {
    code @(ProfileArgs $p) $path
    if ($LASTEXITCODE -ne 0) { throw "Could not open '$path' with profile '$p'." }
    "Opened $path with profile $p"
  }
}
