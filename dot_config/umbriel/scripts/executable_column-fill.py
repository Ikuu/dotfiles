#!/usr/bin/env python3
# Widen the focused column to fill the space left by the other columns fully on
# screen (Niri's expand-column-to-available-width). Bound in keybinds.toml.
#
# Umbriel sizes a column as  width = fraction * (usable - GAP) - SLOT_EXTRA,
# so each column takes up (width + SLOT_EXTRA) of (usable - GAP).
import json
import re
import subprocess

GAP = 8                  # layout.gap
SLOT_EXTRA = GAP + 2 * 2  # layout.gap + 2 * appearance.border_width

def msg(*action):
    # e.g. msg("window-focus", wid): action name, then its word arguments
    subprocess.run(["umbriel", "msg", *map(str, action)])

def usable_areas():
    # output name -> (x, width) of its usable area
    out = subprocess.run(["umbriel", "outputs"], capture_output=True, text=True).stdout
    areas, name = {}, None
    for line in out.splitlines():
        if line and not line.startswith(" "):
            name = line.split()[0]
        m = re.search(r"Usable area: (\d+)x\d+\+(-?\d+)\+", line)
        if m and name:
            areas[name] = (int(m.group(2)), int(m.group(1)))
    return areas

def current_windows():
    proc = subprocess.Popen(["umbriel", "subscribe", "windows"],
                            stdout=subprocess.PIPE, text=True)
    try:
        return json.loads(proc.stdout.readline())["data"]
    finally:
        proc.kill()

def main():
    windows = current_windows()
    focused = next((w for w in windows if w.get("active")), None)
    if not focused or focused["floating"] or focused["column"] < 0:
        return
    out_x, usable = usable_areas()[focused["output"]]

    def on_screen(ws):
        return [w for w in ws
                if w["workspace"] == focused["workspace"] and not w["floating"]
                and w["column"] >= 0
                and w["x"] >= out_x and w["x"] + w["w"] <= out_x + usable]

    # Width of each column fully on screen in the focused workspace.
    visible = on_screen(windows)
    columns = {}
    for w in visible:
        columns[w["column"]] = max(columns.get(w["column"], 0), w["w"])
    columns[focused["column"]] = focused["w"]

    space = usable - GAP
    free = space - sum(width + SLOT_EXTRA for width in columns.values())
    if free <= 0:
        return
    fraction = (focused["w"] + SLOT_EXTRA + free) / space
    msg("window-set-primary-extent", f"{fraction:.5f}")

    # The view doesn't scroll after a resize, so a neighbour can end up partly
    # off screen. Focusing it scrolls it back in; then return focus.
    still_visible = {w["id"] for w in on_screen(current_windows())}
    pushed_out = [w for w in visible if w["id"] not in still_visible]
    for w in pushed_out:
        msg("window-focus", w["id"])
    if pushed_out:
        msg("window-focus", focused["id"])

if __name__ == "__main__":
    main()
