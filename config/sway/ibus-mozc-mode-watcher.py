#!/usr/bin/python3
import fcntl
import os
import re
import sys
import time

import gi

gi.require_version("IBus", "1.0")
from gi.repository import Gio, GLib, IBus


STATE_DIR = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "sway")
STATE_FILE = os.path.join(STATE_DIR, "ibus-mozc-mode")
RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", f"/tmp/ibus-mozc-mode-{os.getuid()}")
LOCK_FILE = os.path.join(RUNTIME_DIR, "ibus-mozc-mode-watcher.lock")

MODE_BY_KEY = {
    "InputMode.Direct": "A",
    "InputMode.Hiragana": "あ",
    "InputMode.Katakana": "ア",
    "InputMode.Latin": "A",
    "InputMode.WideLatin": "Ａ",
    "InputMode.HalfWidthKatakana": "ｱ",
}


def take_lock():
    os.makedirs(RUNTIME_DIR, exist_ok=True)
    lock = open(LOCK_FILE, "w", encoding="utf-8")
    try:
        fcntl.lockf(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        sys.exit(0)
    return lock


def atomic_write(text):
    os.makedirs(STATE_DIR, exist_ok=True)
    tmp_file = f"{STATE_FILE}.tmp"
    with open(tmp_file, "w", encoding="utf-8") as handle:
        handle.write(text)
        handle.write("\n")
    os.replace(tmp_file, STATE_FILE)


def text_value(ibus_text):
    if ibus_text is None:
        return ""
    try:
        return ibus_text.get_text() or ""
    except Exception:
        return ""


def clean_symbol(symbol):
    symbol = symbol.strip()
    if symbol.startswith("_"):
        symbol = symbol[1:]
    return symbol


def mode_from_label(label):
    match = re.search(r"\(([^()]*)\)\s*$", label)
    if not match:
        return ""
    return clean_symbol(match.group(1))


def mode_from_property(prop):
    key = prop.get_key()
    if key == "InputMode":
        symbol = clean_symbol(text_value(prop.get_symbol()))
        if symbol:
            return symbol
        return mode_from_label(text_value(prop.get_label()))

    if key in MODE_BY_KEY and prop.get_state() == IBus.PropState.CHECKED:
        return MODE_BY_KEY[key]

    sub_props = prop.get_sub_props()
    if sub_props is not None:
        return mode_from_prop_list(sub_props)

    return ""


def mode_from_prop_list(prop_list):
    index = 0
    while True:
        prop = prop_list.get(index)
        if prop is None:
            return ""
        mode = mode_from_property(prop)
        if mode:
            return mode
        index += 1


def deserialize_first_parameter(parameters):
    value = parameters.get_child_value(0)
    if value.get_type_string() == "v":
        value = value.get_variant()
    return IBus.Serializable.deserialize_object(value)


def handle_input_context_signal(_connection, _sender, _path, _interface, _signal, parameters, _data):
    try:
        obj = deserialize_first_parameter(parameters)
    except Exception:
        return

    mode = ""
    if isinstance(obj, IBus.Property):
        mode = mode_from_property(obj)
    elif isinstance(obj, IBus.PropList):
        mode = mode_from_prop_list(obj)

    if mode:
        atomic_write(mode)


def run():
    IBus.init()

    while True:
        bus = IBus.Bus()
        if not bus.is_connected():
            time.sleep(1)
            continue

        loop = GLib.MainLoop()
        connection = bus.get_connection()

        connection.signal_subscribe(
            None,
            "org.freedesktop.IBus.InputContext",
            None,
            None,
            None,
            Gio.DBusSignalFlags.NONE,
            handle_input_context_signal,
            None,
        )

        bus.connect("disconnected", lambda *_args: loop.quit())
        loop.run()
        time.sleep(1)


if __name__ == "__main__":
    lock_handle = take_lock()
    run()
