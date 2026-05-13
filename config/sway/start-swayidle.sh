#!/bin/sh

pkill -x swayidle 2>/dev/null || true

exec swayidle -w \
    timeout 600 '/home/minhbui/.config/sway/lock.sh' \
    timeout 900 '/home/minhbui/.config/sway/idle-suspend.sh' \
    resume '/home/minhbui/.config/sway/resume-from-suspend.sh' \
    before-sleep '/home/minhbui/.config/sway/lock.sh' \
    idlehint 600
