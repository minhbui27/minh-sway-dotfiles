# Minh Sway Dotfiles

This repo contains my Sway desktop configuration, helper scripts, terminal settings, selected app wrappers, and notes for restoring the setup on another Ubuntu/Sway machine.

The active setup was built on Ubuntu 24.04 with Sway, PipeWire/WirePlumber, IBus Mozc, Wofi, Kitty, and `swaylock-effects`.

## Layout

```text
config/sway/                  Sway config, bar, menus, lock, screenshots, input helpers
config/sway/assets/           Wallpaper and other Sway assets
config/kitty/                 Kitty config
config/terminator/            Terminator profile config
config/mozc/                  Minimal IBus Mozc text config only
local/bin/                    App wrapper scripts for Sway/IBus behavior
local/share/applications/     Desktop-entry overrides for Wofi/app launchers
docs/sway-shortcuts.md        Shortcut reference
install.sh                    Non-destructive restore script
```

## Main Features

- Alt-based Sway modifier.
- Dynamic workspace labels based on focused app/window.
- Swaybar status with clickable menus for Wi-Fi, Bluetooth, audio, and power.
- IBus/Mozc helpers for Japanese input.
- Kitty default terminal, with Terminator available for Japanese terminal input.
- Screenshot helpers using `grim`, `slurp`, and `wl-copy`.
- Styled `swaylock-effects` lock screen using the stored wallpaper.
- Idle behavior:
  - 10 min: lock
  - 10 min 15 sec: screen off
  - 30 min: suspend only on battery
  - plugged in: never idle-suspend

## Required Packages

Base packages:

```bash
sudo apt install sway swayidle swaylock wofi kitty terminator \
  ibus ibus-mozc jq grim slurp wl-clipboard \
  pipewire wireplumber network-manager bluez upower libnotify-bin \
  fonts-font-awesome
```

Useful extras:

```bash
sudo apt install pavucontrol blueman
```

For the enhanced lock screen, build and install `swaylock-effects`:

```bash
sudo apt install git meson ninja-build pkg-config scdoc \
  libwayland-dev wayland-protocols libxkbcommon-dev \
  libcairo2-dev libgdk-pixbuf-2.0-dev libpam0g-dev

mkdir -p ~/src
cd ~/src
git clone https://github.com/mortie/swaylock-effects.git
cd swaylock-effects
meson setup build --prefix=/usr/local
ninja -C build
sudo ninja -C build install
```

Verify:

```bash
/usr/local/bin/swaylock --help | grep -E 'clock|effect-blur|screenshots'
```

## Install On A New Machine

Clone:

```bash
git clone git@github.com:minhbui27/minh-sway-dotfiles.git ~/minh-sway-dotfiles
cd ~/minh-sway-dotfiles
```

Preview what will be installed:

```bash
./install.sh --dry-run
```

Install:

```bash
./install.sh
```

The installer backs up existing files into:

```text
~/.dotfiles-backup/YYYYmmdd-HHMMSS/
```

It then copies files into:

```text
~/.config/sway/
~/.config/kitty/
~/.config/terminator/
~/.config/mozc/ibus_config.textproto
~/.local/bin/
~/.local/share/applications/
~/sway-shortcuts.md
```

During install, text files have `/home/minhbui` rewritten to the target `$HOME`, so the config can be restored under a different home path.

## After Install

Reload Sway:

```bash
swaymsg reload
```

Restart IBus if Japanese input does not appear:

```bash
ibus restart
```

If Wofi shows stale duplicate entries, clear its drun cache:

```bash
rm -f ~/.cache/wofi-drun
```

## Pairing New Bluetooth Devices

The included Bluetooth menu handles already-paired devices. To pair a new device:

```bash
bluetoothctl
```

Inside the prompt:

```text
power on
agent on
default-agent
scan on
pair XX:XX:XX:XX:XX:XX
trust XX:XX:XX:XX:XX:XX
connect XX:XX:XX:XX:XX:XX
scan off
quit
```

After pairing, the device should appear in the Bluetooth menu.

## Notes

- Do not commit `~/.cache`, Mozc databases, lock files, or generated `__pycache__`.
- `config/mozc/ibus_config.textproto` is intentionally the only Mozc file tracked.
- Some wrappers force XWayland/IBus for browsers and Anki so Japanese input works more reliably under Sway.
- Kitty stays native Wayland so image rendering still works.
