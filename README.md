# Brother DCP-T520W on Omarchy

One script to install and configure the **Brother DCP-T520W** printer on
[Omarchy](https://omarchy.org) (or any Arch Linux).

## Usage

```bash
git clone https://github.com/navis23/omarchy-Brother-DCP-T520W-install.git
cd omarchy-Brother-DCP-T520W-install

# Printer connected by USB (turn it on and plug it in first)
./fix-brother-printer.sh

# Or: printer on Wi-Fi (print the network report from the printer to get its IP)
./fix-brother-printer.sh 192.168.1.50
```

Then print a test page:

```bash
lp -d Brother-DCP-T520W /usr/share/cups/data/testprint
```

After this, the printer just works whenever it's connected; no further setup is needed.

## What the script does

1. Installs `cups`, `ghostscript`, `a2ps`, `lib32-glibc` and the AUR driver
   `brother-dcpt520w`, and enables the CUPS service.
2. **Fixes the AUR package**: it skips Brother's post-install step that
   symlinks the 64-bit filter binaries into `/opt/brother/Printers/dcpt520w/lpd/`.
   Without these links, jobs show **"completed" but nothing prints**.
3. Removes the duplicate `DCPT520W` queue the driver installer creates.
4. Creates the `Brother-DCP-T520W` queue (USB auto-detected, or Wi-Fi via
   `socket://IP:9100`), sets A4 paper, and makes it the default printer.

The script is safe to re-run (e.g. after reinstalling the driver or to switch
between USB and Wi-Fi).

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Job "completed" but nothing printed | Missing filter symlinks: re-run the script. |
| Queue shows driver "DYMO Label Printer" | Wrong driver was picked in the GUI: re-run the script. |
| `DCP-T520W not found on USB` | Printer off/unplugged, or pass its Wi-Fi IP instead. |
| `Enable [multilib]` error | Uncomment `[multilib]` in `/etc/pacman.conf`, run `sudo pacman -Sy`. |

## Requirements

- Arch-based system with `yay` (Omarchy ships it)
- `[multilib]` repository enabled (the Brother driver includes 32-bit tools)
