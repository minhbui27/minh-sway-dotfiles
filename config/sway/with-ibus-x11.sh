#!/bin/sh

export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export INPUT_METHOD=fcitx
export SDL_IM_MODULE=fcitx
export CLUTTER_IM_MODULE=fcitx
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb
export MOZ_ENABLE_WAYLAND=0

exec "$@"
