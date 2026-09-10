# Hacker Green — GRUB boot theme

A Full HD (1920x1080) GRUB2 theme: black CRT-style screen, glowing green
monospace text (Hack font), scanline overlay, ASCII-style corner brackets
around the boot menu.

## Preview

![preview](screenshots/preview.png)

## Requirements

- GRUB 2.06+ (tested on GRUB 2.12 / Ubuntu 24.04 based systems)
- `imagemagick`, `grub-common` (for `grub-mkfont`)
- the [Hack](https://sourcefoundry.org/hack/) font (`fonts-hack-ttf` on Debian/Ubuntu) — only needed to rebuild assets with `scripts/build.sh`, not to install

## Install

```
sudo bash scripts/install.sh
```

This backs up `/etc/default/grub` and `/boot/grub/grub.cfg` with a timestamp,
copies the theme into `/boot/grub/themes/hacker-green/`, sets `GRUB_THEME`,
`GRUB_GFXMODE="1920x1080,auto"` and `GRUB_TIMEOUT_STYLE="menu"`, then runs
`update-grub`. Every step is validated; on any failure it rolls back
automatically. The `auto` fallback in `GRUB_GFXMODE` means GRUB drops to a
supported resolution instead of failing if 1920x1080 isn't available.

## Test without touching the real bootloader

```
sudo apt install grub-emu
sudo bash scripts/test-in-emulator.sh
```

Runs the *installed* theme inside `grub-emu` (a real GRUB core in an SDL
window) and saves a screenshot to `.emu/screenshot.png`. Useful for catching
theme.txt errors before rebooting.

## Rebuild assets from scratch

```
bash scripts/build.sh
```

Regenerates everything in `theme/` (fonts, background, corner brackets).

## Notes / gotchas hit while building this

- GRUB's theme parser (`grub-core/gfxmenu`) only accepts **integer** numbers
  for `left`/`top`/`width`/`height` (plain pixels or `N%`) — a value like
  `36.5%` fails with `error: unrecognized number.`
- GRUB's built-in PNG decoder (`png.mod`) only supports **8-bit** color
  depth. ImageMagick's `radial-gradient:` (and some other generators)
  produce 16-bit PNGs by default, which fail with `error: invalid filter
  value.` at render time. Always `convert ... -depth 8 ...` (or check with
  `identify -format '%z-bit' file.png`).
- `GRUB_TIMEOUT_STYLE="hidden"` (Ubuntu's default) means the themed menu
  never actually renders unless a key is pressed during boot — set it to
  `"menu"` to see the theme every boot.

## License

MIT — see [LICENSE](LICENSE).
