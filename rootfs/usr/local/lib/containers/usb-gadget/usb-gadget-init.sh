#!/bin/sh
# USB Gadget Ethernet Setup for Raspberry Pi 4
# Runs as Talos extension service at boot

set -e

GADGET_DIR="/sys/kernel/config/usb_gadget/talos"

# Find UDC (USB Device Controller)
if [ -d /sys/class/udc ]; then
    UDC=$(ls /sys/class/udc 2>/dev/null | head -1)
fi

if [ -z "$UDC" ]; then
    echo "No UDC found - dwc2 may not be in peripheral mode"
    echo "Ensure extraKernelArgs includes: dwc2.dr_mode=peripheral"
    exit 1
fi

# Check if already configured
if [ -d "$GADGET_DIR" ]; then
    echo "USB gadget already configured"
    exit 0
fi

echo "Configuring USB Ethernet gadget on $UDC..."

# Mount configfs if needed
if [ -d /sys/kernel/config ] && ! mountpoint -q /sys/kernel/config 2>/dev/null; then
    mount -t configfs none /sys/kernel/config || true
fi

# Create gadget
mkdir -p "$GADGET_DIR"
cd "$GADGET_DIR"

# USB Device Descriptor
echo 0x1d6b > idVendor   # Linux Foundation
echo 0x0104 > idProduct  # Multifunction Composite Gadget
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

# Strings
mkdir -p strings/0x409
echo "talos-rpi4" > strings/0x409/serialnumber
echo "Talos" > strings/0x409/manufacturer
echo "USB Ethernet" > strings/0x409/product

# Configuration
mkdir -p configs/c.1/strings/0x409
echo "ECM" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower

# ECM function
mkdir -p functions/ecm.usb0
ln -sf functions/ecm.usb0 configs/c.1/

# Activate
echo "$UDC" > UDC

echo "USB gadget configured - usb0 interface available"
