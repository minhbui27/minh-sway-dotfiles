# Sway Shortcut Sheet

Generated: 2026-05-12

Modifier notes:

- `Alt` is the main Sway modifier (`$mod` / `Mod1`).
- `Super` is `Mod4`.
- Some custom shortcuts have both `Super` and `Alt` fallbacks because the modifier setup was changed during configuration.

## Custom Shortcuts

| Shortcut | Action |
| --- | --- |
| `Ctrl+Space` | Toggle input source between `US` and `JP` |
| `Ctrl+J` | Force Japanese Mozc Hiragana mode (`JP あ`) |
| `Super+Shift+P` | Open power menu |
| `Alt+Shift+P` | Open power menu fallback |
| `Super+Shift+O` | Force outputs back on |
| `Alt+Shift+O` | Force outputs back on fallback |
| `Super+Shift+A` | Open audio menu |
| `Alt+Shift+A` | Open audio menu fallback |
| `Print` | Full screenshot to `~/Pictures/Screenshots/` |
| `Super+Shift+S` | Drag-select screenshot region to file |
| `Alt+Shift+S` | Drag-select screenshot region to file fallback |
| `Super+Shift+C` | Drag-select screenshot region to clipboard |
| `Alt+Shift+C` | Drag-select screenshot region to clipboard fallback |
| `Volume Up` | Unmute output, then raise volume |
| `Volume Down` | Unmute output, then lower volume |
| `Volume Mute` | Toggle output mute |
| `Mic Mute` | Toggle microphone mute |

## Bar Clicks

| Bar Item | Action |
| --- | --- |
| Keyboard status | Display current `US` / `JP` state |
| Volume status | Open audio menu |
| Battery status | Display battery state |
| Wi-Fi status | Open Wi-Fi menu |
| Bluetooth status | Open Bluetooth paired-device menu |
| Power icon | Open power menu |

## Menus

| Menu | What It Does |
| --- | --- |
| Power menu | Lock, suspend, restart, power off |
| Wi-Fi menu | Rescan, toggle Wi-Fi, disconnect, connect to visible/saved networks |
| Audio menu | Mute, volume up/down, choose output device, choose input device, open Bluetooth menu |
| Bluetooth menu | Toggle Bluetooth, connect/disconnect paired devices |

## Core Sway Shortcuts

| Shortcut | Action |
| --- | --- |
| `Alt+Enter` | Open terminal (`kitty`) |
| `Alt+D` | Open app launcher (`wofi`) |
| `Alt+Shift+Q` | Close focused window |
| `Alt+Shift+R` | Reload Sway config |
| `Alt+Shift+E` | Exit Sway session prompt |
| `Alt+H/J/K/L` | Focus left/down/up/right |
| `Alt+Arrow` | Focus left/down/up/right |
| `Alt+Shift+H/J/K/L` | Move focused window left/down/up/right |
| `Alt+Shift+Arrow` | Move focused window left/down/up/right |
| `Alt+1` ... `Alt+0` | Switch to workspace 1 ... 10 |
| `Alt+Shift+1` ... `Alt+Shift+0` | Move focused window to workspace 1 ... 10 |
| `Alt+B` | Split horizontally |
| `Alt+V` | Split vertically |
| `Alt+S` | Stacking layout |
| `Alt+W` | Tabbed layout |
| `Alt+E` | Toggle split layout |
| `Alt+F` | Toggle fullscreen |
| `Alt+Shift+Space` | Toggle floating |
| `Alt+Space` | Toggle focus between tiling/floating |
| `Alt+A` | Focus parent container |
| `Alt+Shift+-` | Move focused window to scratchpad |
| `Alt+-` | Show/hide scratchpad window |
| `Alt+R` | Enter resize mode |
| `H/J/K/L` in resize mode | Resize left/down/up/right |
| `Arrow` in resize mode | Resize left/down/up/right |
| `Enter` or `Esc` in resize mode | Leave resize mode |

## Idle And Power Behavior

| Condition | Behavior |
| --- | --- |
| 10 minutes idle on battery | Suspend; `before-sleep` locks first |
| 10 minutes idle while plugged in | Stay awake |
| Sleep mode | `s2idle`, so the internal keyboard can wake the laptop |
| Idle screen-off | Disabled until display wake is reliable on this machine |
| Lid close | Sway handles lid-close and suspends |
| Before sleep | Lock first |

## Helper Files

| File | Purpose |
| --- | --- |
| `~/.config/sway/config` | Main Sway config |
| `~/.config/sway/status.sh` | Swaybar status and click handling |
| `~/.config/sway/power-menu.sh` | Power menu |
| `~/.config/sway/wifi-menu.sh` | Wi-Fi menu |
| `~/.config/sway/audio-menu.sh` | Audio menu |
| `~/.config/sway/bluetooth-menu.sh` | Bluetooth menu |
| `~/.config/sway/volume.sh` | Volume key helper |
| `~/.config/sway/screenshot.sh` | Screenshot helper |
| `~/.config/sway/toggle-input.sh` | `US` / `JP` toggle |
| `~/.config/sway/kana-input.sh` | Force Japanese Hiragana mode |
| `~/.config/sway/workspace-labels.py` | Dynamic workspace labels |
| `~/.config/sway/inhibit-lid-suspend.sh` | Prevent logind's default lid handling so Sway can handle lid close |
| `~/.config/sway/idle-suspend.sh` | Suspend after idle unless the system just resumed |
| `~/.config/sway/resume-from-suspend.sh` | Mark resume time and power outputs on |
| `~/.config/sway/lid-close.sh` | Suspend when the lid closes |
| `~/.config/sway/lid-open.sh` | Power outputs back on when the lid opens |
| `~/.config/sway/suspend-on-battery.sh` | Battery-only suspend helper, currently unused |
