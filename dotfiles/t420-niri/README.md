# t420-niri dotfiles

Arch Linux + [niri](https://github.com/YaLTeR/niri) on a ThinkPad T420 (1366x768, Intel HD 3000). Catppuccin Mocha throughout.
Lean and terminal-first: niri, waybar, fuzzel, mako, swayidle/swaylock, Terminology, Zed, Brave.

## Layout
| Path | What |
|---|---|
| `home/` | Mirrors `$HOME` (`.config/niri`, `waybar`, `mako`, `fuzzel`, `swayidle`, `swaylock`, `gtk-3.0`, Terminology colour scheme, `mimeapps.list`, `.zshrc`, systemd user unit) |
| `bin/` | Scripts for `~/.local/bin`: `cheatsheet` (keybind cheat sheet), `caffeine` (idle-inhibit toggle), `nightlight` (wlsunset toggle), `clip-menu` (cliphist picker), `peek-desktop`, `powermenu`, `battmenu` (battery dropdown) |
| `system/` | Root-owned files, reference only: zram, earlyoom, sysctl, SDDM/GRUB Catppuccin themes, `battctl` + sudoers rule |
| `terminology-base.cfg.txt` | Decoded Terminology config (the real one is a binary `.eet`) |

The live fastfetch wallpaper is in [`../../wallpaper-niri/`](../../wallpaper-niri/).

## Install
```bash
./install.sh            # user files; backs up anything it would change as *.pre-dotfiles
niri validate           # then log out and back in
```
Needs: niri waybar fuzzel mako swayidle swaylock wlsunset cliphist wl-clipboard awww fastfetch python-pillow
ttf-jetbrains-mono-nerd terminology polkit-gnome tlp.

## Root steps (you run these, nothing here touches the system on its own)
```bash
# zram swap + tuning
sudo cp system/zram-generator.conf /etc/systemd/ && sudo cp system/99-zram.conf /etc/sysctl.d/ && sudo sysctl --system
# battery dropdown helper: limited sudo rule, validate before installing
sudo install -m 755 system/battctl /usr/local/bin/battctl
sudo sh -c 'visudo -cf system/battctl.sudoers.example && install -m 440 system/battctl.sudoers.example /etc/sudoers.d/battctl'
```
Edit the username in `battctl.sudoers.example` first. `earlyoom`, the SDDM theme and the GRUB lines are copied as-is for reference.

## Notes
- The SDDM/GRUB themes are Catppuccin Mocha with a custom background. The background image is **not** included (licence unknown); drop your own in as `background.png` (GRUB) and `backgrounds/tux.png` (SDDM).
- Keybinds avoid Mod+Shift chords on purpose. Press Scroll Lock for the cheat sheet.
- `battmenu` charge limit sets start/end thresholds (75/80) via `thinkpad_acpi`; profiles use `tlp bat|ac|start`.
