#!/usr/bin/env python3
# Scratchpad helper, started from autostart.toml:
# - Hide a scratchpad when its last visible window closes, so it doesn't stay
#   "shown" and empty (e.g. after typing `exit` in the drop-down terminal).
# - Resize and re-center a scratchpad window each time it's shown, since Umbriel
#   keeps its creation-time size and a scaled offset on a different monitor.
import json
import subprocess

# Fractions of the monitor; keep in sync with default_floating_size in rules.toml.
WIDTH = 0.4
HEIGHT = 0.45

def msg(action):
    subprocess.run(["umbriel", "msg", action])

def visible_scratchpads(windows):
    # scratchpad name -> ids of its windows currently shown
    shown = {}
    for w in windows:
        if w.get("scratchpad") and w.get("visible"):
            shown.setdefault(w["scratchpad"], set()).add(w["id"])
    return shown

def main():
    proc = subprocess.Popen(["umbriel", "subscribe", "windows"],
                            stdout=subprocess.PIPE, text=True)
    before = {}
    for line in proc.stdout:
        try:
            windows = json.loads(line)["data"]
        except (ValueError, KeyError):
            continue
        ids = {w["id"] for w in windows}
        now = visible_scratchpads(windows)
        for name, shown in before.items():
            closed = shown - ids
            # A shown window closed and nothing else in that scratchpad is shown.
            if closed and not now.get(name):
                msg(f"scratchpad-toggle:{name}")

        # Newly shown: these actions act on the focused window, so focus it first.
        was_shown = set().union(*before.values())
        for wid in set().union(*now.values()) - was_shown:
            msg(f"window-focus:{wid}")
            msg(f"window-set-primary-extent:{WIDTH}")
            msg(f"window-set-secondary-extent:{HEIGHT}")
            msg("window-center")
        before = now

if __name__ == "__main__":
    main()
