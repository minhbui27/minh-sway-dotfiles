#!/usr/bin/env python3

import fcntl
import json
import os
import re
import subprocess
import sys
import time


MAX_NAME_LENGTH = 34
RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", f"/tmp/sway-workspace-labels-{os.getuid()}")
LOCK_FILE = os.path.join(RUNTIME_DIR, "workspace-labels.lock")
LOG_FILE = os.path.join(
    os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")),
    "sway",
    "workspace-labels.log",
)

APP_NAMES = {
    "anki": "Anki",
    "brave-browser": "Brave",
    "chromium": "Chromium",
    "code": "Code",
    "firefox": "Firefox",
    "google-chrome": "Chrome",
    "kitty": "term",
    "org.gnome.nautilus": "Files",
    "terminator": "term",
    "thunderbird": "Mail",
    "wofi": "wofi",
}

TERMINALS = {"kitty", "terminator", "foot", "alacritty"}


def log(message):
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    with open(LOG_FILE, "a", encoding="utf-8") as handle:
        handle.write(f"{time.strftime('%F %T')} {message}\n")


def take_lock():
    os.makedirs(RUNTIME_DIR, exist_ok=True)
    lock = open(LOCK_FILE, "w", encoding="utf-8")
    try:
        fcntl.lockf(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        sys.exit(0)
    return lock


def sway_json(*args):
    output = subprocess.check_output(["swaymsg", *args], text=True)
    return json.loads(output)


def sway_command(command):
    subprocess.run(["swaymsg", command], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)


def quote(text):
    return text.replace("\\", "\\\\").replace('"', '\\"')


def clean_title(title):
    title = re.sub(r"\s+", " ", title or "").strip()
    if title and 0x2800 <= ord(title[0]) <= 0x28FF:
        title = title[1:].strip()
    title = re.sub(r"\s+-\s+(Brave|Google Chrome|Mozilla Firefox)$", "", title)
    return title


def app_key(con):
    props = con.get("window_properties") or {}
    value = con.get("app_id") or props.get("class") or props.get("instance") or ""
    return value.strip()


def app_label(con):
    key = app_key(con)
    return APP_NAMES.get(key.lower(), key)


def truncate(text, max_length=MAX_NAME_LENGTH):
    text = text.strip()
    if len(text) <= max_length:
        return text
    return text[: max_length - 3].rstrip() + "..."


def walk(node):
    yield node
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        yield from walk(child)


def workspace_nodes(tree):
    return [
        node
        for node in walk(tree)
        if node.get("type") == "workspace" and isinstance(node.get("num"), int) and node.get("num") > 0
    ]


def windows_in_workspace(workspace):
    return [
        node
        for node in walk(workspace)
        if node.get("pid") is not None and (node.get("app_id") or node.get("window_properties") or node.get("name"))
    ]


def representative_window(workspace):
    windows = windows_in_workspace(workspace)
    if not windows:
        return None

    for window in windows:
        if window.get("focused"):
            return window

    by_id = {window.get("id"): window for window in windows}
    for node_id in reversed(workspace.get("focus", [])):
        if node_id in by_id:
            return by_id[node_id]

    return windows[0]


def label_for_window(window):
    app = app_label(window)
    key = app_key(window).lower()
    title = clean_title(window.get("name"))

    if key in TERMINALS:
        return truncate(title or app or "term")

    if app and title and app.lower() not in title.lower():
        return truncate(f"{app}: {title}")

    return truncate(app or title or "window")


def desired_workspace_name(workspace):
    number = workspace.get("num")
    window = representative_window(workspace)
    if not window:
        return str(number)
    return f"{number}: {label_for_window(window)}"


def update_workspaces():
    tree = sway_json("-t", "get_tree")
    for workspace in workspace_nodes(tree):
        old_name = workspace.get("name") or str(workspace.get("num"))
        new_name = desired_workspace_name(workspace)
        if old_name == new_name:
            continue
        sway_command(f'rename workspace "{quote(old_name)}" to "{quote(new_name)}"')


def watch():
    update_workspaces()
    events = json.dumps(["workspace", "window", "binding"])
    process = subprocess.Popen(
        ["swaymsg", "-t", "subscribe", "-m", events],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        bufsize=1,
    )

    assert process.stdout is not None
    for line in process.stdout:
        if line.strip():
            update_workspaces()


def main():
    if "--once" in sys.argv:
        update_workspaces()
        return

    lock = take_lock()
    try:
        watch()
    except Exception as error:
        log(f"error: {error}")
        raise
    finally:
        lock.close()


if __name__ == "__main__":
    main()
