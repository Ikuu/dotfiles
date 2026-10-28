#!/bin/bash
export WINEPREFIX=/media/Linux/Lutris
export PROTONPATH="$HOME/.local/share/Steam/compatibilitytools.d/Proton-GE Latest"
BNET="$WINEPREFIX/drive_c/Program Files (x86)/Battle.net/Battle.net.exe"

if ! pgrep -f "Battle.net/Agent" > /dev/null; then
    umu-run "$BNET" &
    sleep 25
fi

# Battle.net launch codes for --exec="launch <code>":
#   WoW   Retail
#   WoWC  Classic (whichever Classic version is selected in Battle.net)
#   WoWF  World of Warcraft: Forever (beta; code may change at release)
PROTON_VERB=run umu-run "$BNET" --exec="launch WoWF"
wait
