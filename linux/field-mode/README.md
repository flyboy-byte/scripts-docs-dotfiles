# field-mode

Battery-saving toggle for LXQt field use — ham radio logging, outdoor work, anywhere you're off AC.

One command flips CPU governor, WiFi power save, screen brightness, and TLP battery profile all at once. Toggle it off to restore everything.

## Usage

```bash
field-mode               # show help
field-mode on            # enable (WiFi power save)
field-mode on wifi-off   # enable (WiFi interface down)
field-mode off           # disable, restore everything
field-mode status        # show current state
field-mode help          # show help
```

## What it does

| Setting | Field mode ON | `on wifi-off` | Field mode OFF |
|---|---|---|---|
| CPU governor | `powersave` | `powersave` | `schedutil` |
| WiFi | power save on | interface down | restored |
| Screen brightness | 40% | 40% | restored to previous |
| TLP profile | forced battery | forced battery | auto-detect |

Use `wifi-off` when you don't need internet at all (pure radio logging) — it saves more power than power save alone.

## Setup

**Dependencies:**
```bash
sudo pacman -S tlp brightnessctl
sudo systemctl enable --now tlp
```

**Install the script:**
```bash
cp field-mode ~/bin/field-mode
chmod +x ~/bin/field-mode
# make sure ~/bin is in your PATH
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
```

**Passwordless sudo** (so it doesn't prompt mid-field):
```bash
# edit sudoers.example — replace "logan" with your username
sudo visudo -c -f sudoers.example && sudo cp sudoers.example /etc/sudoers.d/field-mode
```

**LXQt keyboard shortcut:**
LXQt Settings → Shortcut Keys → Add → command `field-mode`, assign a key like `Meta+F`.
