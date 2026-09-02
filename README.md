# Minh Sway Dotfiles

This repo contains my Sway desktop configuration, helper scripts, terminal settings, desktop entries, and notes for restoring the setup on another Ubuntu machine.

The active setup was built on Ubuntu 24.04 (ThinkPad X1 Carbon Gen 9) with Sway 1.10.1 (built from source), PipeWire/WirePlumber, Fcitx5 + Mozc, Wofi, Mako, Kitty, and `swaylock-effects`. The session is started from GDM's "Sway" entry.

## Layout

```text
config/sway/                  Sway config, bar, menus, lock, screenshots, input helpers
config/sway/assets/           Wallpaper and other Sway assets
config/kitty/                 Kitty config + light/dark themes and toggle script
config/mako/                  Mako notification daemon config
config/terminator/            Terminator profile config (legacy, rarely used)
config/fcitx5/                Fcitx5 profile for US keyboard plus Mozc
config/mozc/                  Legacy minimal IBus Mozc text config
local/share/applications/     Desktop-entry overrides for Wofi/app launchers
shell/bashrc-extras.sh        Custom ~/.bashrc additions (uva-vpn, aliases, PATH)
systemd/logind.conf.d/        System config so Sway (not logind) owns lid-close
systemd/enable-wake-sources.sh Root helper for mem_sleep mode and wake sources
systemd/system/               Systemd service that applies wake sources at boot
systemd/tmpfiles.d/           Optional deep-sleep persistence (see Suspend section)
docs/sway-shortcuts.md        Shortcut reference
install.sh                    Non-destructive restore script
```

## Main Features

- Alt-based Sway modifier (`$mod` = `Mod1`).
- Dynamic workspace labels named after the focused app/window (`workspace-labels.py`, needs `python3-i3ipc`).
- Swaybar status with clickable menus for Wi-Fi, Bluetooth, audio, brightness, and power; clock pinned to US Eastern time (`TZ=America/New_York` in `status.sh` — edit there to change).
- Brightness keys with percentage notifications and a Wofi brightness menu (`brightnessctl`).
- Fcitx5/Mozc helpers for Japanese input (`Ctrl+Space` toggle, `Ctrl+J` force kana).
- Kitty default terminal (official installer in `~/.local/kitty.app`) with a light/dark theme toggle.
- Mako desktop notifications.
- Screenshot helpers using `grim`, `slurp`, and `wl-copy` (full / region-to-file / region-to-clipboard).
- Styled `swaylock-effects` lock screen using the stored wallpaper.
- Lid close suspends while Sway is running, with Sway handling the lid switch directly.
- `remote-float.py`: ssh-forwarded X11 windows are floated and collected on workspace 9.
- Idle behavior:
  - 10 min idle: lock screen
  - 11 min idle: blank and power off active displays
  - 15 min on battery: suspend
  - 15 min plugged in: stay locked, blanked, and awake

See `docs/sway-shortcuts.md` for the full keybind and menu reference.

## Required Packages

Sway itself and swaylock are **built from source** (next section). The distro `sway` package is still installed for the GDM session file and dependencies; the source build in `/usr/local/bin` shadows it via PATH.

```bash
sudo apt install sway swayidle swaybg wofi mako-notifier \
  fcitx5 fcitx5-mozc fcitx5-config-qt fcitx5-frontend-all \
  jq grim slurp wl-clipboard brightnessctl \
  python3-i3ipc x11-utils \
  pipewire wireplumber network-manager bluez upower libnotify-bin \
  fonts-font-awesome
```

Useful extras:

```bash
sudo apt install pavucontrol blueman terminator openconnect network-manager-openconnect
```

Kitty via the official installer (the Sway config points at `~/.local/kitty.app/bin/kitty`):

```bash
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
mkdir -p ~/.local/bin
ln -sf ~/.local/kitty.app/bin/kitty ~/.local/kitty.app/bin/kitten ~/.local/bin/
```

## Source Builds

Both live in `~/src` and install to `/usr/local`.

### Sway 1.10.1

Ubuntu 24.04 ships Sway 1.9; this setup runs 1.10.1. wlroots 0.18 and wayland are pulled automatically as meson subprojects (built statically), so no separate wlroots install is needed.

```bash
sudo apt install git meson ninja-build pkg-config scdoc
# pull the rest of the build deps from the distro sway package
# (enable deb-src in /etc/apt/sources.list.d/ubuntu.sources first if needed)
sudo apt build-dep sway

mkdir -p ~/src && cd ~/src
git clone https://github.com/swaywm/sway.git
cd sway
git checkout 1.10.1
meson setup build --prefix=/usr/local
ninja -C build
sudo ninja -C build install
```

Verify with `/usr/local/bin/sway --version` and log out/in; GDM's Sway session launches `sway` from PATH, which resolves to `/usr/local/bin/sway`.

### swaylock-effects v1.7.0.0

```bash
sudo apt install libwayland-dev wayland-protocols libxkbcommon-dev \
  libcairo2-dev libgdk-pixbuf-2.0-dev libpam0g-dev

cd ~/src
git clone https://github.com/mortie/swaylock-effects.git
cd swaylock-effects
git checkout v1.7.0.0
meson setup build --prefix=/usr/local
ninja -C build
sudo ninja -C build install
```

Verify:

```bash
/usr/local/bin/swaylock --help | grep -E 'clock|effect-blur|screenshots'
```

`lock.sh` calls `/usr/local/bin/swaylock` by absolute path.

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

The installer backs up existing files into `~/.dotfiles-backup/YYYYmmdd-HHMMSS/` and then copies into:

```text
~/.config/sway/
~/.config/fcitx5/
~/.config/kitty/
~/.config/terminator/
~/.config/mako/
~/.config/mozc/ibus_config.textproto
~/.local/share/applications/
~/sway-shortcuts.md
```

During install, text files have `/home/minhbui` rewritten to the target `$HOME`, so the config can be restored under a different home path.

Shell extras (the `uva-vpn` helper, `prism` alias, PATH entries) are not auto-installed; add to `~/.bashrc`:

```bash
. ~/minh-sway-dotfiles/shell/bashrc-extras.sh
```

## Suspend, Lid, And Wake Behavior

How it fits together:

- `systemd/logind.conf.d/10-sway-no-lid-suspend.conf` makes logind ignore the lid switch system-wide; `inhibit-lid-suspend.sh` (started by Sway) additionally holds a `handle-lid-switch` inhibitor.
- Sway's `bindswitch lid:on/off` then owns the lid: close → `lid-close.sh` (`systemctl suspend`, always), open → `lid-open.sh` (outputs back on).
- `start-swayidle.sh` stages the idle policy: lock at 10 min, screens off at 11 min, suspend at 15 min **on battery only** (`idle-suspend.sh`, with a 2-minute grace period after any resume), lock before any sleep.
- `minh-wake-sources.service` runs `enable-wake-sources.sh` at boot: sets `mem_sleep` to `s2idle` and enables internal keyboard / TrackPoint / Intel HID wake. Broad USB/Bluetooth wake stays disabled because it caused immediate resume on this laptop.

Install the system pieces (the installer never writes root-owned files):

```bash
sudo install -Dm644 systemd/logind.conf.d/10-sway-no-lid-suspend.conf /etc/systemd/logind.conf.d/10-sway-no-lid-suspend.conf
sudo install -Dm755 systemd/enable-wake-sources.sh /usr/local/bin/minh-enable-wake-sources
sudo install -Dm644 systemd/system/minh-wake-sources.service /etc/systemd/system/minh-wake-sources.service
sudo systemctl enable --now minh-wake-sources.service
```

Reboot afterward, or restart `systemd-logind` from a TTY if you need the lid change immediately.

### If resume from suspend hangs

On the X1 Carbon Gen 9, `s2idle` occasionally fails to resume (screen stays black, power button forced-shutdown needed; journal shows `PM: suspend entry (s2idle)` with no matching exit). The fix is firmware-level `deep` (S3) sleep — the trade-off is that the internal keyboard no longer wakes the laptop (use the power button or lid), and resume is a bit slower.

Test for one boot:

```bash
echo deep | sudo tee /sys/power/mem_sleep
systemctl suspend
```

If that resumes reliably, make it persistent — **and** change `set_mem_sleep s2idle` to `set_mem_sleep deep` in `enable-wake-sources.sh` (or disable `minh-wake-sources.service`), since the service re-applies `s2idle` at every boot:

```bash
sudo install -Dm644 systemd/tmpfiles.d/mem-sleep.conf /etc/tmpfiles.d/mem-sleep.conf
```

If `deep` also misbehaves, check BIOS → Config → Power → Sleep State → "Linux".

### Bluetooth wake (optional, current boot only)

```bash
sudo ENABLE_BLUETOOTH_WAKE=1 sh systemd/enable-wake-sources.sh
systemctl suspend
```

If the laptop immediately wakes by itself, run the script again without the variable to disable it.

## Launcher Entries And AppImages

Wofi's `drun` mode (`Alt+D`) lists `.desktop` files from `~/.local/share/applications/` and `/usr/share/applications/`. To add an AppImage:

1. Put the AppImage somewhere stable, e.g. `~/.local/bin/Foo.AppImage`, and `chmod +x` it.
2. Extract its icon once: `./Foo.AppImage --appimage-extract`, copy the `.png` to `~/.local/share/icons/`, delete `squashfs-root/`.
3. Create `~/.local/share/applications/foo.desktop` with `Name=`, `Exec=/home/you/.local/bin/Foo.AppImage %U`, and `Icon=` pointing at the copied png (absolute path). `Categories=` is ignored by Wofi. No reload needed — Wofi rescans on every launch.

`prismlauncher.desktop`, `obsidian.desktop`, and `org.qbittorrent.qBittorrent.desktop` in this repo follow that pattern; update their `Exec=`/`Icon=` paths for wherever the AppImages actually live on the new machine. `net.ankiweb.Anki.desktop` expects Anki via flatpak.

## Not In This Repo — Migrate By Hand

- **`~/.cert/`** (private, never commit): `eduroam-minhx1.p12`, `uva-vpn.p12` (SecureW2 client certs), `uva-anywhere-ca.pem` (CA bundle for the UVA Anywhere gateway). Copy with `scp`/USB, keep mode 600. Without these, eduroam Wi-Fi and `uva-vpn` won't connect; certs can be regenerated at the SecureW2 portal (Netbadge login; p12 passphrase must be < 15 characters).
- **NetworkManager connections**: either reconfigure Wi-Fi by hand or copy profiles from `/etc/NetworkManager/system-connections/` (root-owned, mode 600). For eduroam autoconnect, store the p12 passphrase in the profile: `sudo nmcli connection modify eduroam 802-1x.private-key-password-flags 0 802-1x.private-key-password '...'`.
- **AppImages / flatpaks**: Prism Launcher and qBittorrent AppImages in `~/.local/bin/`, Obsidian AppImage, Anki flatpak (`flatpak install flathub net.ankiweb.Anki`).
- **Wallpaper-adjacent state**: nothing else — the wallpaper ships in `config/sway/assets/`.
- **GDM**: no config needed; pick the "Sway" session on the login screen.
- Optional system timezone: `sudo timedatectl set-timezone America/New_York` (the swaybar clock is already pinned to Eastern regardless).

## After Install

Reload Sway:

```bash
swaymsg reload
```

Restart Fcitx5 if Japanese input does not appear:

```bash
~/.config/sway/start-fcitx5.sh
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
```
