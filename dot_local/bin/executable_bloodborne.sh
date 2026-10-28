#!/bin/bash
# Launch Bloodborne (bbhost) from Steam with the performance power profile and
# GameMode. The wrappers run here, inside Steam's process tracking, rather
# than in the launch options, where Steam lost the game and stopped counting
# playtime. Leave the Steam shortcut's launch options empty.
cd "$HOME/Games/Bloodborne/bbhost" || exit 1
exec game-performance gamemoderun ./bbhost
