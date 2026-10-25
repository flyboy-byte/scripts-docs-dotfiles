# linux

Fixes and desktop tools for Linux laptops. Each folder has its own README; the two loose scripts are described here.

| | What it does | Runs on |
|---|---|---|
| [**vfs0090-rhel/**](vfs0090-rhel/) | Gets the Validity `138a:0090` fingerprint sensor working with `fprintd`, without touching the system `libfprint`. **LGPL-2.1-or-later.** | RHEL 10 / CentOS Stream 10 |
| [**field-mode/**](field-mode/) | One command for off-AC use: CPU governor, WiFi, brightness and TLP profile, and back. | LXQt |
| [**wallpaper/**](wallpaper/) | Live system-info wallpaper that redraws when your stats change: `fastfetch` + `awww` on niri, `neofetch` on KDE Plasma. | niri / Wayland, KDE |
| [`mouse-jiggler.py`](mouse-jiggler.py) | Keeps the screen awake during long compiles and downloads. | KDE, X11 or Wayland |
| [`pkgfilter.py`](pkgfilter.py) | The original interactive Arch package bloat hunter. | Arch |

---

## mouse-jiggler.py

Detects X11 or Wayland on its own: nudges the cursor with `xdotool` on X11, or takes a DBus screensaver inhibit
(falling back to `ydotool`) on Wayland. A small GUI with a start/stop toggle and an interval from 5 to 300 s.

```bash
python linux/mouse-jiggler.py
```

## pkgfilter.py

> [!TIP]
> For a version Claude drives, that explains each big folder and remembers what you said to keep, use the
> [pkgfilter skill](../skills/pkgfilter/). This script is what it grew out of.

The first run saves every installed package with its size (`pacman -Qq` / `-Qi`) as `revision1.txt`. Each later run
strips packages by keyword (`plasma`, `kde`, `qt`), so what's left is what you don't recognise, optionally drops anything
under a size, and saves the next `revisionN.txt` so you can diff passes. It can also list the 20 largest directories
and files on the filesystem. Run it from an empty folder: that's where the revision files pile up.

```bash
python3 pkgfilter.py                    # interactive: keywords, size filter, optional fs scan
python3 pkgfilter.py -k plasma          # strip a keyword
python3 pkgfilter.py -s 5MiB            # drop anything under 5 MiB
python3 pkgfilter.py -k kde -s 10MiB    # both
sudo python3 pkgfilter.py               # full filesystem scan outside your home
```
