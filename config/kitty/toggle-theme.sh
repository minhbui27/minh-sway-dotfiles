#!/bin/sh
# Toggle kitty between Gruvbox Light Hard and Gruvbox Dark, live-reloading
# every open kitty window.
theme_file="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/current-theme.conf"

if grep -qi 'name: One Half Light' "$theme_file" 2>/dev/null; then
    next="Gruvbox Dark"
else
    next="One Half Light"
fi

exec kitten themes --reload-in=all "$next"
