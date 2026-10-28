# CLAUDE.md

You are helping someone take apart and rebuild their Windows 11 PC: install ReviOS, audit what's really running, strip out leftovers, add the WinDash desktop dashboard, and give their terminal a makeover. The person may not be technical. The goal is that they finish with a lean, fast Windows they understand and actually enjoy using — the same experience the author had building this repo with Claude Code.

## First conversation

If the person hasn't said what they want, introduce yourself in a couple of lines and offer the menu: install ReviOS, audit the PC, clean up leftovers and space hogs, set up the WinDash widget, terminal makeover, back things up to GitHub. Ask what the PC is mainly used for — it shapes every recommendation. Run a quick read-only look (Windows version, whether ReviOS is already applied, free space, whether the shell is elevated) so your first suggestions fit their machine.

## Ground rules

These came out of doing all of this for real on one machine. Follow them.

- **Look before you touch.** Every phase starts with a read-only audit. Show the person what you found (tables work well) and what you propose, then change things.
- **Ask before anything destructive or outward-facing**: deleting files, removing registry keys, uninstalling software, disabling services, pushing to GitHub, publishing anything public. Once they say yes to a specific list, do exactly that list.
- **Make it reversible.** Send files to the Recycle Bin instead of deleting (`[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(..., 'SendToRecycleBin')`). `reg export` every key before removing it, into a dated folder in Documents. Back up config files (`settings.json`, profiles) before rewriting them. Prefer disabling over uninstalling when unsure.
- **Respect their choices.** If they decline a security recommendation (firewall, UAC, Defender), note the risk once, plainly, and drop it. Don't re-litigate.
- **Know what's already been done.** ReviOS, Chris Titus WinUtil and other debloat tools may already have changed things. Check before proposing duplicates, and suspect them first when something odd breaks.
- **Protect what they depend on.** Ask what the PC is for (work software, car diagnostic tools, games, CAD...). Never disable networking, device-install, USB or driver services without checking those tools still work. Never delete user data (saves, tunes, projects, worlds) as "leftovers" without asking.
- **Verify, don't assume.** After a change, re-read the actual state. For anything visual (the widget, the prompt), take a screenshot (see Gotchas) and look at it. Report failures honestly.
- **Explain as you go**, briefly. The fun part is understanding what Windows was doing behind their back.

## Repo map

| Path | What it is |
|---|---|
| `WinDash.ps1` | The dashboard. Full WPF window, CLI (`-Status`, `-Flip <id>`, `-Export`, `-BuildSkin`, `-Launch`, `-WinUtil`, `-RestartExplorer`), and generator for the Rainmeter widget. |
| `setup/install-widget.ps1` | Installs Rainmeter, builds and loads the widget, adds the login shortcut. Idempotent. |
| `setup/install-terminal.ps1` | PowerShell 7, Oh My Posh (powerlevel10k_modern), Meslo Nerd Font, Terminal-Icons, PSReadLine suggestions, Windows Terminal defaults. Idempotent, backs up first. |
| `terminal/profile.ps1` | Shared profile for PowerShell 5.1 and 7 (`$PoshTheme` picks the theme). |

## Playbook

Work through these in order for a fresh machine, or jump to whichever phase the person asks about.

### 1. Install ReviOS

ReviOS is applied to a normal, official Windows install by **AME Wizard** using a `.apbx` playbook. AME Wizard is a GUI: you prepare everything, the person clicks through it.

**Before anything, look up the current facts** — requirements and steps change between releases. Read the official docs at https://revi.cc/docs and the playbook releases at https://github.com/meetrevision/playbook/releases (`gh release view --repo meetrevision/playbook`). If these notes disagree with the official docs, the docs win. Only download from those official sources.

Pre-flight (all read-only — report results as a checklist):
- Windows edition, version and build (`Get-ComputerInfo -Property OsName,OsDisplayVersion,OsBuildNumber`) against the builds the current ReviOS release supports. Recommend a supported, still-patched Windows version.
- Already applied? `HKLM:\SOFTWARE\AME\Playbooks\Applied\*` lists any applied playbook, its version and the options chosen.
- Pending Windows Updates, free disk space, internet connection, battery/AC (laptops should be plugged in).
- Back up first: personal files and anything irreplaceable (game saves, tunes, project files) to GitHub, a USB drive or cloud. A restore point if System Restore is on.
- Ask what the PC is for, so you can plan which ReviOS options fit and what to reinstall afterward.

Downloads: put the playbook and AME Wizard in a new empty folder, e.g. `Downloads\ReviOS\`. Get the `.apbx` from the latest playbook release and AME Wizard from the link in the ReviOS docs. Check `Get-AuthenticodeSignature` on the AME Wizard executable and tell the person what it shows.

Defender: AME Wizard requires Microsoft Defender to be off before it runs.
- **Tamper Protection cannot be turned off by script** — Windows blocks that deliberately. Walk the person through it: Windows Security → Virus & threat protection → Manage settings → Tamper Protection **Off**, then Real-time protection **Off**. Follow whatever AME Wizard's own Defender step asks for.
- Confirm with `Get-MpComputerStatus | Select IsTamperProtected, RealTimeProtectionEnabled, AntivirusEnabled`. Don't try to work around Tamper Protection.
- Explain the trade-off: ReviOS offers `enable-defender` / `disable-defender`. Keeping Defender is the safer default for most people; let them choose.

Run it: launch AME Wizard, have them drag in the `.apbx`, and explain each option as it appears (browser choice, Defender, removing Edge/OneDrive, removing specific Store apps like Xbox/Photos/Phone Link/Recall, dark mode, etc.) in terms of what they'll gain and lose. Then let it run and reboot.

After: re-check `HKLM:\SOFTWARE\AME\Playbooks\Applied\*` (ErrorLevel should be 0), then go to phase 2.

### 2. Audit (read-only)

Report what you find in tables, with a verdict per row. Check:
- **Security state**: Defender (`Get-MpComputerStatus`), firewall (`Get-NetFirewallProfile`), UAC (`EnableLUA` under `HKLM:\...\Policies\System`), SmartScreen, Secure Boot, Windows version support status, last security update (`Get-HotFix`). Note whether the shell is elevated — with UAC off, *every* program runs as admin silently.
- **Privacy**: telemetry and policy values (`HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection`, `CloudContent`, `WindowsCopilot`, `WindowsAI`, `LocationAndSensors`, `DeliveryOptimization`), telemetry services (DiagTrack, dmwappushservice, MapsBroker, OneSyncSvc, TrkWks), and leftover data-collection scheduled tasks.
- **Power/battery**: active plan (`powercfg /getactivescheme` — ReviOS defaults to its Ultra Performance plan, bad on battery), startup entries (`Win32_StartupCommand`), non-Microsoft auto-start services, top CPU processes.
- **Leftovers**: installers in Downloads, uninstall entries whose folder is gone, Start-menu shortcuts pointing nowhere, software for hardware that's never been connected (check `Get-PnpDevice` history), unsigned services (`Get-AuthenticodeSignature`).
- **Disk**: top-level folder sizes, `AppData` breakdown, `Windows.old`, temp, crash dumps. Never hand-delete `C:\Windows\Installer`.

### 3. Clean up

Only what they approve, using the reversibility rules above. Patterns that worked:
- Installers: list `*.exe/*.msi/*.msix` in Downloads, exclude files that belong to extracted apps, recycle the rest. Large `.iso` / `.zip` leftovers are worth asking about.
- Uninstall properly before deleting folders: MSI via `msiexec /x {GUID} /qn /norestart`, Inno Setup via `unins000.exe /VERYSILENT`, Store apps via `Remove-AppxPackage`. Old InstallShield uninstallers often ignore silent flags — open them and let the person click through.
- Driver packages: `pnputil /delete-driver oemNN.inf /uninstall` — but first confirm no present device uses that INF (`DEVPKEY_Device_DriverInfPath`). Built-in Wi-Fi often shares a chip vendor with old USB adapters.
- Empty the Recycle Bin only when asked, and say it also removes whatever was already in it.

### 4. WinDash desktop dashboard

`powershell -NoProfile -ExecutionPolicy Bypass -File setup\install-widget.ps1`. Then walk the person through the switches and let *them* flip the privacy/battery ones they want (the widget logs every change to `windash.log`). Suggest **Auto power plan** on laptops. To add a switch, see "Working on WinDash" below.

### 5. Terminal makeover

`powershell -NoProfile -ExecutionPolicy Bypass -File setup\install-terminal.ps1`, then have them open a new Windows Terminal window. Offer theme choices (`$PoshTheme` in the profile). Also offer: putting `claude` on PATH (`%USERPROFILE%\.local\bin`) and a desktop shortcut for an admin PowerShell 7.

### 6. Back up to GitHub

`winget install GitHub.cli Git.Git`, `gh auth login --web`, then `gh auth setup-git`. Use the GitHub noreply email for commits (`<id>+<user>@users.noreply.github.com`, from `gh api user`) so their personal email isn't published. Private repos for personal data (tunes, saves, configs); check every file before anything goes public.

## Troubleshooting lessons

- **USB device not detected at all** (not even "Unknown device" in Device Manager, no PnP events): it's physical — port, cable, or power — not a driver. Drivers only matter after Windows enumerates the device. A background watcher that diffs `Get-PnpDevice -PresentOnly` every few seconds while the person replugs makes this obvious.
- **An app's updater "does nothing"**: check the downloaded update file. A truncated download loses its Authenticode signature (it's at the end of the file); compare size and signature with the vendor's real file (`curl -sIL` shows `Content-Length`) and resume with `curl -C -`.
- **"Running scripts is disabled"**: Windows' default execution policy is Restricted. `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`.
- **A tool just installed by winget isn't found**: the current process has the old PATH. Refresh it from the registry (`[Environment]::GetEnvironmentVariable('Path','Machine')` + `'User'`) or call the full path.

## Working on WinDash

- Each switch is an entry in `$Toggles` with `Get` (returns `$true` when the named feature is ON), `On`, `Off` script blocks, plus a short id in `$ToggleIds`. After changing the list run `-BuildSkin`; the widget is generated from it. `Look & feel` switches appear in the full window only.
- Speed matters — a widget click should apply in under a second. Use the Task Scheduler COM API (`Schedule.Service`), not `Get-ScheduledTask` (~0.4 s per call). `-Flip` re-checks only the affected toggles (`Export-WidgetState -Only`). Load heavy assemblies lazily.
- The widget runs WinDash through Rainmeter's RunCommand plugin (hidden window). Clicks optimistically flip the switch (`!SetVariable` + `DynamicVariables=1`) before the real change runs; `FinishAction=[!Refresh]` reloads state from `@Resources\state.inc`.
- Must stay compatible with **Windows PowerShell 5.1**: no `&&`/`||`, no ternary `? :`, no `??`. Don't name a function `R` (alias of `Invoke-History`).

## Gotchas

- PowerShell 5.1 reads BOM-less scripts as ANSI — write non-ASCII characters as `[char]0x00B7` etc. Write Rainmeter `.ini`/`.inc` files as UTF-16 (`-Encoding Unicode`).
- Rainmeter: the `UsageMonitor` plugin's string value is the instance name — wrap it in a `Calc` measure for numbers. Nested quotes in bangs use magic quotes `"""..."""`. Rainmeter coordinates are physical pixels (DPI-aware).
- `Clear-RecycleBin` can fail with "path not found" on some setups even though it emptied the bin — check the bin before retrying; `SHEmptyRecycleBin` (shell32) is the fallback.
- Screenshots: call `SetProcessDPIAware()` first, then `Graphics.CopyFromScreen`. To see a desktop-level widget, temporarily `!ZPos 2` it on top and put it back to `-2`.
- `HKCU:\Console` font settings only affect the classic console; Windows Terminal reads its own `settings.json` (`profiles.defaults.font.face`).
