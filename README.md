# Brother DCP-T520W on Omarchy

One script to install and configure the **Brother DCP-T520W** printer and scanner
on [Omarchy](https://omarchy.org) (or any Arch Linux).

## Usage

```bash
git clone https://github.com/navis23/omarchy-Brother-DCP-T520W-install.git
cd omarchy-Brother-DCP-T520W-install

# Turn the printer on and plug in the USB cable first, then:
./install.sh

# Or over Wi-Fi (print the network report from the printer to get its IP):
./install.sh 192.168.1.50
```

Test them:

```bash
lp -d Brother-DCP-T520W /usr/share/cups/data/testprint     # print a test page
scanimage -L                                               # should list "Brother DCP-T520W"
scanimage --format=png --resolution 300 -o scan.png        # scan to a file
```

For everyday scanning, open the **Document Scanner** app (installed by the script).

After setup, printing and scanning just work whenever the device is connected;
no further setup is needed. The script is safe to re-run.

## What `install.sh` does

**Packages:** `cups`, `ghostscript`, `a2ps`, `lib32-glibc`, `sane`,
`libusb-compat`, `simple-scan` (Document Scanner), and the AUR drivers
`brother-dcpt520w` (printer) and `brscan5` (scanner; `brscan4` does not
support this model). Enables the CUPS service.

**Printer:**

1. **Fixes the AUR package**: it skips Brother's post-install step that
   symlinks the 64-bit filter binaries into `/opt/brother/Printers/dcpt520w/lpd/`.
   Without these links, jobs show **"completed" but nothing prints**.
2. Removes the duplicate `DCPT520W` queue the driver installer creates.
3. Creates the `Brother-DCP-T520W` queue (USB auto-detected, or Wi-Fi via
   `socket://IP:9100`), sets A4 paper, and makes it the default printer.

**Scanner:**

1. **Fixes USB access**: brscan5's own udev rule never matches (it compares
   the interface class to `0ff` while Linux reports `ff`), so the scanner stays
   `root:lp` and isn't detected. The script adds
   `/etc/udev/rules.d/60-brother-dcpt520w-scanner.rules`, which tags USB ID
   `04f9:0476` so the logged-in user can use it.
2. For Wi-Fi, registers the scanner with `brsaneconfig5`.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Print job "completed" but nothing printed | Missing filter symlinks: re-run `install.sh`. |
| Queue shows driver "DYMO Label Printer" | Wrong driver was picked in the GUI: re-run `install.sh`. |
| `DCP-T520W not found on USB` | Printer off/unplugged, or pass its Wi-Fi IP instead. |
| `scanimage -L` shows only the webcam | Missing udev rule: re-run `install.sh`, or replug the USB cable. |
| `Enable [multilib]` error | Uncomment `[multilib]` in `/etc/pacman.conf`, run `sudo pacman -Sy`. |

## Requirements

- Arch-based system with `yay` (Omarchy ships it)
- `[multilib]` repository enabled (the printer driver includes 32-bit tools)
