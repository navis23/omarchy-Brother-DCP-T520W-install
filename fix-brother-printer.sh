#!/usr/bin/env bash
# Install and configure the Brother DCP-T520W printer on Omarchy / Arch Linux.
#
# Installs Brother's official driver (AUR: brother-dcpt520w), repairs the
# missing binary symlinks the AUR package forgets, and creates a CUPS queue
# named "Brother-DCP-T520W" as the default printer with A4 paper.
#
# Usage:
#   ./fix-brother-printer.sh                # printer connected by USB (auto-detect)
#   ./fix-brother-printer.sh 192.168.1.50   # printer on Wi-Fi at that IP
#
# Safe to re-run at any time (e.g. after reinstalling the driver package).
set -euo pipefail

QUEUE="Brother-DCP-T520W"
IP="${1:-}"
BR=/opt/brother/Printers/dcpt520w/lpd

die() { echo "ERROR: $*" >&2; exit 1; }

# --- Prerequisites -----------------------------------------------------------
command -v yay >/dev/null || die "yay not found (needed to install from the AUR)."
grep -q '^\[multilib\]' /etc/pacman.conf \
  || die "Enable [multilib] in /etc/pacman.conf (driver needs lib32-glibc), then re-run."

echo "==> Installing CUPS + Brother DCP-T520W driver (asks for your sudo password)"
sudo pacman -S --needed --noconfirm cups ghostscript a2ps lib32-glibc
yay -S --needed --noconfirm brother-dcpt520w
sudo systemctl enable --now cups.service

# --- Fix the AUR package -----------------------------------------------------
# The AUR package skips Brother's rpm post-install step, which links the
# arch-specific binaries into lpd/. Without these the filter silently outputs
# nothing and CUPS marks jobs "completed" with no page printed.
ARCH=$([[ "$(uname -m)" == x86_64 ]] && echo x86_64 || echo i686)
echo "==> Linking Brother filter binaries ($ARCH)"
sudo ln -sf "$BR/$ARCH/brdcpt520wfilter"     "$BR/brdcpt520wfilter"
sudo ln -sf "$BR/$ARCH/brprintconf_dcpt520w" "$BR/brprintconf_dcpt520w"
sudo ln -sf "$BR/brprintconf_dcpt520w"       /usr/bin/brprintconf_dcpt520w

PPD="/usr/share/cups/model/Brother/brother_dcpt520w_printer_en.ppd"
[[ -f "$PPD" ]] || PPD="/usr/share/ppd/Brother/brother_dcpt520w_printer_en.ppd"
[[ -f "$PPD" ]] || die "Brother PPD not found after install."

# --- Find the printer --------------------------------------------------------
if [[ -n "$IP" ]]; then
  URI="socket://${IP}:9100"
else
  echo "==> Looking for the printer on USB (make sure it is plugged in and on)"
  URI=$(sudo lpinfo --include-schemes usb -v 2>/dev/null \
        | awk '/DCP-T520W/ {print $2; exit}')
  [[ -n "$URI" ]] || die "DCP-T520W not found on USB. Plug it in / power it on, or pass its Wi-Fi IP."
fi

# --- Create the queue --------------------------------------------------------
# The driver installer auto-creates a duplicate queue named DCPT520W; drop it.
sudo lpadmin -x DCPT520W 2>/dev/null || true

echo "==> Creating queue $QUEUE -> $URI"
sudo cancel -a "$QUEUE" 2>/dev/null || true
sudo lpadmin -x "$QUEUE" 2>/dev/null || true
sudo lpadmin -p "$QUEUE" -E -v "$URI" -P "$PPD" \
  -D "Brother DCP-T520W" -o PageSize=A4
sudo lpadmin -d "$QUEUE"
sudo systemctl restart cups

echo "==> Done."
lpstat -p "$QUEUE" -v "$QUEUE"
echo
echo "Print a test page with:  lp -d $QUEUE /usr/share/cups/data/testprint"
