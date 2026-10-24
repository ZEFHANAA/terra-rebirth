#!/usr/bin/env bash
# Rekam gameplay satu wilayah penuh (mode demo "rekam") dari Xvfb.
# Pakai: ./tools/rekam.sh /tmp/rekam.mp4 45 [demo]
# demo: rekam (satu wilayah) | tour (dua wilayah + objek)
set -u
OUT="${1:-/tmp/rekam.mp4}"
DUR="${2:-45}"
DEMO="${3:-rekam}"
GODOT=/home/ubuntu/.local/bin/godot
FFMPEG=/home/ubuntu/.hermes/tools/ffmpeg-9.0.1-linux-arm64/bin/ffmpeg

pkill -f "godot --path /home/ubuntu/terra-godot" 2>/dev/null
sleep 1

DISPLAY=:99 "$FFMPEG" -y -loglevel error -f x11grab -video_size 1280x720 \
	-framerate 30 -draw_mouse 1 -i :99 -t "$DUR" \
	-c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p -movflags +faststart "$OUT" &
FPID=$!
sleep 1

cd /home/ubuntu/terra-godot
DISPLAY=:99 TERRA_DEMO="$DEMO" "$GODOT" --path /home/ubuntu/terra-godot --resolution 1280x720 \
	> /tmp/godot_rekam.log 2>&1 &
GPID=$!

wait $FPID
kill $GPID 2>/dev/null
wait $GPID 2>/dev/null

# bersihkan berkas demo supaya folder pengguna tetap rapi
D="$HOME/.local/share/godot/app_userdata/Terra Rebirth"
rm -f "$D/records_demo.json" "$D/save_demo.json"

echo "video: $OUT"
ls -lh "$OUT" | awk '{print $5}'
