#!/usr/bin/env python3
# Scratchpad helper, started from cfg/general.toml:
# - Hide a scratchpad when its last visible window closes, so it doesn't stay
#   "shown" and empty (e.g. after typing `exit` in the drop-down terminal).
# - Resize and re-center a scratchpad window each time it's shown, since Umbriel
#   keeps its creation-time size and a scaled offset on a different monitor.
import json
import subprocess
import time

# Fractions of the monitor; keep in sync with default_floating_size in rules.toml.
WIDTH = 0.4
HEIGHT = 0.45

def msg(action):
    subprocess.run(["umbriel", "msg", action])

def active_id():
    # id of the window that currently has focus, from a one-off snapshot
    proc = subprocess.Popen(["umbriel", "subscribe", "windows"],
                            stdout=subprocess.PIPE, text=True)
    try:
        windows = json.loads(proc.stdout.readline())["data"]
    except (ValueError, KeyError):
        return None
    finally:
        proc.kill()
    return next((w["id"] for w in windows if w.get("active")), None)

def focused_on(wid, tries=10):
    # The resize actions act on whatever is focused, so only run them once the
    # scratchpad window really has focus; otherwise they'd resize a tiled column.
    for _ in range(tries):
        if active_id() == wid:
            return True
        time.sleep(0.05)
    return False

def visible_scratchpads(windows):
    # scratchpad name -> ids of its windows currently shown
    shown = {}
    for w in windows:
        if w.get("scratchpad") and w.get("visible"):
            shown.setdefault(w["scratchpad"], set()).add(w["id"])
    return shown

def outputs_of(windows):
    # id -> output of each shown scratchpad window
    return {w["id"]: w["output"] for w in windows
            if w.get("scratchpad") and w.get("visible")}

def main():
    proc = subprocess.Popen(["umbriel", "subscribe", "windows"],
                            stdout=subprocess.PIPE, text=True)
    before = {}
    outputs_before = {}
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

        # Newly shown, or moved to another monitor (toggling it from the other
        # monitor moves it instead of hiding it). These actions act on the
        # focused window, so focus it first.
        outputs_now = outputs_of(windows)
        to_fit = {wid for wid, out in outputs_now.items()
                  if outputs_before.get(wid) != out}
        for wid in to_fit:
            msg(f"window-focus:{wid}")
            for action in (f"window-set-primary-extent:{WIDTH}",
                           f"window-set-secondary-extent:{HEIGHT}",
                           "window-center"):
                if not focused_on(wid):
                    break
                msg(action)
        before = now
        outputs_before = outputs_now

if __name__ == "__main__":
    main()
