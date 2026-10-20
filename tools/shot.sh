#!/usr/bin/env bash
# Ambil tangkapan layar satu kondisi demo (dari viewport game, bukan X11).
# Pakai: ./tools/shot.sh <demo> <output.png> [delay] [map]
set -u
DEMO="${1:-title}"
OUT="${2:-/tmp/shot.png}"
DELAY="${3:-7}"
MAP="${4:-}"
GODOT=/home/ubuntu/.local/bin/godot

pkill -f "terra-godot --resolution" 2>/dev/null
sleep 1

cd /home/ubuntu/terra-godot
rm -f "$OUT"
DISPLAY=:99 TERRA_DEMO="$DEMO" TERRA_MAP="$MAP" TERRA_SHOT="$OUT" TERRA_SHOT_DELAY="$DELAY" \
	"$GODOT" --path /home/ubuntu/terra-godot --resolution 1280x720 > "/tmp/godot_${DEMO}.log" 2>&1
echo "captured $OUT"
grep -iE "^SCRIPT ERROR|^ERROR" "/tmp/godot_${DEMO}.log" | head -5
exit 0
