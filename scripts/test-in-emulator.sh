#!/bin/bash
# Renders the *installed* theme (/boot/grub/themes/hacker-green) inside
# grub-emu — a real GRUB running in an SDL window — without touching the
# real bootloader. Requires: sudo apt install grub-emu
set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "run with sudo: sudo bash scripts/test-in-emulator.sh"
  exit 1
fi

DIR="$(cd "$(dirname "$0")/.." && pwd)/.emu"
mkdir -p "$DIR"

if [ ! -s "$DIR/device.map" ]; then
  grub-mkdevicemap --device-map="$DIR/device.map"
fi

# auto-detect the caller's DISPLAY/XAUTHORITY from their desktop session,
# since sudo usually strips these
REAL_USER="${SUDO_USER:-$USER}"
SESSPID=$(pgrep -u "$REAL_USER" -f "plasmashell|kwin_x11|kwin_wayland|gnome-shell|Xorg" | head -1)
if [ -z "$SESSPID" ]; then
  echo "couldn't find a desktop session for $REAL_USER — set DISPLAY/XAUTHORITY manually"
  exit 1
fi
export DISPLAY=$(tr '\0' '\n' < "/proc/$SESSPID/environ" | sed -n 's/^DISPLAY=//p')
export XAUTHORITY=$(tr '\0' '\n' < "/proc/$SESSPID/environ" | sed -n 's/^XAUTHORITY=//p')
echo "DISPLAY=$DISPLAY  XAUTHORITY=$XAUTHORITY"

grub-emu -d /boot/grub -m "$DIR/device.map" > "$DIR/emu.log" 2>&1 &
EMU_PID=$!

echo "waiting for window..."
sleep 6

WIN_ID=$(DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY xwininfo -root -tree | grep '"grub-emu"' | awk '{print $1}')
if [ -n "$WIN_ID" ]; then
  import -window "$WIN_ID" "$DIR/screenshot.png"
  chown "$REAL_USER":"$REAL_USER" "$DIR/screenshot.png"
  echo "screenshot: $DIR/screenshot.png"
else
  echo "no grub-emu window found — check $DIR/emu.log"
fi

kill "$EMU_PID" 2>/dev/null || true
sleep 1
kill -9 "$EMU_PID" 2>/dev/null || true
