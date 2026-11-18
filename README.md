# Brother DCP-T520W on Omarchy

Scripts to install and configure the **Brother DCP-T520W** printer and scanner
on [Omarchy](https://omarchy.org) (or any Arch Linux).

## Usage

```bash
git clone https://github.com/navis23/omarchy-Brother-DCP-T520W-install.git
cd omarchy-Brother-DCP-T520W-install

# Turn the printer on and plug in the USB cable first, then:
./fix-brother-printer.sh     # printer
./setup-brother-scanner.sh   # scanner

# Or over Wi-Fi (print the network report from the printer to get its IP):
./fix-brother-printer.sh 192.168.1.50
./setup-brother-scanner.sh 192.168.1.50
```

Test them:

```bash
lp -d Brother-DCP-T520W /usr/share/cups/data/testprint     # print a test page
scanimage -L                                               # should list "Brother DCP-T520W"
scanimage --format=png --resolution 300 -o scan.png        # scan to a file
```

For everyday scanning, open the **Document Scanner** app (installed by the script).

After setup, both just work whenever the device is connected; no further setup is needed.
Both scripts are safe to re-run.

## What `fix-brother-printer.sh` does

1. Installs `cups`, `ghostscript`, `a2ps`, `lib32-glibc` and the AUR driver
   `brother-dcpt520w`, and enables the CUPS service.
2. **Fixes the AUR package**: it skips Brother's post-install step that
   symlinks the 64-bit filter binaries into `/opt/brother/Printers/dcpt520w/lpd/`.
   Without these links, jobs show **"completed" but nothing prints**.
3. Removes the duplicate `DCPT520W` queue the driver installer creates.
4. Creates the `Brother-DCP-T520W` queue (USB auto-detected, or Wi-Fi via
   `socket://IP:9100`), sets A4 paper, and makes it the default printer.

## What `setup-brother-scanner.sh` does

1. Installs `sane`, `libusb-compat`, `simple-scan` (Document Scanner) and the
   AUR driver `brscan5` (Brother's scanner driver for this model; `brscan4`
   does not support it).
2. **Fixes USB access**: brscan5's own udev rule never matches (it compares
   the interface class to `0ff` while Linux reports `ff`), so the scanner stays
   `root:lp` and isn't detected. The script adds
   `/etc/udev/rules.d/60-brother-dcpt520w-scanner.rules`, which tags USB ID
   `04f9:0476` so the logged-in user can use it.
3. For Wi-Fi, registers the scanner with `brsaneconfig5`.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Print job "completed" but nothing printed | Missing filter symlinks: re-run `fix-brother-printer.sh`. |
| Queue shows driver "DYMO Label Printer" | Wrong driver was picked in the GUI: re-run `fix-brother-printer.sh`. |
| `DCP-T520W not found on USB` | Printer off/unplugged, or pass its Wi-Fi IP instead. |
| `scanimage -L` shows only the webcam | Missing udev rule: re-run `setup-brother-scanner.sh`, or replug the USB cable. |
| `Enable [multilib]` error | Uncomment `[multilib]` in `/etc/pacman.conf`, run `sudo pacman -Sy`. |

## Requirements

- Arch-based system with `yay` (Omarchy ships it)
- `[multilib]` repository enabled (the printer driver includes 32-bit tools)
