#!/bin/bash
# Regenerates theme/ assets from scratch (fonts + background + corner brackets).
# Output PNGs are forced to 8-bit depth — GRUB's built-in png.mod decoder
# cannot read 16-bit PNGs (fails with "invalid filter value").
set -e

OUT="$(dirname "$0")/../theme"
mkdir -p "$OUT"
cd "$OUT"

FONT_TTF="/usr/share/fonts/truetype/hack/Hack-Regular.ttf"
if [ ! -f "$FONT_TTF" ]; then
  echo "Hack font not found at $FONT_TTF — install it (e.g. apt install fonts-hack-ttf) or edit FONT_TTF in this script."
  exit 1
fi

echo "== fonts =="
grub-mkfont --output=hackgreen.pf2 --name="hackgreen" --size=26 "$FONT_TTF"
grub-mkfont --output=hackgreen-small.pf2 --name="hackgreen-small" --size=16 "$FONT_TTF"

echo "== background (1920x1080, 8-bit) =="
convert -size 1920x1080 -depth 8 radial-gradient:'#07170c-#000000' bg_vignette.png
convert -size 1920x3 -depth 8 xc:black -fill "#0d3a1a" -draw "rectangle 0,0 1920,0" scanline_tile.png
convert -size 1920x1080 -depth 8 tile:scanline_tile.png -alpha set -channel A -evaluate set 10% +channel scanlines.png
convert bg_vignette.png scanlines.png -compose over -composite -depth 8 -type TrueColor -define png:color-type=2 background.png
rm -f bg_vignette.png scanline_tile.png scanlines.png

echo "== corner brackets (36x36, 8-bit RGBA) =="
convert -size 36x36 -depth 8 xc:none -fill none -stroke '#33ff66' -strokewidth 3 -draw "line 2,2 2,26 line 2,2 26,2" -define png:color-type=6 corner_tl.png
convert corner_tl.png -flop -depth 8 -define png:color-type=6 corner_tr.png
convert corner_tl.png -flip -depth 8 -define png:color-type=6 corner_bl.png
convert corner_tl.png -flip -flop -depth 8 -define png:color-type=6 corner_br.png

echo "== done, verifying depth =="
for f in *.png; do
  echo "$f: $(identify -format '%z-bit' "$f")"
done
