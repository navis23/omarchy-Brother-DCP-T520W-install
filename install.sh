#!/usr/bin/env bash
# Install the Brother DCP-T520W printer + scanner on Omarchy / Arch Linux.
#
# Usage:
#   ./install.sh                 # printer connected by USB (auto-detect)
#   ./install.sh 192.168.1.50    # printer on Wi-Fi at that IP
#
# Safe to re-run at any time (e.g. after reinstalling a driver package or to
# switch between USB and Wi-Fi).
set -euo pipefail

IP="${1:-}"
QUEUE="Brother-DCP-T520W"
MODEL="DCP-T520W"
BR=/opt/brother/Printers/dcpt520w/lpd

die() { echo "ERROR: $*" >&2; exit 1; }

# --- Prerequisites -----------------------------------------------------------
command -v yay >/dev/null || die "yay not found (needed to install from the AUR)."
grep -q '^\[multilib\]' /etc/pacman.conf \
  || die "Enable [multilib] in /etc/pacman.conf (printer driver needs lib32-glibc), then re-run."

# --- Packages ----------------------------------------------------------------
echo "==> Installing packages (asks for your sudo password)"
sudo pacman -S --needed --noconfirm \
  cups ghostscript a2ps lib32-glibc \
  sane libusb-compat simple-scan
yay -S --needed --noconfirm brother-dcpt520w brscan5
sudo systemctl enable --now cups.service

# =============================================================================
# PRINTER
# =============================================================================

# The AUR package skips Brother's rpm post-install step, which links the
# arch-specific binaries into lpd/. Without these the filter silently outputs
# nothing and CUPS marks jobs "completed" with no page printed.
ARCH=$([[ "$(uname -m)" == x86_64 ]] && echo x86_64 || echo i686)
echo "==> [printer] Linking Brother filter binaries ($ARCH)"
sudo ln -sf "$BR/$ARCH/brdcpt520wfilter"     "$BR/brdcpt520wfilter"
sudo ln -sf "$BR/$ARCH/brprintconf_dcpt520w" "$BR/brprintconf_dcpt520w"
sudo ln -sf "$BR/brprintconf_dcpt520w"       /usr/bin/brprintconf_dcpt520w

PPD="/usr/share/cups/model/Brother/brother_dcpt520w_printer_en.ppd"
[[ -f "$PPD" ]] || PPD="/usr/share/ppd/Brother/brother_dcpt520w_printer_en.ppd"
[[ -f "$PPD" ]] || die "Brother PPD not found after install."

if [[ -n "$IP" ]]; then
  URI="socket://${IP}:9100"
else
  echo "==> [printer] Looking for $MODEL on USB (must be plugged in and on)"
  URI=$(sudo lpinfo --include-schemes usb -v 2>/dev/null \
        | awk -v m="$MODEL" '$0 ~ m {print $2; exit}')
  [[ -n "$URI" ]] || die "$MODEL not found on USB. Plug it in / power it on, or pass its Wi-Fi IP."
fi

# The driver installer auto-creates a duplicate queue named DCPT520W; drop it.
sudo lpadmin -x DCPT520W 2>/dev/null || true

echo "==> [printer] Creating queue $QUEUE -> $URI"
sudo cancel -a "$QUEUE" 2>/dev/null || true
sudo lpadmin -x "$QUEUE" 2>/dev/null || true
sudo lpadmin -p "$QUEUE" -E -v "$URI" -P "$PPD" \
  -D "Brother DCP-T520W" -o PageSize=A4
sudo lpadmin -d "$QUEUE"
sudo systemctl restart cups

# =============================================================================
# SCANNER
# =============================================================================

# brscan5's own udev rule never matches (it compares bInterfaceClass to "0ff"
# while sysfs reports "ff", and checks interface attributes on the device
# node). Without libsane_matched the device stays root:lp and SANE can't open
# it, so scanimage -L shows nothing. Tag the DCP-T520W (04f9:0476) ourselves;
# 70-uaccess.rules then grants the logged-in desktop user access.
echo "==> [scanner] Installing udev rule for USB access"
echo 'SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="04f9", ATTR{idProduct}=="0476", ENV{libsane_matched}="yes"' \
  | sudo tee /etc/udev/rules.d/60-brother-dcpt520w-scanner.rules >/dev/null
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=usb --attr-match=idVendor=04f9

if [[ -n "$IP" ]]; then
  echo "==> [scanner] Registering network scanner $MODEL at $IP"
  sudo brsaneconfig5 -r "$MODEL" >/dev/null 2>&1 || true
  sudo brsaneconfig5 -a name="$MODEL" model="$MODEL" ip="$IP"
fi

# =============================================================================
# SUMMARY
# =============================================================================
echo
echo "==> Printer:"
lpstat -p "$QUEUE" -v "$QUEUE"
echo
echo "==> Scanner:"
sleep 1
scanimage -L 2>/dev/null | grep -i brother || echo "  (not detected yet; replug the USB cable and run: scanimage -L)"
echo
echo "Test print:  lp -d $QUEUE /usr/share/cups/data/testprint"
echo "Scan:        open 'Document Scanner', or  scanimage --format=png --resolution 300 -o scan.png"
