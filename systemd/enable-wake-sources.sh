#!/bin/sh

set -eu

set_wakeup() {
    path=$1
    label=$2
    value=$3

    if [ -e "$path" ]; then
        printf '%s wake: %s (%s)\n' "$value" "$label" "$path"
        printf '%s\n' "$value" > "$path"
    else
        printf 'missing wake path: %s (%s)\n' "$label" "$path"
    fi
}

set_mem_sleep() {
    value=$1

    if [ -w /sys/power/mem_sleep ]; then
        printf 'setting mem_sleep=%s\n' "$value"
        printf '%s\n' "$value" > /sys/power/mem_sleep
    else
        printf 'missing or unwritable: /sys/power/mem_sleep\n'
    fi
}

bluetooth_wake=${ENABLE_BLUETOOTH_WAKE:-0}

# Internal keyboard wake works on this laptop with s2idle, not deep/S3.
set_mem_sleep s2idle

# Keep the safe built-in wake sources enabled first. Broad USB/Bluetooth wake
# caused immediate resume on this laptop, so those stay disabled by default.
set_wakeup /sys/devices/platform/i8042/serio0/power/wakeup "internal keyboard" enabled
set_wakeup /sys/devices/platform/i8042/serio1/power/wakeup "TrackPoint" enabled
set_wakeup /sys/devices/platform/INTC1051:00/power/wakeup "Intel HID events" enabled

case "$bluetooth_wake" in
    1|yes|true|on)
        set_wakeup /sys/devices/pci0000:00/0000:00:14.0/usb3/power/wakeup "USB2 root hub" enabled
        bluetooth_value=enabled
        ;;
    *)
        set_wakeup /sys/devices/pci0000:00/0000:00:14.0/usb3/power/wakeup "USB2 root hub" disabled
        bluetooth_value=disabled
        ;;
esac

for device in /sys/bus/usb/devices/*; do
    [ -r "$device/idVendor" ] || continue
    [ -r "$device/idProduct" ] || continue
    vendor=$(cat "$device/idVendor")
    product=$(cat "$device/idProduct")

    case "$vendor:$product" in
        8087:0026)
            set_wakeup "$device/power/wakeup" "Intel Bluetooth controller" "$bluetooth_value"
            ;;
    esac
done
