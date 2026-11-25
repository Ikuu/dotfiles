#!/usr/bin/env bash
# Usage: turn-timer.sh start|stop  (reads hook JSON on stdin)
# Chime on stop when: the turn was a background wake-up (no user prompt since the
# last stop), OR a user-prompted turn ran >= THRESHOLD seconds.
THRESHOLD=300
dir="${XDG_RUNTIME_DIR:-/tmp}/claude-turn-timer"
mkdir -p "$dir"
sid=$(jq -r '.session_id // "default"')
f="$dir/$sid"
now=$(date +%s)
if [ "$1" = start ]; then
  echo "user $now" > "$f"
  exit 0
fi
read -r kind start < "$f" 2>/dev/null || { kind=auto; start=$now; }
if [ "$kind" != user ] || [ $((now - start)) -ge $THRESHOLD ]; then
  pw-play /usr/share/sounds/ocean/stereo/completion-success.oga >/dev/null 2>&1 &
fi
# Next stop with no prompt in between is a background wake-up
echo "auto $now" > "$f"
