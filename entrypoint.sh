#!/bin/bash
set -e

# Wechselt in das Workspace-Verzeichnis.
cd /home/rosdev/ros2_ws
# Installiert alle im Workspace definierten ROS-Abhängigkeiten.
# --ignore-src verhindert, dass Pakete im 'src'-Ordner erneut installiert werden.


# Führt den Befehl aus, der an 'docker compose up' oder 'docker run' übergeben wurde (z.B. 'tail -f /dev/null').
exec "$@"