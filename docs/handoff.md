# Handoff — 2026-11-18

> Written by `/wrap-up` for the next session. Start with `/resume`.

## Snapshot
- Branch: `main` @ `463ab70` + this handoff commit, pushed — github.com/navis23/omarchy-Brother-DCP-T520W-install
- Scripts: `install.sh` syntax ok (`bash -n`); shellcheck not installed, not run.
- This machine (at wrap-up, printer **unplugged/off**, so not on USB):
  - packages: `cups 2.4.20`, `sane 1.4.0`, `brother-dcpt520w 3.5.0-1`, `brscan5 1.7.0_0-1` installed
  - printer queue `Brother-DCP-T520W`: driver `Brother DCPT520W CUPS`, USB URI, idle, default printer
  - scanner: not detected at wrap-up (device unplugged); detected and scanned earlier the same day
  - fixes in place: filter symlinks under `/opt/brother/Printers/dcpt520w/lpd/`,
    `/etc/udev/rules.d/60-brother-dcpt520w-scanner.rules`
- Tested for real this session (all over **USB**):
  - real print: user confirmed a test page printed after the symlink fix
  - real scan: `scanimage -d 'brother5:bus1;dev3' --resolution 100` gave a full A4 PNG (842×1161)
  - the separate scripts `fix-brother-printer.sh` and `setup-brother-scanner.sh` were run by the user and worked
- Only syntax-checked: the combined `install.sh` (never run end to end), the USB auto-detect of the printer URI,
  the `udevadm trigger --attr-match` step inside it, and **all Wi-Fi paths** (`socket://IP:9100`, `brsaneconfig5`).
- Running processes left behind: none.

## What exists now
- `install.sh`: one idempotent script that installs printer + scanner on Omarchy/Arch over USB (auto-detect) or Wi-Fi
  (`./install.sh <ip>`). See `README.md` for exactly what it does and troubleshooting.
- It works around three driver bugs (each commented in `install.sh`):
  1. a queue created in the GUI with the **"DYMO Label Printer"** driver (original cause: jobs complete, no print);
  2. AUR `brother-dcpt520w` omits Brother's rpm post-install symlinks to `lpd/x86_64/*` (filter outputs nothing);
  3. brscan5's udev rule never matches (`"0ff"` vs sysfs `"ff"`), so the scanner stays `root:lp` and is invisible.
- `brscan4` does **not** support the DCP-T520W (stops at T510W); `brscan5` does. The printer has no IPP-over-USB, so
  driverless (`ipp-usb` / `sane-airscan`) is not an option over USB.
- Project skills `/wrap-up` and `/resume` in `.claude/skills/`.

## This session
- `c00f900` printer installer (Brother driver, symlink fix, A4 default queue)
- `414cfb1` scanner setup (brscan5, simple-scan, udev rule)
- `bfafc72` both merged into `install.sh`; old scripts removed
- `463ab70` `/wrap-up` and `/resume` skills (adapted from `~/Dev/running-app`)

## In progress / unfinished
- None in code. The combined `install.sh` has not been run end to end yet.

## Next steps (in order)
1. Run `./install.sh` once on this machine with the printer plugged in, then a test print and
   `scanimage -L`. This proves the combined script (auto-detect + udev trigger) before anyone relies on it on a new
   machine. — **blocked on user** (sudo password, printer plugged in and on)
2. Unplug and replug the USB cable, then `scanimage -L` again: confirms the udev rule works on a real hot-plug, not
   only via `udevadm trigger`. — **blocked on user** (physical access)
3. If Wi-Fi is wanted: get the printer's IP (print its network report), run `./install.sh <ip>`, test print + scan.
   Unverified: whether `brsaneconfig5` accepts `model="DCP-T520W"`; if it doesn't, list the accepted names with
   `brsaneconfig5 -q` and adjust `install.sh`. — **blocked on user** (IP, sudo)
4. Optional: `sudo pacman -S shellcheck` and fix anything it reports in `install.sh`. — doable after user installs it

## Waiting on the user
- Steps 1–3 above: sudo runs, plugging in the printer, the printer's Wi-Fi IP.

## Environment & gotchas
- Claude can't run `sudo` here (needs the user's password). Hand over `! <command>` or "run `./install.sh`", then
  verify the result yourself with read-only checks.
- Re-running `install.sh` deletes and recreates the `Brother-DCP-T520W` queue and cancels its pending jobs.
- CUPS reports "completed" even when the filter produced nothing. Check the filter, not the job status.
- `lpinfo -v` as a normal user returns *Forbidden*; use `sudo lpinfo` (the script does) or look in
  `/sys/bus/usb/devices` (Brother vendor `04f9`, DCP-T520W product `0476`).
- The scanner's SANE device name includes the USB bus/dev number (`brother5:bus1;devN`) and changes on replug;
  use `scanimage -L` to get the current one.
- The CUPS log shows harmless `CreateProfile failed ... not activatable` warnings (no colord); ignore them.

## Resume commands
```bash
git status -sb && git log --oneline -5
for d in /sys/bus/usb/devices/*; do [ "$(cat $d/idVendor 2>/dev/null)" = 04f9 ] && cat $d/product; done
lpstat -p Brother-DCP-T520W -v Brother-DCP-T520W
scanimage -L
```
