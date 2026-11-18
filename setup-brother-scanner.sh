#!/usr/bin/env bash
# Set up the scanner of the Brother DCP-T520W on Omarchy / Arch Linux.
#
# Installs SANE + Brother's brscan5 driver (AUR) + Document Scanner
# (simple-scan) as a GUI, and makes the scanner usable without root.
#
# Usage:
#   ./setup-brother-scanner.sh                # scanner connected by USB
#   ./setup-brother-scanner.sh 192.168.1.50   # scanner on Wi-Fi at that IP
#
# Safe to re-run at any time.
set -euo pipefail

IP="${1:-}"
NAME="DCP-T520W"

die() { echo "ERROR: $*" >&2; exit 1; }

command -v yay >/dev/null || die "yay not found (needed to install from the AUR)."

echo "==> Installing SANE, Brother brscan5 driver and Document Scanner (asks for sudo)"
sudo pacman -S --needed --noconfirm sane libusb-compat simple-scan
yay -S --needed --noconfirm brscan5

# brscan5's own udev rule never matches (it compares bInterfaceClass to "0ff"
# while sysfs reports "ff", and checks interface attributes on the device
# node). Without libsane_matched the device stays root:lp and SANE can't open
# it, so scanimage -L shows nothing. Tag the DCP-T520W (04f9:0476) ourselves;
# 70-uaccess.rules then grants the logged-in desktop user access.
echo "==> Installing udev rule for scanner access"
echo 'SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="04f9", ATTR{idProduct}=="0476", ENV{libsane_matched}="yes"' \
  | sudo tee /etc/udev/rules.d/60-brother-dcpt520w-scanner.rules >/dev/null

# Re-apply rules so an already-plugged-in scanner works without replugging.
echo "==> Reloading udev rules"
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=usb --attr-match=idVendor=04f9

if [[ -n "$IP" ]]; then
  echo "==> Registering network scanner $NAME at $IP"
  sudo brsaneconfig5 -r "$NAME" >/dev/null 2>&1 || true
  sudo brsaneconfig5 -a name="$NAME" model="$NAME" ip="$IP"
fi

echo "==> Detected scanners:"
sleep 1
scanimage -L || true
echo
echo "Scan with the 'Document Scanner' app, or from a terminal:"
echo "  scanimage --format=png --resolution 300 -o scan.png"
