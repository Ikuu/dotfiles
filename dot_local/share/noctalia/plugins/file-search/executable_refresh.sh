#!/bin/sh
# Rebuild the file lists. Each source has its own list, and a list is only
# replaced when its fd run finishes, so an offline network share keeps its
# last good list instead of vanishing from results.
dir="$HOME/.cache/noctalia-file-search"
mkdir -p "$dir"
exec 9>"$dir/lock"
flock -n 9 || exit 0   # a refresh is already running

list() {  # list <name> <timeout-seconds> <paths...>
    name=$1 secs=$2; shift 2
    if timeout "$secs" fd -t f . "$@" > "$dir/$name.tmp" 2>/dev/null; then
        mv "$dir/$name.tmp" "$dir/$name.list"
    else
        rm -f "$dir/$name.tmp"
    fi
}

list local 60 "$HOME" /media/Linux /media/Storage /media/Shared
list das 120 /media/das &
list smb 120 /media/smb &
wait
