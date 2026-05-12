#!/bin/sh

export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export INPUT_METHOD=ibus
export SDL_IM_MODULE=ibus
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb
export MOZ_ENABLE_WAYLAND=0

exec "$@"
