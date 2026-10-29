#!/usr/bin/env bash
# Start Obsidian once Discord's main window is open, so on workspace 2 Discord
# gets the left column and Obsidian the right. Umbriel can't order separate
# columns, but a new column opens to the right of the existing one.
# Started from cfg/general.toml (autostart); placement rules are in rules.toml.

# Wait up to ~40s (startup rules only match in the first 60s). Skip Discord's
# updater splash, which shares its app ID.
for _ in $(seq 80); do
  if umbriel windows | grep -E '^[ *]discord\s' | grep -vqi 'updat'; then
    sleep 1
    break
  fi
  sleep 0.5
done

exec /home/alex/Applications/Obsidian.AppImage --no-sandbox
