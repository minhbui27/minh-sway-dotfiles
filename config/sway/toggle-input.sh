#!/bin/sh

case "$(ibus engine 2>/dev/null)" in
    mozc-jp)
        ibus engine xkb:us::eng >/dev/null 2>&1 || true
        ;;
    *)
        ibus engine mozc-jp >/dev/null 2>&1 || true
        ;;
esac
