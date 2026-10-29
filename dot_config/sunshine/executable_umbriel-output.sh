#!/bin/sh
# Sunshine global prep command (sunshine.conf): a virtual output for each
# stream, sized to the client. Based on Umbriel's docs/user/streaming.md.
set -eu

name=sunshine
# Optional include in config.toml, only filled during a session.
rules="$HOME/.config/umbriel/streaming.toml"
# "<workspace position> <output>" of Steam's main window when the stream began.
home="${XDG_RUNTIME_DIR:-/tmp}/umbriel-sunshine-steam"

steam_main() {
    # "<id> <workspace id>" of Steam's main window, if it is open
    umbriel windows --json |
        jq -r '[.[] | select(.app_id == "steam" and (.title | test("^[Ss]team$")))]
            | first | select(.) | "\(.id) \(.workspace)"'
}

case "$1" in
    create)
        umbriel output-destroy "$name" >/dev/null 2>&1 || true
        # Remember where Steam's main window is before Big Picture replaces it.
        : > "$home"
        main="$(steam_main)"
        if [ -n "$main" ]; then
            umbriel workspaces --json |
                jq -r --arg ws "${main#* }" '.[] | select(.id == $ws) | "\(.index) \(.output)"' > "$home"
        fi
        umbriel output-create "$name" \
            "${SUNSHINE_CLIENT_WIDTH:-1920}x${SUNSHINE_CLIENT_HEIGHT:-1080}@${SUNSHINE_CLIENT_FPS:-60}" >/dev/null
        # Steam's main window comes back when Big Picture closes: don't let it
        # take focus, and put it back where it was.
        {
            echo '[[window_rule]]'
            echo 'match.app_id      = "^steam$"'
            echo 'match.title       = "^[Ss]team$"'
            echo 'default_focused   = false'
            if [ -s "$home" ]; then
                read -r index output < "$home"
                echo "default_output    = \"$output\""
                echo "default_workspace = $index"
            fi
        } > "$rules"
        umbriel msg config-reload
        ;;
    remove)
        # Give windows that the app's undo command is closing up to 5 seconds to
        # go away, so they do not flash onto a physical monitor.
        i=0
        while [ "$i" -lt 25 ]; do
            left="$(umbriel windows --json |
                jq --arg out "$name:" '[.[] | select(.workspace | startswith($out))] | length')"
            [ "$left" = 0 ] && break
            sleep 0.2
            i=$((i + 1))
        done
        # Move what is left off the stream, so it does not return to the next
        # session's output: to where Steam was, else the focused workspace of
        # another output.
        target=""
        if [ -s "$home" ]; then
            read -r index output < "$home"
            target="$(umbriel workspaces --json |
                jq -r --arg out "$output" --argjson i "$index" \
                    '.[] | select(.output == $out and .index == $i) | "\(.name)/\(.output)"')"
        fi
        [ -n "$target" ] || target="$(umbriel workspaces --json |
            jq -r --arg out "$name" '[.[] | select(.output != $out and .active)]
                | (map(select(.focused)) + .) | first | "\(.name)/\(.output)" // empty')"
        for id in $(umbriel windows --json |
            jq -r --arg out "$name:" '.[] | select(.workspace | startswith($out)) | .id'); do
            [ -n "$target" ] || break
            umbriel msg "window-focus:$id"
            umbriel msg "window-move-to-workspace-silent:$target"
        done
        umbriel output-destroy "$name" >/dev/null 2>&1 || true
        # Keep the Steam rule until its main window is back (up to 10 seconds).
        i=0
        while [ "$i" -lt 50 ] && [ -z "$(steam_main)" ]; do
            sleep 0.2
            i=$((i + 1))
        done
        : > "$rules"
        rm -f "$home"
        umbriel msg config-reload
        ;;
esac
