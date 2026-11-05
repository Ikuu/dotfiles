#!/usr/bin/env python3
# Fullscreen helper, started from cfg/general.toml:
# A window that goes fullscreen soon after it opens (games, borderless
# fullscreen, video players started fullscreen) is moved to the empty
# workspace at the end of its monitor, so it doesn't sit on top of a workspace
# with other windows. Umbriel's window rules can't match on fullscreen, hence
# this script.
#
# Only new windows are moved: going fullscreen later (Mod+F, a browser video)
# leaves the window where it is. Each window is moved at most once.
import json
import subprocess
import time

GRACE = 60  # seconds after a window opens during which fullscreen moves it

def msg(*action):
    subprocess.run(["umbriel", "msg", *map(str, action)])

def snapshot(event):
    # One-off copy of an event's current data
    proc = subprocess.Popen(["umbriel", "subscribe", event],
                            stdout=subprocess.PIPE, text=True)
    try:
        return json.loads(proc.stdout.readline())["data"]
    except (ValueError, KeyError):
        return []
    finally:
        proc.kill()

def focused_on(wid, tries=10):
    # window-move-to-workspace acts on the focused window, so wait for it
    for _ in range(tries):
        if any(w["id"] == wid and w.get("active") for w in snapshot("windows")):
            return True
        time.sleep(0.05)
    return False

def move_to_empty(win):
    workspaces = snapshot("workspaces")
    here = next((ws for ws in workspaces if ws["id"] == win["workspace"]), None)
    if here is None or here["window_count"] <= 1:
        return  # Already alone (or unknown workspace)
    empty = [ws for ws in workspaces
             if ws["output"] == win["output"] and not ws["occupied"]]
    if not empty:
        return
    target = max(empty, key=lambda ws: ws["index"])
    msg("window-focus", win["id"])
    if focused_on(win["id"]):
        msg("window-move-to-workspace", target["index"], "--output", win["output"])

def main():
    proc = subprocess.Popen(["umbriel", "subscribe", "windows"],
                            stdout=subprocess.PIPE, text=True)
    opened = {}     # id -> time first seen
    handled = set()  # ids already moved (or past their grace period)
    first = True
    for line in proc.stdout:
        try:
            windows = json.loads(line)["data"]
        except (ValueError, KeyError):
            continue
        now = time.monotonic()
        ids = set()
        for w in windows:
            wid = w["id"]
            ids.add(wid)
            if wid not in opened:
                opened[wid] = now
                if first:
                    handled.add(wid)  # Already open when the script started
            if wid in handled:
                continue
            if now - opened[wid] > GRACE:
                handled.add(wid)
                continue
            if w.get("fullscreen") and w.get("workspace") and not w.get("scratchpad"):
                handled.add(wid)
                move_to_empty(w)
        first = False
        # Forget closed windows
        for wid in set(opened) - ids:
            opened.pop(wid, None)
            handled.discard(wid)

if __name__ == "__main__":
    main()
