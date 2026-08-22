#requires -Version 7
<#
  sync.ps1 save   -> copy live config files INTO this repo (run before commit)
  sync.ps1 apply  -> copy repo files OUT to their live locations (new machine)
#>
param([ValidateSet('save','apply')][string]$Mode = 'save')

$repo = $PSScriptRoot
$wt   = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$ps   = "$HOME\Documents\PowerShell"

# repo-relative path  ->  live path
$map = [ordered]@{
  'powershell/Microsoft.PowerShell_profile.ps1' = "$ps\Microsoft.PowerShell_profile.ps1"
  'powershell/powershell.config.json'           = "$ps\powershell.config.json"
  'psmux/.psmux.conf'                           = "$HOME\.psmux.conf"
  'psmux/.psmux-binds.conf'                     = "$HOME\.psmux-binds.conf"
  'psmux/.psmux-theme-dark.conf'                = "$HOME\.psmux-theme-dark.conf"
  'psmux/.psmux-theme-light.conf'               = "$HOME\.psmux-theme-light.conf"
  'psmux/.psmux-theme-watch.ps1'                = "$HOME\.psmux-theme-watch.ps1"
  'psmux/.psmux-theme.cmd'                      = "$HOME\.psmux-theme.cmd"
  'windows-terminal/settings.json'              = $wt
  'git/.gitconfig'                              = "$HOME\.gitconfig"
}

foreach ($k in $map.Keys) {
  $inRepo = Join-Path $repo $k
  $live   = $map[$k]
  $src, $dst = if ($Mode -eq 'save') { $live, $inRepo } else { $inRepo, $live }
  if (-not (Test-Path -LiteralPath $src)) { Write-Warning "missing: $src"; continue }
  New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
  Copy-Item -LiteralPath $src -Destination $dst -Force
  Write-Host "$k"
}

# package + module lists
if (Get-Command scoop -EA SilentlyContinue) {
  if ($Mode -eq 'save') { scoop export | Set-Content "$repo\scoop\scoopfile.json" }
  else                  { scoop import "$repo\scoop\scoopfile.json" }
}
if ($Mode -eq 'apply' -and (Get-Command winget -EA SilentlyContinue)) {
  Get-Content "$repo\winget\apps.txt" |
    ForEach-Object { ($_ -replace '#.*').Trim() } | Where-Object { $_ } |
    ForEach-Object { winget install --id $_ -e --accept-package-agreements --accept-source-agreements }
}
if ($Mode -eq 'apply' -and (Get-Command volta -EA SilentlyContinue)) { volta install node@24 }

$modFile = "$repo\powershell\modules.txt"
if ($Mode -eq 'save') {
  Get-InstalledModule | Select-Object -Expand Name | Sort-Object | Set-Content $modFile
} elseif (Test-Path $modFile) {
  Get-Content $modFile | Where-Object { $_ -and -not (Get-Module -ListAvailable $_) } |
    ForEach-Object { Install-Module $_ -Scope CurrentUser -Force }
}
Write-Host "`n$Mode done." -ForegroundColor Green
