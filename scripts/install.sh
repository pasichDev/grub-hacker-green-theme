#!/bin/bash
# Installs theme/ into /boot/grub/themes/hacker-green, wires it up in
# /etc/default/grub, regenerates grub.cfg, and validates the result.
# Backs everything up first and auto-rolls-back if any check fails.
set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "run with sudo: sudo bash scripts/install.sh"
  exit 1
fi

SRC="$(cd "$(dirname "$0")/.." && pwd)/theme"
DST="/boot/grub/themes/hacker-green"
STAMP=$(date +%Y%m%d-%H%M%S)

echo "== 1. backing up current config =="
cp -a /etc/default/grub "/etc/default/grub.bak-$STAMP"
cp -a /boot/grub/grub.cfg "/boot/grub/grub.cfg.bak-$STAMP"

echo "== 2. installing theme files =="
mkdir -p "$DST"
cp -v "$SRC"/theme.txt "$SRC"/background.png "$SRC"/hackgreen.pf2 "$SRC"/hackgreen-small.pf2 "$SRC"/corner_*.png "$DST"/
chown -R root:root "$DST"
chmod 644 "$DST"/*

echo "== 3. sanity-checking theme.txt (no decimal numbers, balanced braces) =="
if grep -qE '[0-9]+\.[0-9]+' "$DST/theme.txt"; then
  echo "FAIL: decimal number in theme.txt — GRUB's parser only accepts integers"
  exit 1
fi
OPEN=$(grep -o '{' "$DST/theme.txt" | wc -l)
CLOSE=$(grep -o '}' "$DST/theme.txt" | wc -l)
if [ "$OPEN" != "$CLOSE" ]; then
  echo "FAIL: brace mismatch in theme.txt"
  exit 1
fi

echo "== 4. sanity-checking PNG depth (GRUB's png.mod only reads 8-bit) =="
for f in "$DST"/*.png; do
  DEPTH=$(identify -format "%z" "$f")
  if [ "$DEPTH" != "8" ]; then
    echo "FAIL: $f is ${DEPTH}-bit, must be 8-bit"
    exit 1
  fi
done

echo "== 5. updating /etc/default/grub =="
sed -i 's#^GRUB_THEME=.*#GRUB_THEME="/boot/grub/themes/hacker-green/theme.txt"#' /etc/default/grub
if grep -q '^GRUB_GFXMODE=' /etc/default/grub; then
  sed -i 's#^GRUB_GFXMODE=.*#GRUB_GFXMODE="1920x1080,auto"#' /etc/default/grub
else
  echo 'GRUB_GFXMODE="1920x1080,auto"' >> /etc/default/grub
fi
sed -i 's#^GRUB_TIMEOUT_STYLE=.*#GRUB_TIMEOUT_STYLE="menu"#' /etc/default/grub

echo "== 6. regenerating grub.cfg =="
update-grub

echo "== 7. validating grub.cfg =="
FAIL=0
grep -q "hacker-green/theme.txt" /boot/grub/grub.cfg || { echo "FAIL: theme path missing from grub.cfg"; FAIL=1; }

if [ "$FAIL" -ne 0 ]; then
  echo "== rolling back =="
  cp -a "/etc/default/grub.bak-$STAMP" /etc/default/grub
  update-grub
  exit 1
fi

echo "== ALL CHECKS PASSED =="
echo "rollback if needed: sudo cp /etc/default/grub.bak-$STAMP /etc/default/grub && sudo update-grub"
