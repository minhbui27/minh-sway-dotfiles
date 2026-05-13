#!/bin/sh

case "$(ibus engine 2>/dev/null)" in
    mozc-jp)
        ibus engine xkb:us::eng >/dev/null 2>&1 || true
        ;;
    *)
        /home/minhbui/.config/sway/kana-input.sh >/dev/null 2>&1 || true
        ;;
esac
