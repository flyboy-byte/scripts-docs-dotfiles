#Requires -Version 5.1
# Installs Rainmeter, builds the WinDash widget, puts it on the desktop and starts it at login.
# Run from anywhere:  powershell -NoProfile -ExecutionPolicy Bypass -File setup\install-widget.ps1
# Safe to re-run.

$ErrorActionPreference = 'Stop'
$WinDash   = Join-Path (Split-Path $PSScriptRoot -Parent) 'WinDash.ps1'
$Rainmeter = Join-Path $env:ProgramFiles 'Rainmeter\Rainmeter.exe'

function Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

if (-not (Test-Path $Rainmeter)) {
    Step 'Installing Rainmeter'
    winget install --id Rainmeter.Rainmeter -e --silent --accept-package-agreements --accept-source-agreements
    if (-not (Test-Path $Rainmeter)) { throw 'Rainmeter did not install.' }
}

# Rainmeter writes its settings (and the Skins path WinDash reads) on first start.
if (-not (Get-Process Rainmeter -ErrorAction SilentlyContinue)) {
    Step 'Starting Rainmeter'
    Start-Process $Rainmeter
    Start-Sleep -Seconds 6
}

Step 'Building the WinDash widget'
powershell -NoProfile -ExecutionPolicy Bypass -File $WinDash -BuildSkin

Step 'Loading it on the desktop'
foreach ($c in 'illustro\Clock', 'illustro\Disk', 'illustro\System', 'illustro\Welcome') { & $Rainmeter '!DeactivateConfig' $c }
& $Rainmeter '!RefreshApp'
Start-Sleep -Seconds 3
& $Rainmeter '!ActivateConfig' 'WinDash' 'WinDash.ini'
Start-Sleep -Seconds 2
& $Rainmeter '!ZPos' '-2' 'WinDash'   # sit on the desktop, behind windows

Step 'Adding WinDash to Startup (syncs the widget, then starts Rainmeter)'
$startup = [Environment]::GetFolderPath('Startup')
Remove-Item (Join-Path $startup 'Rainmeter.lnk') -ErrorAction SilentlyContinue
$ws  = New-Object -ComObject WScript.Shell
$lnk = $ws.CreateShortcut((Join-Path $startup 'WinDash.lnk'))
$lnk.TargetPath       = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$lnk.Arguments        = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$WinDash`" -Launch"
$lnk.WorkingDirectory = Split-Path $WinDash
$lnk.WindowStyle      = 7
$lnk.Save()

Step 'Done. Drag the widget where you like; right-click it for the full window.'
