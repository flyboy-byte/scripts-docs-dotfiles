#Requires -Version 5.1
# WinDash - a small toggle dashboard for ReviOS tweaks: power, privacy, background services, look & feel.
# Run:  powershell -NoProfile -ExecutionPolicy Bypass -STA -File WinDash.ps1
#       -Status           print every toggle's current state instead of opening the window
#       -Flip <id>        flip one toggle (used by the Rainmeter widget)
#       -Export           write current states for the Rainmeter widget
#       -BuildSkin        (re)generate the Rainmeter widget from the toggle list below
#       -RestartExplorer  restart Explorer so Look & feel changes show
#       -Launch           sync the widget then start Rainmeter (run at logon from the Startup folder)
#       -WinUtil          open Chris Titus Tech's WinUtil in an admin PowerShell window
param([switch]$Status, [string]$Flip, [switch]$Export, [switch]$BuildSkin, [switch]$RestartExplorer, [switch]$Launch, [switch]$WinUtil)

$ErrorActionPreference = 'Stop'

$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $argList = "-NoProfile -ExecutionPolicy Bypass -STA -File `"$PSCommandPath`""
    foreach ($p in $PSBoundParameters.GetEnumerator()) {
        if ($p.Value -is [switch]) { $argList += " -$($p.Key)" } else { $argList += " -$($p.Key) $($p.Value)" }
    }
    Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList $argList
    return
}

$LogFile      = Join-Path $PSScriptRoot 'windash.log'
$UltraGuid    = '3ff9831b-6f80-4830-8178-736cd4229e7b'   # Revision - Ultra Performance (ReviOS only)
$BalancedGuid = '381b4222-f694-41f0-9685-ff5bb260df2e'   # Windows Balanced
# Without ReviOS, the "performance" side of the power toggles uses Windows' built-in High performance plan.
if (((powercfg /list) -join "`n") -notmatch $UltraGuid) { $UltraGuid = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c' }
$AutoTaskName = 'WinDash Auto Power Plan'

# ---------------- helpers ----------------

function Write-Log($msg) { Add-Content -Path $LogFile -Value ("{0:yyyy-MM-dd HH:mm:ss}  {1}" -f (Get-Date), $msg) }

function Get-RegValue($Path, $Name) {
    try { (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name } catch { $null }
}

function Set-RegValue($Path, $Name, $Value, $Type = 'DWord') {
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Remove-RegValue($Path, $Name) {
    if (Test-Path $Path) { Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue }
}

# $StartTypes maps service name -> start type to restore when turned back on.
function Test-ServicesOn([hashtable]$StartTypes) {
    foreach ($n in $StartTypes.Keys) {
        $s = Get-Service $n -ErrorAction SilentlyContinue
        if ($s -and $s.StartType -ne 'Disabled') { return $true }
    }
    $false
}

function Set-ServicesState([hashtable]$StartTypes, [bool]$On) {
    $failed = @()
    foreach ($n in $StartTypes.Keys) {
        if (-not (Get-Service $n -ErrorAction SilentlyContinue)) { continue }
        try {
            if ($On) {
                Set-Service $n -StartupType $StartTypes[$n]
                if ($StartTypes[$n] -eq 'Automatic') { Start-Service $n -ErrorAction SilentlyContinue }
            } else {
                Stop-Service $n -Force -ErrorAction SilentlyContinue
                Set-Service $n -StartupType Disabled
            }
        } catch { $failed += $n }
    }
    if ($failed) { throw "could not change: $($failed -join ', ')" }
}

# Task Scheduler COM API: milliseconds per lookup vs ~0.4 s for each Get-ScheduledTask call.
$script:TaskService = $null
function Get-TaskService {
    if (-not $script:TaskService) {
        $script:TaskService = New-Object -ComObject Schedule.Service
        $script:TaskService.Connect()
    }
    $script:TaskService
}

function Get-Tasks($Pairs) {
    $svc = Get-TaskService
    foreach ($p in $Pairs) {
        try { $svc.GetFolder($p[0].TrimEnd('\')).GetTask($p[1]) } catch { }
    }
}

function Test-TaskExists([string]$Name) {
    try { [void](Get-TaskService).GetFolder('\').GetTask($Name); $true } catch { $false }
}

function Test-TasksOn($Tasks) { [bool]($Tasks | Where-Object { $_.Enabled }) }

function Set-TasksState($Tasks, [bool]$On) {
    $failed = @()
    foreach ($t in $Tasks) {
        try { $t.Enabled = $On } catch { $failed += $t.Name }
    }
    if ($failed) { throw "could not change: $($failed -join ', ')" }
}

function Get-ActivePlanGuid {
    if ((powercfg /getactivescheme) -match '([0-9a-fA-F-]{36})') { $Matches[1].ToLower() }
}

function Set-PlanForPowerSource {
    Add-Type -AssemblyName System.Windows.Forms
    if ([System.Windows.Forms.SystemInformation]::PowerStatus.PowerLineStatus -eq 'Online') {
        powercfg /setactive $UltraGuid
    } else {
        powercfg /setactive $BalancedGuid
    }
}

# Scheduled task (runs as SYSTEM) that re-applies the plan on every plug/unplug (Kernel-Power event 105) and at boot.
function Register-AutoPowerTask {
    $cmd = "Add-Type -AssemblyName System.Windows.Forms; if ([System.Windows.Forms.SystemInformation]::PowerStatus.PowerLineStatus -eq 'Online') { powercfg /setactive $UltraGuid } else { powercfg /setactive $BalancedGuid }"
    $sub = "<QueryList><Query Id='0' Path='System'><Select Path='System'>*[System[Provider[@Name='Microsoft-Windows-Kernel-Power'] and EventID=105]]</Select></Query></QueryList>"
    $xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo><Description>WinDash: Ultra Performance on AC power, Balanced on battery.</Description></RegistrationInfo>
  <Triggers>
    <EventTrigger><Enabled>true</Enabled><Subscription>$([Security.SecurityElement]::Escape($sub))</Subscription></EventTrigger>
    <BootTrigger><Enabled>true</Enabled></BootTrigger>
  </Triggers>
  <Principals><Principal id="Author"><UserId>S-1-5-18</UserId><RunLevel>HighestAvailable</RunLevel></Principal></Principals>
  <Settings>
    <MultipleInstancesPolicy>Queue</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <ExecutionTimeLimit>PT1M</ExecutionTimeLimit>
    <Enabled>true</Enabled>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-NoProfile -NonInteractive -WindowStyle Hidden -Command "$([Security.SecurityElement]::Escape($cmd))"</Arguments>
    </Exec>
  </Actions>
</Task>
"@
    Register-ScheduledTask -TaskName $AutoTaskName -Xml $xml -Force | Out-Null
}

# ---------------- toggle definitions ----------------
# Get returns $true when the feature named in Name is ON.

$TelemetryTasks = @(
    @('\Microsoft\Windows\Flighting\OneSettings\', 'RefreshCache'),
    @('\Microsoft\Windows\PI\', 'Sqm-Tasks'),
    @('\Microsoft\Windows\CloudExperienceHost\', 'CreateObjectTask'),
    @('\Microsoft\Windows\Maps\', 'MapsToastTask'),
    @('\Microsoft\Windows\Application Experience\', 'PcaPatchDbTask')
)
$SyncServices  = @{ MapsBroker = 'Automatic'; OneSyncSvc = 'Automatic'; TrkWks = 'Automatic' }
$EdgeServices  = @{ edgeupdate = 'Automatic'; edgeupdatem = 'Manual' }
$ClassicMenuKey = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
$ExplorerAdv    = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$Personalize    = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'

function Get-EdgeTasks { (Get-TaskService).GetFolder('\').GetTasks(1) | Where-Object { $_.Name -like 'MicrosoftEdgeUpdateTask*' } }

$Toggles = @(
    # ---- Power
    [pscustomobject]@{ Category = 'Power'; Name = 'Auto power plan'; Explorer = $false
        Desc = 'Max performance plan when plugged in, Balanced on battery. Switches by itself when you plug or unplug.'
        Get  = { Test-TaskExists $AutoTaskName }
        On   = { Register-AutoPowerTask; Set-PlanForPowerSource }
        Off  = { Unregister-ScheduledTask -TaskName $AutoTaskName -Confirm:$false } }
    [pscustomobject]@{ Category = 'Power'; Name = 'Ultra Performance plan'; Explorer = $false
        Desc = 'ReviOS max-performance plan (High performance on non-ReviOS PCs). Off = Balanced. If Auto power plan is on, it wins the next time you plug or unplug.'
        Get  = { (Get-ActivePlanGuid) -eq $UltraGuid }
        On   = { powercfg /setactive $UltraGuid }
        Off  = { powercfg /setactive $BalancedGuid } }

    # ---- Privacy
    [pscustomobject]@{ Category = 'Privacy'; Name = 'Location services'; Explorer = $false
        Desc = 'Lets Windows and apps find your location.'
        Get  = { (Get-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation') -ne 1 }
        On   = { Remove-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation' }
        Off  = { Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation' 1 } }
    [pscustomobject]@{ Category = 'Privacy'; Name = 'Update sharing with other PCs'; Explorer = $false
        Desc = 'Delivery Optimization peer-to-peer. Off = updates come only from Microsoft, nothing is uploaded.'
        Get  = { (Get-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode') -ne 0 }
        On   = { Remove-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode' }
        Off  = { Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode' 0 } }
    [pscustomobject]@{ Category = 'Privacy'; Name = 'Copilot'; Explorer = $false
        Desc = 'Off = policy that blocks Copilot, so updates cannot bring it back.'
        Get  = { (Get-RegValue 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot') -ne 1 -and (Get-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot') -ne 1 }
        On   = { Remove-RegValue 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot'; Remove-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' }
        Off  = { Set-RegValue 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1; Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1 } }
    [pscustomobject]@{ Category = 'Privacy'; Name = 'Suggested & promoted apps'; Explorer = $false
        Desc = 'Microsoft "consumer features" that silently install sponsored apps and suggestions.'
        Get  = { (Get-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures') -ne 1 }
        On   = { Remove-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' }
        Off  = { Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1 } }
    [pscustomobject]@{ Category = 'Privacy'; Name = 'Leftover data-collection tasks'; Explorer = $false
        Desc = 'Flighting, SQM, CloudExperienceHost, MapsToast and PcaPatchDb scheduled tasks that ReviOS left enabled.'
        Get  = { Test-TasksOn (Get-Tasks $TelemetryTasks) }
        On   = { Set-TasksState (Get-Tasks $TelemetryTasks) $true }
        Off  = { Set-TasksState (Get-Tasks $TelemetryTasks) $false } }
    [pscustomobject]@{ Category = 'Privacy'; Name = 'Maps, sync & link-tracking services'; Explorer = $false
        Desc = 'MapsBroker (offline maps), OneSyncSvc (mail/contacts sync), TrkWks (shortcut link tracking).'
        Get  = { Test-ServicesOn $SyncServices }
        On   = { Set-ServicesState $SyncServices $true }
        Off  = { Set-ServicesState $SyncServices $false } }

    # ---- Background & battery
    [pscustomobject]@{ Category = 'Background & battery'; Name = 'Search indexing'; Explorer = $false
        Desc = 'Keeps a file index for fast Start search. Off saves battery and disk activity; file search gets slower.'
        Get  = { Test-ServicesOn @{ WSearch = 'Automatic' } }
        On   = { Set-ServicesState @{ WSearch = 'Automatic' } $true }
        Off  = { Set-ServicesState @{ WSearch = 'Automatic' } $false } }
    [pscustomobject]@{ Category = 'Background & battery'; Name = 'SysMain (app preloading)'; Explorer = $false
        Desc = 'Preloads often-used apps into RAM. Small benefit on an SSD.'
        Get  = { Test-ServicesOn @{ SysMain = 'Automatic' } }
        On   = { Set-ServicesState @{ SysMain = 'Automatic' } $true }
        Off  = { Set-ServicesState @{ SysMain = 'Automatic' } $false } }
    [pscustomobject]@{ Category = 'Background & battery'; Name = 'Print spooler'; Explorer = $false
        Desc = 'Needed for printing and "Print to PDF". Off if you never print from this PC.'
        Get  = { Test-ServicesOn @{ Spooler = 'Automatic' } }
        On   = { Set-ServicesState @{ Spooler = 'Automatic' } $true }
        Off  = { Set-ServicesState @{ Spooler = 'Automatic' } $false } }
    [pscustomobject]@{ Category = 'Background & battery'; Name = 'Edge / WebView2 updater'; Explorer = $false
        Desc = 'Edge is removed, but this also updates WebView2, which some apps use. Off = WebView2 stops getting updates.'
        Get  = { (Test-ServicesOn $EdgeServices) -or (Test-TasksOn (Get-EdgeTasks)) }
        On   = { Set-ServicesState $EdgeServices $true; Set-TasksState (Get-EdgeTasks) $true }
        Off  = { Set-ServicesState $EdgeServices $false; Set-TasksState (Get-EdgeTasks) $false } }
    [pscustomobject]@{ Category = 'Background & battery'; Name = 'Store apps run in background'; Explorer = $false
        Desc = 'Off = policy that stops all Store apps running in the background. Desktop programs are not affected.'
        Get  = { (Get-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsRunInBackground') -ne 2 }
        On   = { Remove-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsRunInBackground' }
        Off  = { Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsRunInBackground' 2 } }

    # ---- Look & feel
    [pscustomobject]@{ Category = 'Look & feel'; Name = 'Classic right-click menu'; Explorer = $true
        Desc = 'Windows 10 style context menu, no "Show more options".'
        Get  = { Test-Path "$ClassicMenuKey\InprocServer32" }
        On   = { New-Item -Path "$ClassicMenuKey\InprocServer32" -Force | Out-Null; Set-ItemProperty -Path "$ClassicMenuKey\InprocServer32" -Name '(default)' -Value '' }
        Off  = { Remove-Item -Path $ClassicMenuKey -Recurse -Force } }
    [pscustomobject]@{ Category = 'Look & feel'; Name = 'Show file extensions'; Explorer = $true
        Desc = 'Shows .exe, .pdf etc. in Explorer.'
        Get  = { (Get-RegValue $ExplorerAdv 'HideFileExt') -eq 0 }
        On   = { Set-RegValue $ExplorerAdv 'HideFileExt' 0 }
        Off  = { Set-RegValue $ExplorerAdv 'HideFileExt' 1 } }
    [pscustomobject]@{ Category = 'Look & feel'; Name = 'Show hidden files'; Explorer = $true
        Desc = 'Shows hidden files and folders like AppData.'
        Get  = { (Get-RegValue $ExplorerAdv 'Hidden') -eq 1 }
        On   = { Set-RegValue $ExplorerAdv 'Hidden' 1 }
        Off  = { Set-RegValue $ExplorerAdv 'Hidden' 2 } }
    [pscustomobject]@{ Category = 'Look & feel'; Name = 'Centered taskbar'; Explorer = $false
        Desc = 'Off = icons on the left like Windows 10.'
        Get  = { (Get-RegValue $ExplorerAdv 'TaskbarAl') -ne 0 }
        On   = { Set-RegValue $ExplorerAdv 'TaskbarAl' 1 }
        Off  = { Set-RegValue $ExplorerAdv 'TaskbarAl' 0 } }
    [pscustomobject]@{ Category = 'Look & feel'; Name = 'Dark mode'; Explorer = $false
        Desc = 'Dark theme for Windows and apps.'
        Get  = { (Get-RegValue $Personalize 'AppsUseLightTheme') -eq 0 }
        On   = { Set-RegValue $Personalize 'AppsUseLightTheme' 0; Set-RegValue $Personalize 'SystemUsesLightTheme' 0 }
        Off  = { Set-RegValue $Personalize 'AppsUseLightTheme' 1; Set-RegValue $Personalize 'SystemUsesLightTheme' 1 } }
    [pscustomobject]@{ Category = 'Look & feel'; Name = 'Transparency effects'; Explorer = $false
        Desc = 'See-through taskbar and Start. Off saves a little GPU and battery.'
        Get  = { (Get-RegValue $Personalize 'EnableTransparency') -ne 0 }
        On   = { Set-RegValue $Personalize 'EnableTransparency' 1 }
        Off  = { Set-RegValue $Personalize 'EnableTransparency' 0 } }
)

# Short ids used on the command line and in the Rainmeter widget.
$ToggleIds = @{
    'Auto power plan' = 'auto'; 'Ultra Performance plan' = 'ultra'
    'Location services' = 'loc'; 'Update sharing with other PCs' = 'dosvc'; 'Copilot' = 'copilot'
    'Suggested & promoted apps' = 'consumer'; 'Leftover data-collection tasks' = 'tasks'; 'Maps, sync & link-tracking services' = 'sync'
    'Search indexing' = 'search'; 'SysMain (app preloading)' = 'sysmain'; 'Print spooler' = 'spooler'
    'Edge / WebView2 updater' = 'edge'; 'Store apps run in background' = 'bgapps'
    'Classic right-click menu' = 'classic'; 'Show file extensions' = 'ext'; 'Show hidden files' = 'hidden'
    'Centered taskbar' = 'center'; 'Dark mode' = 'dark'; 'Transparency effects' = 'transp'
}
foreach ($t in $Toggles) { $t | Add-Member -NotePropertyName Id -NotePropertyValue $ToggleIds[$t.Name] }

function Get-ToggleState($t) { try { [bool](& $t.Get) } catch { $false } }

# Downloads and runs the latest WinUtil from christitus.com in its own visible admin window.
function Start-WinUtil {
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command "irm https://christitus.com/win | iex"'
}

function Invoke-ExplorerRestart {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
}

# ---------------- Rainmeter widget ----------------

$RainmeterExe = Join-Path $env:ProgramFiles 'Rainmeter\Rainmeter.exe'

function Get-SkinDir {
    $skins = $null
    $ini = Join-Path $env:APPDATA 'Rainmeter\Rainmeter.ini'
    if (Test-Path $ini) {
        $m = Select-String -Path $ini -Pattern '^SkinPath=(.+)$' | Select-Object -First 1
        if ($m) { $skins = $m.Matches[0].Groups[1].Value.Trim() }
    }
    if (-not $skins) { $skins = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Rainmeter\Skins' }
    Join-Path $skins 'WinDash'
}

# The widget @Includes this file; it holds the power plan, last message, and each switch's colour/knob position.
# $Only limits the re-check to those toggles and keeps the rest from the existing file (fast path after a click).
function Export-WidgetState([string]$Msg = '', $Only = $null) {
    $res = Join-Path (Get-SkinDir) '@Resources'
    if (-not (Test-Path $res)) { return }
    $file = Join-Path $res 'state.inc'
    $plan = if ((powercfg /getactivescheme) -match '\((.+)\)') { $Matches[1] -replace '^Revision - ', '' } else { 'unknown' }
    $vars = [ordered]@{}
    if ($Only -and (Test-Path $file)) {
        foreach ($l in Get-Content $file) { if ($l -match '^([^=\[]+)=(.*)$') { $vars[$Matches[1]] = $Matches[2] } }
    }
    $vars['Plan'] = $plan
    $vars['Msg'] = $Msg
    $check = if ($Only -and $vars.Count -gt 2) { $Only } else { $Toggles }
    foreach ($t in $check) {
        $on = Get-ToggleState $t
        $vars["C_$($t.Id)"] = if ($on) { '59,130,246,255' } else { '58,63,75,255' }
        $vars["K_$($t.Id)"] = if ($on) { '26' } else { '10' }
    }
    $lines = @('[Variables]') + @($vars.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" })
    Set-Content -Path $file -Value $lines -Encoding Unicode
}

function Update-Widget { if (Test-Path $RainmeterExe) { & $RainmeterExe '!Refresh' 'WinDash' } }

function Build-Skin {
    $dir = Get-SkinDir
    New-Item -ItemType Directory -Force (Join-Path $dir '@Resources') | Out-Null
    $W = 300
    # Runs WinDash hidden through the RunCommand plugin; the widget refreshes when it finishes.
    $run = '[!SetOption MeterMsg Text "Working..."][!UpdateMeter MeterMsg][!Redraw][!SetOption MeasureRun Parameter """-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "#Script#" {0}"""][!UpdateMeasure MeasureRun][!CommandMeasure MeasureRun "Run"]'
    $font = 'FontFace=Segoe UI', 'AntiAlias=1'

    $ini = New-Object System.Collections.Generic.List[string]
    $ini.Add('[Rainmeter]')
    $ini.Add('Update=1000')
    $ini.Add('AccurateText=1')
    $ini.Add('ContextTitle=Open full WinDash')
    $ini.Add('ContextAction=["powershell.exe" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "#Script#"]')
    $ini.Add('ContextTitle2=Sync now')
    $ini.Add('ContextAction2=' + ($run -f '-Export'))
    $ini.Add('ContextTitle3=Restart Explorer')
    $ini.Add('ContextAction3=' + ($run -f '-RestartExplorer'))
    $ini.Add('')
    $ini.Add('[Metadata]')
    $ini.Add('Name=WinDash')
    $ini.Add('Information=Desktop switches for WinDash. Generated by WinDash.ps1 -BuildSkin; edit the script, not this file.')
    $ini.Add('')
    $ini.Add('[Variables]')
    $ini.Add("Script=$PSCommandPath")
    $ini.Add('Text=241,243,247,255')
    $ini.Add('Sub=139,147,163,255')
    $ini.Add('Src=')
    $ini.Add('@Include=#@#state.inc')
    $ini.Add('')
    $ini.Add('[MeasureRun]')
    $ini.Add('Measure=Plugin')
    $ini.Add('Plugin=RunCommand')
    $ini.Add('Program=powershell.exe')
    $ini.Add('State=Hide')
    $ini.Add('FinishAction=[!Refresh]')
    $ini.Add('')
    $ini.Add('[MeasureBattery]')
    $ini.Add('Measure=Plugin')
    $ini.Add('Plugin=PowerPlugin')
    $ini.Add('PowerState=Percent')
    $ini.Add('')
    $ini.Add('[MeasureAC]')
    $ini.Add('Measure=Plugin')
    $ini.Add('Plugin=PowerPlugin')
    $ini.Add('PowerState=ACLine')
    $ini.Add('IfCondition=MeasureAC=1')
    $ini.Add('IfTrueAction=[!SetVariable Src "plugged in"]')
    $ini.Add('IfFalseAction=[!SetVariable Src "on battery"]')
    $ini.Add('')
    # Re-sync every 5 minutes in case something else changed a setting.
    $ini.Add('[MeasureSyncTimer]')
    $ini.Add('Measure=Calc')
    $ini.Add('Formula=MeasureSyncTimer+1')
    $ini.Add('IfCondition=MeasureSyncTimer=300')
    $ini.Add('IfTrueAction=' + ($run -f '-Export'))
    $ini.Add('')

    $body = New-Object System.Collections.Generic.List[string]
    $body.Add('[MeterTitle]'); $body.Add('Meter=String'); $body.AddRange([string[]]$font)
    $body.Add('Text=WinDash'); $body.Add('FontSize=13'); $body.Add('StringStyle=Bold'); $body.Add('FontColor=#Text#'); $body.Add('X=16'); $body.Add('Y=12'); $body.Add('')
    $body.Add('[MeterStatus]'); $body.Add('Meter=String'); $body.AddRange([string[]]$font)
    $body.Add('MeasureName=MeasureBattery'); $body.Add("Text=#Plan#  $([char]0x00B7)  %1%  #Src#"); $body.Add('DynamicVariables=1')
    $body.Add('FontSize=9'); $body.Add('FontColor=#Sub#'); $body.Add('X=16'); $body.Add('Y=38'); $body.Add('')

    $y = 66
    $n = 0
    # Look & feel stays in the full window only; the widget shows system usage instead.
    foreach ($group in ($Toggles | Where-Object Category -ne 'Look & feel' | Group-Object Category)) {
        $n++
        $body.Add("[Hdr$n]"); $body.Add('Meter=String'); $body.AddRange([string[]]$font)
        $body.Add("Text=$($group.Name)"); $body.Add('StringCase=Upper'); $body.Add('StringStyle=Bold'); $body.Add('FontSize=8')
        $body.Add('FontColor=#Sub#'); $body.Add('X=16'); $body.Add("Y=$y"); $body.Add('')
        $y += 22
        foreach ($t in $group.Group) {
            # Flip the switch on screen immediately (lighter blue = pending), then run the real change.
            $action = "[!SetVariable K_$($t.Id) (36-#K_$($t.Id)#)][!SetVariable C_$($t.Id) `"96,165,250,160`"][!UpdateMeter Sw_$($t.Id)]" + ($run -f "-Flip $($t.Id)")
            $tip = $t.Desc -replace '"', "'"
            $body.Add("[Name_$($t.Id)]"); $body.Add('Meter=String'); $body.AddRange([string[]]$font)
            $body.Add("Text=$($t.Name)"); $body.Add('FontSize=10'); $body.Add('FontColor=#Text#')
            $body.Add('X=16'); $body.Add("Y=$y"); $body.Add('W=220'); $body.Add('H=20'); $body.Add('ClipString=1')
            $body.Add("ToolTipText=$tip"); $body.Add("LeftMouseUpAction=$action"); $body.Add('')
            $body.Add("[Sw_$($t.Id)]"); $body.Add('Meter=Shape')
            $body.Add("Shape=Rectangle 0,0,36,20,10 | Fill Color #C_$($t.Id)# | StrokeWidth 0")
            $body.Add("Shape2=Ellipse #K_$($t.Id)#,10,7 | Fill Color 241,243,247,255 | StrokeWidth 0")
            $body.Add('DynamicVariables=1'); $body.Add("X=$($W - 52)"); $body.Add("Y=$($y)"); $body.Add("ToolTipText=$tip"); $body.Add("LeftMouseUpAction=$action"); $body.Add('')
            $y += 28
        }
        $y += 6
    }

    # ---- System usage: label + value on one line, thin bar underneath
    $ini.AddRange([string[]]@(
        '[MeasureCPU]', 'Measure=CPU', '',
        '[MeasureGPURaw]', 'Measure=Plugin', 'Plugin=UsageMonitor', 'Category=GPU Engine', 'Counter=Utilization Percentage', 'Name=*engtype_3D', '',
        # UsageMonitor's string value is the instance name, so wrap it in a Calc to get a clamped number.
        '[MeasureGPU]', 'Measure=Calc', 'Formula=Clamp(MeasureGPURaw, 0, 100)', 'MinValue=0', 'MaxValue=100', '',
        '[MeasureRAM]', 'Measure=PhysicalMemory', '',
        '[MeasureRAMTotal]', 'Measure=PhysicalMemory', 'Total=1', '',
        '[MeasureDiskFree]', 'Measure=FreeDiskSpace', 'Drive=C:', '',
        '[MeasureDiskUsed]', 'Measure=FreeDiskSpace', 'Drive=C:', 'InvertMeasure=1', '',
        '[MeasureNetIn]', 'Measure=NetIn', '',
        '[MeasureNetOut]', 'Measure=NetOut', ''
    ))
    $down = [char]0x2193; $up = [char]0x2191
    $stats = @(
        @{ Id = 'CPU';  Label = 'CPU';  Bar = 'MeasureCPU';      Text = '%1%';            Measures = @('MeasureCPU');                       Scale = $false }
        @{ Id = 'GPU';  Label = 'GPU';  Bar = 'MeasureGPU';      Text = '%1%';            Measures = @('MeasureGPU');                       Scale = $false }
        @{ Id = 'RAM';  Label = 'RAM';  Bar = 'MeasureRAM';      Text = '%1B / %2B';      Measures = @('MeasureRAM', 'MeasureRAMTotal');   Scale = $true }
        @{ Id = 'Disk'; Label = 'Disk C:'; Bar = 'MeasureDiskUsed'; Text = '%1B free';    Measures = @('MeasureDiskFree');                  Scale = $true }
        @{ Id = 'Net';  Label = 'Network'; Bar = $null;          Text = "$down %1B/s   $up %2B/s"; Measures = @('MeasureNetIn', 'MeasureNetOut'); Scale = $true }
    )
    $n++
    $body.Add("[Hdr$n]"); $body.Add('Meter=String'); $body.AddRange([string[]]$font)
    $body.Add('Text=System usage'); $body.Add('StringCase=Upper'); $body.Add('StringStyle=Bold'); $body.Add('FontSize=8')
    $body.Add('FontColor=#Sub#'); $body.Add('X=16'); $body.Add("Y=$y"); $body.Add('')
    $y += 22
    foreach ($s in $stats) {
        $body.Add("[Lbl_$($s.Id)]"); $body.Add('Meter=String'); $body.AddRange([string[]]$font)
        $body.Add("Text=$($s.Label)"); $body.Add('FontSize=10'); $body.Add('FontColor=#Text#'); $body.Add('X=16'); $body.Add("Y=$y"); $body.Add('')
        $body.Add("[Val_$($s.Id)]"); $body.Add('Meter=String'); $body.AddRange([string[]]$font)
        $body.Add("MeasureName=$($s.Measures[0])")
        if ($s.Measures.Count -gt 1) { $body.Add("MeasureName2=$($s.Measures[1])") }
        $body.Add("Text=$($s.Text)"); $body.Add('NumOfDecimals=' + $(if ($s.Scale) { '1' } else { '0' }))
        if ($s.Scale) { $body.Add('AutoScale=1') }
        $body.Add('FontSize=10'); $body.Add('FontColor=#Sub#'); $body.Add('StringAlign=Right'); $body.Add("X=$($W - 16)"); $body.Add("Y=$y"); $body.Add('')
        if ($s.Bar) {
            $body.Add("[Bar_$($s.Id)]"); $body.Add('Meter=Bar'); $body.Add("MeasureName=$($s.Bar)"); $body.Add('BarOrientation=Horizontal')
            $body.Add('BarColor=59,130,246,255'); $body.Add('SolidColor=58,63,75,255'); $body.Add('X=16'); $body.Add("Y=$($y + 22)"); $body.Add("W=$($W - 32)"); $body.Add('H=4'); $body.Add('')
            $y += 34
        } else {
            $y += 26
        }
    }
    $y += 6

    $body.Add('[MeterMsg]'); $body.Add('Meter=String'); $body.AddRange([string[]]$font)
    $body.Add('Text=#Msg#'); $body.Add('FontSize=8'); $body.Add('FontColor=#Sub#')
    $body.Add('X=16'); $body.Add("Y=$y"); $body.Add("W=$($W - 32)"); $body.Add('ClipString=1'); $body.Add('')
    $y += 22
    $body.Add('[MeterTaskmgr]'); $body.Add('Meter=String'); $body.AddRange([string[]]$font)
    $body.Add('Text=Open Task Manager'); $body.Add('FontSize=9'); $body.Add('FontColor=59,130,246,255'); $body.Add('StringStyle=Bold')
    $body.Add('X=16'); $body.Add("Y=$y"); $body.Add('LeftMouseUpAction=["taskmgr.exe"]')
    $body.Add('MouseOverAction=[!SetOption MeterTaskmgr FontColor 96,165,250,255][!UpdateMeter MeterTaskmgr][!Redraw]')
    $body.Add('MouseLeaveAction=[!SetOption MeterTaskmgr FontColor 59,130,246,255][!UpdateMeter MeterTaskmgr][!Redraw]'); $body.Add('')
    $body.Add('[MeterWinUtil]'); $body.Add('Meter=String'); $body.AddRange([string[]]$font)
    $body.Add('Text=Chris Titus WinUtil'); $body.Add('FontSize=9'); $body.Add('FontColor=59,130,246,255'); $body.Add('StringStyle=Bold')
    $body.Add('StringAlign=Right'); $body.Add("X=$($W - 16)"); $body.Add("Y=$y"); $body.Add('ToolTipText=Downloads and runs the latest WinUtil (irm christitus.com/win | iex) as admin.')
    $body.Add('LeftMouseUpAction=' + ($run -f '-WinUtil'))
    $body.Add('MouseOverAction=[!SetOption MeterWinUtil FontColor 96,165,250,255][!UpdateMeter MeterWinUtil][!Redraw]')
    $body.Add('MouseLeaveAction=[!SetOption MeterWinUtil FontColor 59,130,246,255][!UpdateMeter MeterWinUtil][!Redraw]'); $body.Add('')
    $H = $y + 30

    # Background first so it draws underneath everything else.
    $ini.Add('[MeterBg]'); $ini.Add('Meter=Shape')
    $ini.Add("Shape=Rectangle 0,0,$W,$H,12 | Fill Color 21,23,28,230 | StrokeWidth 1 | Stroke Color 52,58,70,255")
    $ini.Add('')
    $ini.AddRange($body)

    Set-Content -Path (Join-Path $dir 'WinDash.ini') -Value $ini -Encoding Unicode
}

if ($Status) {
    foreach ($t in $Toggles) {
        $state = if (Get-ToggleState $t) { 'ON' } else { 'off' }
        "{0,-22} {1,-8} {2,-38} {3}" -f $t.Category, $t.Id, $t.Name, $state
    }
    return
}

if ($BuildSkin) { Build-Skin; Export-WidgetState 'Ready. Hover a switch for details.'; return }
if ($Export) { Export-WidgetState 'Synced.'; return }
if ($Launch) {
    Export-WidgetState 'Synced at startup.'
    if (Get-Process Rainmeter -ErrorAction SilentlyContinue) { Update-Widget } elseif (Test-Path $RainmeterExe) { Start-Process $RainmeterExe }
    return
}
if ($RestartExplorer) { Invoke-ExplorerRestart; Export-WidgetState 'Explorer restarted.'; return }
if ($WinUtil) { Start-WinUtil; Export-WidgetState 'Opened Chris Titus WinUtil.' $Toggles[0]; return }

if ($Flip) {
    $t = $Toggles | Where-Object Id -eq $Flip
    if (-not $t) { Export-WidgetState "Unknown toggle: $Flip"; return }
    $want = -not (Get-ToggleState $t)
    $word = if ($want) { 'on' } else { 'off' }
    try {
        if ($want) { & $t.On } else { & $t.Off }
        Write-Log "$($t.Name) -> $word (widget)"
        $msg = "$($t.Name) turned $word."
        if ($t.Explorer) { $msg += ' Right-click > Restart Explorer.' }
    } catch {
        Write-Log "$($t.Name) FAILED: $($_.Exception.Message)"
        $msg = "$($t.Name) failed - see log."
    }
    # Power toggles affect each other (auto mode switches the plan), so re-check the whole group.
    $affected = if ($t.Category -eq 'Power') { $Toggles | Where-Object Category -eq 'Power' } else { @($t) }
    Export-WidgetState $msg $affected
    return
}

# ---------------- window ----------------

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WinDash" Width="640" Height="800" MinWidth="480" MinHeight="400"
        WindowStartupLocation="CenterScreen" Background="#15171C" FontFamily="Segoe UI">
  <Window.Resources>
    <Style x:Key="Switch" TargetType="CheckBox">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="VerticalAlignment" Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Grid Width="44" Height="24" Background="Transparent">
              <Border x:Name="Track" CornerRadius="12" Background="#3A3F4B"/>
              <Ellipse x:Name="Knob" Width="18" Height="18" Fill="#F1F3F7" HorizontalAlignment="Left" Margin="3,0,0,0"/>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Track" Property="Background" Value="#3B82F6"/>
                <Setter TargetName="Knob" Property="HorizontalAlignment" Value="Right"/>
                <Setter TargetName="Knob" Property="Margin" Value="0,0,3,0"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Opacity" Value="0.4"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="Button">
      <Setter Property="Foreground" Value="#F1F3F7"/>
      <Setter Property="Background" Value="#262A33"/>
      <Setter Property="BorderBrush" Value="#343A46"/>
      <Setter Property="Padding" Value="12,6"/>
      <Setter Property="Margin" Value="0,0,8,0"/>
      <Setter Property="Cursor" Value="Hand"/>
    </Style>
  </Window.Resources>
  <Grid Margin="20">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <StackPanel Grid.Row="0">
      <TextBlock Text="WinDash" FontSize="26" FontWeight="Bold" Foreground="#F1F3F7"/>
      <TextBlock Text="ReviOS tweaks: power, privacy, background and look." Foreground="#8B93A3" Margin="0,2,0,0"/>
    </StackPanel>
    <Border Grid.Row="1" Background="#1E2128" CornerRadius="8" Padding="12,8" Margin="0,14,0,0">
      <TextBlock x:Name="StatusLine" Foreground="#C9CFDA"/>
    </Border>
    <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,12,0,12">
      <Button x:Name="RefreshBtn" Content="Refresh"/>
      <Button x:Name="ExplorerBtn" Content="Restart Explorer"/>
      <Button x:Name="LogBtn" Content="Open log"/>
      <Button x:Name="WinUtilBtn" Content="Chris Titus WinUtil"/>
    </StackPanel>
    <ScrollViewer Grid.Row="3" VerticalScrollBarVisibility="Auto">
      <StackPanel x:Name="Rows"/>
    </ScrollViewer>
    <TextBlock Grid.Row="4" x:Name="Message" Foreground="#8B93A3" TextWrapping="Wrap" Margin="0,12,0,0"/>
  </Grid>
</Window>
'@

$window     = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$rowsPanel  = $window.FindName('Rows')
$statusLine = $window.FindName('StatusLine')
$message    = $window.FindName('Message')
$brush      = New-Object System.Windows.Media.BrushConverter
$switches   = New-Object System.Collections.ArrayList

function Set-Message($text, [bool]$IsError) {
    $message.Text = $text
    $message.Foreground = if ($IsError) { $brush.ConvertFromString('#F87171') } else { $brush.ConvertFromString('#8B93A3') }
}

function Update-Status {
    $plan = if ((powercfg /getactivescheme) -match '\((.+)\)') { $Matches[1] } else { 'unknown' }
    $ps   = [System.Windows.Forms.SystemInformation]::PowerStatus
    $src  = if ($ps.PowerLineStatus -eq 'Online') { 'plugged in' } else { 'on battery' }
    $pct  = [math]::Round($ps.BatteryLifePercent * 100)
    $statusLine.Text = "Power plan: $plan    |    Battery: $pct% ($src)"
}

function Update-Switches { foreach ($cb in $switches) { $cb.IsChecked = Get-ToggleState $cb.Tag } }

foreach ($group in ($Toggles | Group-Object Category)) {
    $header = New-Object System.Windows.Controls.TextBlock
    $header.Text = $group.Name.ToUpper()
    $header.Foreground = $brush.ConvertFromString('#8B93A3')
    $header.FontSize = 11
    $header.FontWeight = [System.Windows.FontWeights]::SemiBold
    $header.Margin = New-Object System.Windows.Thickness 2, 10, 0, 6
    [void]$rowsPanel.Children.Add($header)

    $card = New-Object System.Windows.Controls.Border
    $card.Background = $brush.ConvertFromString('#1E2128')
    $card.CornerRadius = New-Object System.Windows.CornerRadius 10
    $card.Padding = New-Object System.Windows.Thickness 14, 10, 14, 10
    $list = New-Object System.Windows.Controls.StackPanel
    $card.Child = $list
    [void]$rowsPanel.Children.Add($card)

    foreach ($t in $group.Group) {
        $row = New-Object System.Windows.Controls.Grid
        $row.Margin = New-Object System.Windows.Thickness 0, 6, 0, 6
        $c1 = New-Object System.Windows.Controls.ColumnDefinition
        $c1.Width = New-Object System.Windows.GridLength 1, ([System.Windows.GridUnitType]::Star)
        $c2 = New-Object System.Windows.Controls.ColumnDefinition
        $c2.Width = [System.Windows.GridLength]::Auto
        $row.ColumnDefinitions.Add($c1)
        $row.ColumnDefinitions.Add($c2)

        $text = New-Object System.Windows.Controls.StackPanel
        $text.Margin = New-Object System.Windows.Thickness 0, 0, 16, 0
        $name = New-Object System.Windows.Controls.TextBlock
        $name.Text = $t.Name
        $name.FontSize = 14
        $name.FontWeight = [System.Windows.FontWeights]::SemiBold
        $name.Foreground = $brush.ConvertFromString('#F1F3F7')
        $desc = New-Object System.Windows.Controls.TextBlock
        $desc.Text = $t.Desc
        $desc.TextWrapping = 'Wrap'
        $desc.Foreground = $brush.ConvertFromString('#8B93A3')
        $desc.Margin = New-Object System.Windows.Thickness 0, 2, 0, 0
        [void]$text.Children.Add($name)
        [void]$text.Children.Add($desc)

        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Style = $window.FindResource('Switch')
        $cb.Tag = $t
        [System.Windows.Controls.Grid]::SetColumn($cb, 1)
        # Click fires only for user clicks, not when IsChecked is set from code.
        $cb.Add_Click({
            $t = $this.Tag
            $want = [bool]$this.IsChecked
            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            try {
                if ($want) { & $t.On } else { & $t.Off }
                $word = if ($want) { 'on' } else { 'off' }
                Write-Log "$($t.Name) -> $word"
                $msg = "$($t.Name) turned $word."
                if ($t.Explorer) { $msg += ' Click Restart Explorer to see it.' }
                Set-Message $msg $false
            } catch {
                Write-Log "$($t.Name) FAILED: $($_.Exception.Message)"
                Set-Message "$($t.Name) failed: $($_.Exception.Message)" $true
            }
            Update-Switches
            Update-Status
            Export-WidgetState $message.Text
            Update-Widget
            $window.Cursor = $null
        })
        [void]$switches.Add($cb)

        [void]$row.Children.Add($text)
        [void]$row.Children.Add($cb)
        [void]$list.Children.Add($row)
    }
}

$window.FindName('RefreshBtn').Add_Click({ Update-Switches; Update-Status; Set-Message 'Refreshed.' $false; Export-WidgetState 'Synced.'; Update-Widget })
$window.FindName('ExplorerBtn').Add_Click({
    Invoke-ExplorerRestart
    Set-Message 'Explorer restarted.' $false
})
$window.FindName('WinUtilBtn').Add_Click({ Start-WinUtil; Set-Message 'Opened Chris Titus WinUtil.' $false })
$window.FindName('LogBtn').Add_Click({
    if (-not (Test-Path $LogFile)) { New-Item -ItemType File -Path $LogFile | Out-Null }
    Start-Process notepad.exe $LogFile
})

Update-Switches
Update-Status
[void]$window.ShowDialog()
