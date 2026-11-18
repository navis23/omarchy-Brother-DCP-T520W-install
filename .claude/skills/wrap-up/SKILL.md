---
name: wrap-up
description: End a Brother DCP-T520W installer work session cleanly before /clear. Verifies the repo, scripts and the live printer/scanner state, writes docs/handoff.md (state, what changed, next steps, open questions, gotchas, resume commands), commits and pushes it, then tells the user to run /clear and /resume. Use when the user says "wrap up", "handoff", "let's /clear", "end session", or before switching to a fresh session.
---

# Wrap up the session

Goal: a fresh session (with no memory of this conversation) can continue the work from `docs/handoff.md` alone,
together with `README.md` and the auto-memory. Write for that reader: concrete, current, no narrative.

This repo usually sits inside the `mbing-toolkit` parent folder as `brother-dcpt520w/`. All paths and commands
below are relative to this repo's root (two levels above this file): `cd` there first, and commit/push here, never
in the parent.

## 1. Collect the facts (don't write from memory; check)

Run these, in parallel where possible:

```bash
git status -sb && git log --oneline -15 && git remote -v | head -1
for f in *.sh; do bash -n "$f" && echo "$f: syntax ok"; done
command -v shellcheck >/dev/null && shellcheck *.sh | tail -20
pacman -Q cups sane brother-dcpt520w brscan5 2>&1
lpstat -p Brother-DCP-T520W -v Brother-DCP-T520W 2>&1
lpoptions -p Brother-DCP-T520W 2>&1 | grep -oE "printer-make-and-model='[^']*'"
scanimage -L 2>&1 | grep -i brother || echo "scanner not detected"
```

- These live checks describe *this* machine only. Say so in the handoff; whether the printer is plugged in changes
  the result.
- Note what was actually tested this session (real print, real scan, USB vs Wi-Fi, a full `./install.sh` run) and
  what was only syntax-checked. Never upgrade "syntax ok" to "works".
- Background processes you started this session (watchers, long scans): list and **stop** them.
- Read the previous `docs/handoff.md` (if it exists), so the new handoff carries forward anything still open.

## 2. Bring the docs up to date

- Behaviour or usage changes → `README.md` (usage, "What `install.sh` does", troubleshooting table).
- A newly found driver/packaging bug and its fix → a comment in `install.sh` at the fix *and* a troubleshooting row.

## 3. Write `docs/handoff.md`

Overwrite it using `handoff-template.md` (next to this file). Rules:
- Dates are absolute (YYYY-MM-DD). Commit hashes are short hashes that exist on the remote.
- "Next steps" is an ordered list. Step 1 is what the next session should actually do first, and why.
- Mark which next steps are **blocked on the user** (sudo password, plugging in / powering the printer, the
  printer's Wi-Fi IP, testing on another machine) vs doable right away.
- Keep it under ~100 lines; link to `README.md` instead of repeating it.
- Never put secrets in it (sudo password, Wi-Fi password, tokens). The printer's USB serial is fine to omit.

## 4. Commit and push

```bash
git add docs/ && git commit -m "Handoff: <one-line summary of the session>" && git push
```
End the commit message with the attribution lines from the system reminder, if any.
If there are other uncommitted changes, commit them first as their own commit with a proper message; don't fold
unrelated work into the handoff commit. Only push to `main` on
`https://github.com/navis23/omarchy-Brother-DCP-T520W-install`.

## 5. Tell the user

Reply briefly:
- what the session delivered (3–5 bullets),
- anything that needs their action,
- then: "Run `/clear`, then `/resume` to continue from `docs/handoff.md`."
