---
name: resume
description: Start a fresh Brother DCP-T520W installer session from where the last one stopped. Reads docs/handoff.md and README.md, checks the repo and the live printer/scanner state are as described, reports a short status, then continues with the first next step. Use at the start of a new session, after /clear, or when the user says "resume", "continue", "where were we".
---

# Resume work

This repo usually sits inside the `mbing-toolkit` parent folder as `brother-dcpt520w/`. All paths and commands
below are relative to this repo's root (two levels above this file): `cd` there first, and run git here, never in
the parent.

## 1. Read (in this order)
1. `docs/handoff.md`: the source of truth for state and next steps. If it's missing, say so and fall back to
   `git log --oneline -20` and `README.md`.
2. `README.md`: what `install.sh` does, the known driver bugs it fixes, troubleshooting.
3. `install.sh`, if the next step touches it.

The auto-memory (user preferences) is already loaded; follow it.

## 2. Verify the handoff is still true (quick, in parallel)

```bash
git fetch -q && git status -sb && git log --oneline -5
for f in *.sh; do bash -n "$f" && echo "$f: syntax ok"; done
pacman -Q brother-dcpt520w brscan5 2>&1
lpstat -p Brother-DCP-T520W -v Brother-DCP-T520W 2>&1
scanimage -L 2>&1 | grep -i brother || echo "scanner not detected"
```
- If the printer/scanner checks differ from the handoff, first ask whether it's simply unplugged or off before
  treating it as a regression.
- If anything else differs from the handoff (new commits, changed scripts), say so before continuing.

## 3. Report, then continue

Give the user a short status (4–6 lines): where things stand, what's blocked on them, and the step you're starting.
Then **start the first unblocked next step** from the handoff. Don't wait for confirmation unless the step is
outward-facing or irreversible (pushing, rewriting pushed history), or it needs sudo / physical access to the printer.

## Working conventions to keep
- Claude can't run `sudo` here (it needs the user's password). Read-only checks run directly; anything needing root
  goes to the user as a ready-to-paste `! <command>` (or "run `./install.sh`"), then verify the result yourself.
- Before blaming the driver, diagnose with evidence: `lpstat -t`, `/var/log/cups/error_log`, the queue's
  `printer-make-and-model`, USB presence under `/sys/bus/usb/devices`, `udevadm info` on the device node.
- Keep `install.sh` idempotent and generic (no machine-specific serials); comment each workaround with why.
- Test print / test scan before calling a fix done; say what was only syntax-checked.
- Commit in small, verified steps and push to `main`; use the attribution lines from the system reminder.
- Before ending, run `/wrap-up`.
