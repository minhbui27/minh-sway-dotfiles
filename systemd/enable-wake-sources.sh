#!/bin/sh

set -eu

enable_wakeup() {
    path=$1
    label=$2

    if [ -e "$path" ]; then
        printf 'enabling wake: %s (%s)\n' "$label" "$path"
        printf 'enabled\n' > "$path"
    else
        printf 'missing wake path: %s (%s)\n' "$label" "$path"
    fi
}

enable_wakeup /sys/devices/platform/i8042/serio0/power/wakeup "internal keyboard"
enable_wakeup /sys/devices/platform/i8042/serio1/power/wakeup "TrackPoint"
enable_wakeup /sys/devices/platform/INTC1051:00/power/wakeup "Intel HID events"
enable_wakeup /sys/devices/pci0000:00/0000:00:14.0/power/wakeup "XHCI USB controller"
enable_wakeup /sys/devices/pci0000:00/0000:00:14.0/usb3/power/wakeup "USB2 root hub"

for device in /sys/bus/usb/devices/*; do
    [ -r "$device/idVendor" ] || continue
    [ -r "$device/idProduct" ] || continue
    vendor=$(cat "$device/idVendor")
    product=$(cat "$device/idProduct")

    case "$vendor:$product" in
        8087:0026)
            enable_wakeup "$device/power/wakeup" "Intel Bluetooth controller"
            ;;
    esac
done
