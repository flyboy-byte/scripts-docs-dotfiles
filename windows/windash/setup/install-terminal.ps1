#Requires -Version 5.1
# Terminal makeover: PowerShell 7, Oh My Posh (powerlevel10k look), Meslo Nerd Font, Terminal-Icons,
# gray history suggestions, and Windows Terminal defaults. Works for both PowerShell 5.1 and 7.
# Run:  powershell -NoProfile -ExecutionPolicy Bypass -File setup\install-terminal.ps1 [-SkipPwsh]
# Safe to re-run. Existing profile and Windows Terminal settings are backed up first.
param([switch]$SkipPwsh)

$ErrorActionPreference = 'Stop'
$Repo = Split-Path $PSScriptRoot -Parent
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Update-SessionPath { $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User') }
function Install-Winget($id) {
    winget list --id $id -e --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -ne 0) { winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements }
}

Step 'Installing Oh My Posh'
Install-Winget 'JanDeDobbeleer.OhMyPosh'
if (-not $SkipPwsh) { Step 'Installing PowerShell 7'; Install-Winget 'Microsoft.PowerShell' }
Update-SessionPath
$pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source

Step 'Downloading prompt themes'
$themes = Join-Path $HOME '.config\oh-my-posh\themes'
New-Item -ItemType Directory -Force $themes | Out-Null
foreach ($t in 'powerlevel10k_modern', 'powerlevel10k_rainbow', 'powerlevel10k_classic', 'powerlevel10k_lean', 'robbyrussell') {
    curl.exe -sSfL -o (Join-Path $themes "$t.omp.json") "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$t.omp.json"
}

Step 'Installing Meslo Nerd Font (the font powerlevel10k recommends)'
oh-my-posh font install Meslo --plain | Out-Null

Step 'Allowing local scripts (RemoteSigned for this user) so the profile can load'
try { Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force } catch { }   # warns harmlessly when a process override is active

Step 'Installing Terminal-Icons and a newer PSReadLine for Windows PowerShell 5.1'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (-not (Get-PackageProvider -ListAvailable NuGet -ErrorAction SilentlyContinue | Where-Object Version -ge 2.8.5.201)) {
    Install-PackageProvider NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
}
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module Terminal-Icons -Scope CurrentUser -Force
Install-Module PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck -AllowClobber   # 5.1 ships 2.0, suggestions need 2.1+
if ($pwsh) {
    Step 'Installing Terminal-Icons for PowerShell 7'
    & $pwsh -NoLogo -NoProfile -Command 'Install-PSResource Terminal-Icons -Scope CurrentUser -TrustRepository -Quiet' 2>$null
}

Step 'Installing the shared profile'
$docs = [Environment]::GetFolderPath('MyDocuments')
$p51 = Join-Path $docs 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
$p7  = Join-Path $docs 'PowerShell\Microsoft.PowerShell_profile.ps1'
New-Item -ItemType Directory -Force (Split-Path $p51), (Split-Path $p7) | Out-Null
foreach ($p in $p51, $p7) { if (Test-Path $p) { Copy-Item $p "$p.bak-$Stamp" } }
Copy-Item (Join-Path $Repo 'terminal\profile.ps1') $p51 -Force
Set-Content -Path $p7 -Encoding UTF8 -Value @(
    '# PowerShell 7 shares the Windows PowerShell 5.1 profile so the prompt/theme lives in one place.'
    '. "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"'
)

Step 'Setting the font for the classic console (fallback)'
$k = 'HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe'
if (-not (Test-Path $k)) { New-Item $k -Force | Out-Null }
Set-ItemProperty $k -Name FaceName -Value 'MesloLGS Nerd Font'
Set-ItemProperty $k -Name FontFamily -Value 0x36 -Type DWord

$wt = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Packages') -Directory -Filter 'Microsoft.WindowsTerminal*' -ErrorAction SilentlyContinue |
    ForEach-Object { Join-Path $_.FullName 'LocalState\settings.json' } | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($wt) {
    Step 'Configuring Windows Terminal (font, PowerShell 7 as default)'
    Copy-Item $wt "$wt.bak-$Stamp"
    # Windows PowerShell's JSON parser rejects comments, so drop whole-line // comments first.
    $json = (Get-Content $wt) | Where-Object { $_.TrimStart() -notmatch '^//' } | Out-String | ConvertFrom-Json
    if (-not $json.profiles.defaults) { $json.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) -Force }
    $json.profiles.defaults | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{ face = 'MesloLGS Nerd Font'; size = 11 }) -Force
    if ($pwsh) {
        $guid = '{574e775e-4f2a-5b96-ac1e-a2962a402336}'   # Windows Terminal's id for PowerShell 7
        if (-not ($json.profiles.list | Where-Object guid -eq $guid)) {
            $json.profiles.list = @([pscustomobject]@{ commandline = 'pwsh.exe -NoLogo'; guid = $guid; hidden = $false; name = 'PowerShell 7'; source = 'Windows.Terminal.PowershellCore' }) + @($json.profiles.list)
        }
        $json.defaultProfile = $guid
    }
    $json | ConvertTo-Json -Depth 32 | Set-Content -Path $wt -Encoding UTF8
} else {
    Write-Warning 'Windows Terminal not found; install it from the Microsoft Store, then re-run this script.'
}

Step 'Done. Open a NEW terminal window to see the prompt.'
