# scripts-docs-dotfiles

Scripts, tools, Claude Code skills, dotfiles and technical docs: one-off utilities, visualizers, fixes and reference
whitepapers.

| Folder | What goes there |
| --- | --- |
| [`skills/`](skills/) | [Claude Code](https://claude.com/claude-code) skills. Each folder installs with `cp -r skills/<name> ~/.claude/skills/`. |
| [`tools/`](tools/) | Anything bigger than one file: each tool has its own folder and `README.md`. |
| [`scripts/`](scripts/) | Single-file scripts, described below. |
| [`dotfiles/`](dotfiles/) | Full desktop setups, one folder per machine. |

MIT licensed (see `LICENSE`), except where a folder has its own `LICENSE`: `tools/vfs0090-rhel/` is LGPL-2.1-or-later.

## Skills

| Skill | What it does |
| --- | --- |
| [pkgfilter](skills/pkgfilter/) | Finds what is eating your disk and which Arch packages are bloat, explains each big folder and how safe it is to clear, and leaves the deleting to you. Remembers what you said to keep. |
| [oss-contribute](skills/oss-contribute/) | Contribute to other people's GitHub projects with Claude doing the work, the careful way: checks the project's AI policy, avoids duplicate PRs, reproduces before fixing, proves tests fail without the fix, runs what CI runs, keeps your email private, writes honest PRs and handles reviews. For developers new to big, fast-moving upstream projects. |
| [fdroid](skills/fdroid/) | Get an Android app into F-Droid and keep it updated: policy, the recipe, the merge request, reproducible builds signed with your own key (the two-run process), signing keys across stores, ABI splits and R8, auto-updates, reading CI and the real build-server logs, and testing other people's MRs. Deep on Expo / React Native. Written for Claude to use, with a README a human can follow (start with "my byte comparison fails"), a recipe linter, a fastlane checker, an APK inspect/diff/signer and an MR summary. |
| [pcb-design](skills/pcb-design/) | Design, place, autoroute, audit and order a custom PCB with KiCad and JLCPCB assembly. Point it at an idea or an existing board folder and it sets the project up: a state file with stages, a requirements interview that picks risk questions from what the board does, check scripts with a release gate that refuses unready fab files, a pin map shared with the firmware, an audit pack for a second model, and a phone review page. It is also a documented workflow ([`WORKFLOW.md`](skills/pcb-design/WORKFLOW.md)): how the assistant works a board on its own for hours, saves the day at a pause point, and hands off to the next session or another model. Worked example: [wideband-work](https://github.com/flyboy-byte/wideband-work). Based on sidewinderzz's skill from a working board (MIT). |

```bash
git clone https://github.com/flyboy-byte/scripts-docs-dotfiles.git
cp -r scripts-docs-dotfiles/skills/<name> ~/.claude/skills/
```

How a skill folder is laid out, and how to add one: [`skills/README.md`](skills/README.md).

## Tools

| Tool | What it does |
| --- | --- |
| [vfs0090-rhel](tools/vfs0090-rhel/) | Gets the Validity `138a:0090` fingerprint sensor working with `fprintd` on RHEL 10 / CentOS Stream 10, without touching the system `libfprint`. |
| [field-mode](tools/field-mode/) | Battery-saving toggle for LXQt field use: CPU governor, WiFi, brightness and TLP profile in one command. |
| [wallpaper-niri](tools/wallpaper-niri/) | Live fastfetch system-info wallpaper for niri/Wayland, cross-faded with `awww`. |
| [wallpaper-kde](tools/wallpaper-kde/) | The KDE original: neofetch rendered onto a wallpaper, one-shot or as a loop with a systemd service. |
| [whitepaper-formatter](tools/whitepaper-formatter/) | Single-file HTML page that turns raw research text into a structured white paper via the Claude API, without rewriting it. |

<details>
<summary>tools in detail</summary>

### vfs0090-rhel
RHEL/Fedora's `libfprint` is built without the `vfs0090` driver. `install.sh` builds the exact upstream `libfprint`
tag you have installed with the driver grafted in and two fixes applied, checks every symbol `fprintd` needs, installs
it to `/usr/local` and points `fprintd` at it with a systemd drop-in. `uninstall.sh` undoes it. Moved here from its own
repo on 2026-10-21 with its history. See [`tools/vfs0090-rhel/README.md`](tools/vfs0090-rhel/README.md).

```bash
cd tools/vfs0090-rhel && ./install.sh
```

### field-mode
Battery-saving toggle for ham radio logging, outdoor work, anywhere you're off AC. Toggle off to restore everything.

```bash
field-mode               # show help
field-mode on            # enable (WiFi power save)
field-mode on wifi-off   # enable (WiFi interface down, for pure radio use)
field-mode off           # disable, restore everything
field-mode status        # show current state
```

See `tools/field-mode/sudoers.example` for the passwordless sudo rule and `tools/field-mode/README.md` for full setup.

### wallpaper-niri
Every ~15s it runs `fastfetch`, and if the output changed, renders it onto a Catppuccin-style PNG sized to the screen
(read from `niri msg`) and cross-fades it in with `awww`. No hardcoded paths. Requires `awww`, `fastfetch` and Pillow.

```bash
install -Dm755 tools/wallpaper-niri/sysinfo-wallpaper ~/.local/bin/sysinfo-wallpaper
sysinfo-wallpaper --once      # render and apply one frame
cp tools/wallpaper-niri/sysinfo-wallpaper.service ~/.config/systemd/user/
systemctl --user enable --now sysinfo-wallpaper.service
```

See `tools/wallpaper-niri/README.md` for full setup.

### wallpaper-kde
- `neofetch_wallpaper_simple.py`: one-shot, captures `neofetch --stdout` and renders it onto a 1080p PNG, color-coded
  by category, with a timestamp. Requires Pillow and neofetch.
- `neofetch_wallpaper_kde.py`: the same as a loop; every ~15s, if the output changed, it regenerates the wallpaper and
  applies it with `plasma-apply-wallpaperimage`. Its output directory is hardcoded (`/home/logan/Downloads/wallpaper`)
  and cleared on each run: edit it before using on another machine.
- `wallpaper.service`: systemd user service that runs the loop with `Restart=always`. Edit its `ExecStart` path.

```bash
python tools/wallpaper-kde/neofetch_wallpaper_simple.py
cp tools/wallpaper-kde/wallpaper.service ~/.config/systemd/user/
systemctl --user enable --now wallpaper.service
```

### whitepaper-formatter
Adds a title, table of contents and headings without rewriting or reordering your text. Runs entirely client-side.

- **Inside claude.ai**: paste the file in as an artifact and leave the API key field blank; your session handles auth.
- **Standalone**: open the file in a browser and paste your own Anthropic API key (`sk-ant-...`). The key is only
  used for that one request and is never stored or sent anywhere else.

</details>

## Scripts

All in [`scripts/`](scripts/). Python 3; tkinter or matplotlib where noted.

| Script | What it does |
| --- | --- |
| `pwm_signal_gui.py` | PWM oscilloscope-style visualizer (tkinter) with adjustable frequency and duty cycle. |
| `teleprompter.py` | Scrolling teleprompter for video scripts (tkinter). |
| `python_phasor_pm.py` | Phase-modulation phasor visualizer (matplotlib) with live sliders. |
| `mouse-jiggler.py` | Keeps the screen awake on KDE, X11 or Wayland. |
| `fuel_injection_calc.py` | Fuel mass and volume per stroke for 4-stroke engines. |
| `pcapdroid_analyze.py` | Classifies a PCAPdroid CSV export into NORMAL / ELEVATED / CONCERN / UNKNOWN traffic. |
| `chat_compress.py` | Shrinks an AI chat markdown export for re-upload. |
| `strip_passwords.py` | Reduces a Google Passwords CSV export to a list of domains, dropping the credentials. |
| `pkgfilter.py` | The original interactive Arch package bloat hunter (the skill in `skills/pkgfilter/` grew out of it). |

<details>
<summary>scripts in detail</summary>

### pwm_signal_gui.py
Built for an automotive class. Draws a live square wave with adjustable frequency and duty cycle so you can see how
each parameter changes the signal shape in real time.

```bash
python scripts/pwm_signal_gui.py
```

### teleprompter.py
Loads a text file, word-wraps it to the window width, and scrolls it upward through a fixed focal zone so your eyes
never move off-camera.

```bash
python scripts/teleprompter.py script.txt
```
Controls: space to play/pause, ↑/↓ for speed, +/− for font size, R to restart, Q to quit.

### python_phasor_pm.py
Side-by-side rotating phasor and time-domain waveform, with live sliders for carrier frequency, message frequency,
modulation index and playback speed, plus play/pause and reset buttons.

```bash
python scripts/python_phasor_pm.py
```

### mouse-jiggler.py
Keeps the screen awake during long compiles/downloads on KDE. Detects X11 vs Wayland automatically: nudges the cursor
via `xdotool` on X11, or issues a DBus screensaver inhibit (falling back to `ydotool`) on Wayland. Small GUI with a
start/stop toggle and an adjustable interval (5–300s).

```bash
python scripts/mouse-jiggler.py
```

### fuel_injection_calc.py
Prompts for fuel type (diesel or gasoline, each with a default BSFC), cylinder count, power output and engine speed,
then reports mass per stroke, volume per stroke, and total fuel rate in g/min and kg/h.

```bash
python scripts/fuel_injection_calc.py
```

### pcapdroid_analyze.py
Uses built-in host and port tables (CDNs and known services as normal, analytics/ad-tech as elevated, data
brokers/Tor/remote-access ports as concern). Outputs a full, grep-friendly report: per-app flagged breakdown, all
domains, all apps by data volume, port inventory, raw flagged connection log, and unclassified domains.

```bash
python scripts/pcapdroid_analyze.py capture.csv
python scripts/pcapdroid_analyze.py capture.csv --days 3      # adds a connections/day rate
python scripts/pcapdroid_analyze.py capture.csv --out report.txt
python scripts/pcapdroid_analyze.py capture.csv --json > report.json   # for LLM ingestion
```

### chat_compress.py
Strips images, links, horizontal rules and excess blank lines. No API calls; prints the size reduction when done.

```bash
python scripts/chat_compress.py input.md
python scripts/chat_compress.py input.md --output out.md
```

### strip_passwords.py
Turns a Google Passwords CSV export (`name,url,username,password`) into a deduped, sorted list of domains. Useful for
auditing which sites you have saved logins for without handling the credentials themselves.

```bash
python scripts/strip_passwords.py export.csv
python scripts/strip_passwords.py export.csv domains.txt   # write to file instead of stdout
```
Never commit the raw export CSV.

### pkgfilter.py
First run saves every installed package with its size (`pacman -Qq`/`-Qi`) as `revision1.txt`. Each later run strips
packages by keyword (`plasma`, `kde`, `qt`) so what's left is what you don't recognise, optionally drops anything under
a size, and saves the next `revisionN.txt`, so you can diff passes. It can also list the 20 largest directories and
files on the filesystem.

```bash
python3 scripts/pkgfilter.py                    # interactive: keyword loop, size filter, then optional fs scan
python3 scripts/pkgfilter.py -k plasma          # strip a keyword non-interactively
python3 scripts/pkgfilter.py -s 5MiB            # drop anything under 5MiB
python3 scripts/pkgfilter.py -k kde -s 10MiB    # combine keyword + size filter
sudo python3 scripts/pkgfilter.py               # needed for a full filesystem scan outside your home dir
```
Run it from an empty folder: that's where the `revisionN.txt` files accumulate. For a version Claude can drive, use the
[pkgfilter skill](skills/pkgfilter/).

</details>

## Dotfiles

### [t420-niri](dotfiles/t420-niri/)
Arch + niri on a ThinkPad T420 (Catppuccin Mocha): niri, waybar, fuzzel, mako, swayidle/swaylock, Terminology, plus
helper scripts (keybind cheat sheet, caffeine and night-light toggles, clipboard picker, battery dropdown with
charge-limit toggle) and reference copies of the root-level config (zram, earlyoom, SDDM/GRUB themes).

```bash
cd dotfiles/t420-niri
./install.sh    # backs up anything it replaces as *.pre-dotfiles
```

See `dotfiles/t420-niri/README.md` for the sudo steps.

### [claude-code](dotfiles/claude-code/)
The owner's user-level `~/.claude/CLAUDE.md`, the file Claude Code loads in every session. It covers role-separated
project docs, resuming a session without re-deriving (paste-back resume blocks plus a handoff file for long sessions),
attempt logs, evidence tags and scope fences.

## Docs

Technical writing that doesn't belong on the portfolio but is worth keeping somewhere searchable.

| Title | Tags |
|---|---|
| [Vendor-Kernel Preservation in Qualcomm-Based SBCs](https://logannightingale.com/papers/qualcomm-kernel.html) | Embedded · Linux · Qualcomm · SBC |
| [Phasing, Math, and Signals — Ham Extra Learner Manual](https://logannightingale.com/papers/ham-radio-math.pdf) | Ham Radio · RF · Math · Extra Class |
| [Pure Arch on an Older Dell Latitude](https://logannightingale.com/papers/arch-dell-latitude.html) | Linux · Arch · Security · Systems |
| [HP LaserJet P1005 on Arch Linux](https://logannightingale.com/papers/hp-p1005-arch.html) | Linux · Arch · Hardware · CUPS |
| [T1D Field Management and Insulin Pen Survival Guide v2](https://logannightingale.com/papers/t1d-field-guide.pdf) | Medical · Field Guide · T1D · Wilderness |
| [Evaluating Common AI APIs and Models](https://logannightingale.com/papers/ai-apis-report.pdf) | AI · LLMs · APIs · Reference |
