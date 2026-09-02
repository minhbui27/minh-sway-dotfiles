#!/usr/bin/python3
"""Float ssh-forwarded X11 windows and send them to a dedicated workspace."""
import socket
import subprocess
import i3ipc

WORKSPACE = 9                # workspace *number* to collect remote windows on
LOCAL = socket.gethostname()  # anything NOT from this host is "remote"
SKIP_CLASSES = {"X2GoAgent", "x2goclient", "nxproxy"}  # x2go manages its own window

def on_new(i3, event):
    con = event.container
    if con.window is None:        # native Wayland window -> local, skip
        return
    if con.window_class in SKIP_CLASSES:
        return
    try:
        out = subprocess.check_output(
            ["xprop", "-id", str(con.window), "WM_CLIENT_MACHINE"],
            text=True, stderr=subprocess.DEVNULL,
        )
    except subprocess.CalledProcessError:
        return
    if '"' not in out:
        return
    host = out.split('"')[1]
    if host != LOCAL and not host.startswith(LOCAL + "."):
        con.command(f'floating enable, move container to workspace number {WORKSPACE}')

i3 = i3ipc.Connection()
i3.on("window::new", on_new)
i3.main()
