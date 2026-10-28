# WinDash

Rip Windows apart and put it back together the way you want — with an AI doing the heavy lifting.

This repo is three things:

1. **WinDash** — a toggle dashboard for Windows 11 tweaks (power, privacy, background services, look & feel) with an always-on desktop widget built on [Rainmeter](https://www.rainmeter.net/), showing live CPU/GPU/RAM/disk/network too.
2. **A terminal makeover** — PowerShell 7, an [Oh My Posh](https://ohmyposh.dev/) powerlevel10k-style prompt, Nerd Font icons and gray command suggestions.
3. **A [`CLAUDE.md`](CLAUDE.md) playbook** so [Claude Code](https://claude.com/claude-code) can walk you through the whole thing: installing [ReviOS](https://revi.cc/), auditing what Windows is really doing, cleaning out leftovers, setting up the dashboard and terminal, and backing your stuff up to GitHub — asking before it changes anything and keeping it reversible.

It was built on a ReviOS install, but everything works on regular Windows 11 too.

## Quick start (with Claude Code)

Claude Desktop is great for chatting, but **Claude Code** runs in your terminal and can actually run commands on your PC — check settings, read logs, install things, fix stuff — while you watch and approve. That's what makes this fun.

Open **Windows Terminal** (Start → type *Terminal*) and run these one at a time:

**1. Install Claude Code**

```powershell
irm https://claude.ai/install.ps1 | iex
```

**2. Put `claude` on your PATH** (so the `claude` command works in any terminal)

```powershell
$bin = "$env:USERPROFILE\.local\bin"; $p = [Environment]::GetEnvironmentVariable('Path','User'); if (($p -split ';') -notcontains $bin) { [Environment]::SetEnvironmentVariable('Path', "$p;$bin", 'User') }
```

Then **close and reopen** the terminal, and check it with `claude --version`.

**3. Get this repo**

```powershell
winget install Git.Git
```

Reopen the terminal again, then:

```powershell
git clone https://github.com/flyboy-byte/WinDash
cd WinDash
```

(No Git? Click **Code → Download ZIP** on GitHub, extract it, and `cd` into the folder.)

**4. Start Claude in the repo**

```powershell
claude
```

Sign in when asked, then just tell it what you want, for example:

- *"Help me install ReviOS on this PC."*
- *"Audit my PC — what's running, what's tracking me, what's eating my battery?"*
- *"Find leftover junk and space hogs."*
- *"Set up the WinDash widget."*
- *"Give my terminal a powerlevel10k makeover."*
- *"Back up my game saves to a private GitHub repo."*

Claude reads `CLAUDE.md` automatically and follows its playbook. Later, `claude --continue` picks up your last session and `claude --resume` lets you pick an older one.

## Doing it by hand

```powershell
# Desktop widget: installs Rainmeter, builds the widget, starts it at login
powershell -NoProfile -ExecutionPolicy Bypass -File setup\install-widget.ps1

# Terminal makeover: PowerShell 7, Oh My Posh, Meslo Nerd Font, Terminal-Icons, suggestions
powershell -NoProfile -ExecutionPolicy Bypass -File setup\install-terminal.ps1

# Full WinDash window
powershell -NoProfile -ExecutionPolicy Bypass -STA -File WinDash.ps1
```

## WinDash switches

| Section | Switches |
|---|---|
| **Power** | Auto power plan (max performance plugged in, Balanced on battery — switches on plug/unplug via a scheduled task), max performance plan (ReviOS Ultra Performance, or High performance on regular Windows) |
| **Privacy** | Location services, Delivery Optimization peer-to-peer, Copilot, suggested/promoted apps, leftover data-collection tasks, Maps / sync / link-tracking services |
| **Background & battery** | Search indexing, SysMain, print spooler, Edge/WebView2 updater, Store apps in background |
| **Look & feel** (full window only) | Classic right-click menu, file extensions, hidden files, centered taskbar, dark mode, transparency |

The widget also shows live system usage and has links to Task Manager and [Chris Titus Tech's WinUtil](https://github.com/ChrisTitusTech/winutil). Right-click it for the full window, a manual sync, or an Explorer restart. Hover a switch to see what it does.

Every switch reads the real current setting, so it never drifts from what Windows is actually doing, and every change is logged to `windash.log`.

### Command line

| Flag | Does |
|---|---|
| `-Status` | Print every switch, its id and current state |
| `-Flip <id>` | Flip one switch |
| `-Export` | Re-read all states into the widget |
| `-BuildSkin` | (Re)generate the Rainmeter widget from the toggle list |
| `-RestartExplorer` | Restart Explorer so Look & feel changes show |
| `-WinUtil` | Open Chris Titus Tech's WinUtil in an admin window |
| `-Launch` | Sync the widget, then start Rainmeter (used at login) |

### Adding a switch

Add an entry to `$Toggles` in `WinDash.ps1` with `Get` / `On` / `Off` script blocks, give it a short id in `$ToggleIds`, then run `-BuildSkin`. The widget is generated from the same list, so the two always match.

## Requirements

- Windows 11 with Windows PowerShell 5.1 (built in) and admin rights — WinDash relaunches itself elevated
- [Rainmeter](https://www.rainmeter.net/) 4.5+ for the widget (the setup script installs it)
- [Windows Terminal](https://aka.ms/terminal) for the terminal makeover (built into Windows 11)

## Heads up

These scripts change real system settings. Most switches are policies or service start types you can flip back any time, but read the descriptions first, and keep backups of anything you'd hate to lose. Turning off Defender, the firewall or UAC (which ReviOS and other tweak tools offer) makes a PC easier to compromise — that's your call to make, knowingly.
