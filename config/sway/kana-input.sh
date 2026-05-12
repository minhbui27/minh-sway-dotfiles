#!/bin/sh

mode_file="${XDG_CACHE_HOME:-$HOME/.cache}/sway/ibus-mozc-mode"
mkdir -p "$(dirname "$mode_file")"
log_file="${XDG_CACHE_HOME:-$HOME/.cache}/sway/kana-input.log"

{
    printf "%s pid=%s engine_before=" "$(date '+%F %T')" "$$"
    ibus engine 2>/dev/null || printf "unknown"
    printf "\n"
} >> "$log_file"

# Make Ctrl+J mean "Japanese hiragana" globally.
ibus engine mozc-jp >/dev/null 2>&1 || true

for _ in 1 2 3 4 5 6 7 8 9 10; do
    [ "$(ibus engine 2>/dev/null)" = "mozc-jp" ] && break
    sleep 0.05
done

address=$(ibus address 2>/dev/null)
context=$(gdbus call --address "$address" \
    --dest org.freedesktop.IBus \
    --object-path /org/freedesktop/IBus \
    --method org.freedesktop.IBus.CurrentInputContext 2>/dev/null \
    | sed -n "s/.*'\([^']*\)'.*/\1/p")

if [ -n "$address" ] && [ -n "$context" ]; then
    DBUS_SESSION_BUS_ADDRESS="$address" dbus-send --type=method_call \
        --dest=org.freedesktop.IBus "$context" \
        org.freedesktop.IBus.InputContext.PropertyActivate \
        string:InputMode.Hiragana uint32:1 >/dev/null 2>&1 || true

    DBUS_SESSION_BUS_ADDRESS="$address" dbus-send --type=method_call \
        --dest=org.freedesktop.IBus "$context" \
        org.freedesktop.IBus.InputContext.ProcessKeyEvent \
        uint32:65317 uint32:0 uint32:0 >/dev/null 2>&1 || true
    DBUS_SESSION_BUS_ADDRESS="$address" dbus-send --type=method_call \
        --dest=org.freedesktop.IBus "$context" \
        org.freedesktop.IBus.InputContext.ProcessKeyEvent \
        uint32:65317 uint32:0 uint32:1073741824 >/dev/null 2>&1 || true
fi

printf "あ\n" > "$mode_file"

{
    printf "%s pid=%s engine_after=" "$(date '+%F %T')" "$$"
    ibus engine 2>/dev/null || printf "unknown"
    printf " mode_cache="
    cat "$mode_file" 2>/dev/null || printf "unknown"
} >> "$log_file"
