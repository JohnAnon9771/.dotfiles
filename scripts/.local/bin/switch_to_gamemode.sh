#!/usr/bin/env bash
# set -euo pipefail

DESKTOP_USER="albus_rb"
GAME_TTY="tty3"

loginctl terminate-user "$DESKTOP_USER"
# systemctl start "getty@${GAME_TTY}.service"

chvt 3
