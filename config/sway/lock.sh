#!/bin/sh

swaylock_bin="/usr/local/bin/swaylock"
wallpaper="/home/minhbui/.config/sway/assets/wallpaper.jpg"
if [ ! -x "$swaylock_bin" ]; then
    swaylock_bin="swaylock"
fi

exec "$swaylock_bin" -f \
    -i "$wallpaper" \
    --scaling fill \
    --effect-blur 8x4 \
    --fade-in 0.2 \
    --indicator \
    --clock \
    --timestr "%H:%M" \
    --datestr "%A, %B %d" \
    --show-failed-attempts \
    --show-keyboard-layout \
    --font "JetBrainsMono Nerd Font" \
    --font-size 18 \
    --indicator-radius 92 \
    --indicator-thickness 9 \
    --inside-color 282828dd \
    --inside-clear-color 282828dd \
    --inside-ver-color 3c3836dd \
    --inside-wrong-color 3c1f1fdd \
    --ring-color 504945ff \
    --ring-clear-color 83a598ff \
    --ring-ver-color b8bb26ff \
    --ring-wrong-color fb4934ff \
    --key-hl-color fabd2fff \
    --bs-hl-color fb4934ff \
    --line-color 00000000 \
    --separator-color 00000000 \
    --text-color ebdbb2ff \
    --text-clear-color ebdbb2ff \
    --text-ver-color ebdbb2ff \
    --text-wrong-color fb4934ff \
    --layout-bg-color 282828dd \
    --layout-border-color 504945ff \
    --layout-text-color ebdbb2ff
