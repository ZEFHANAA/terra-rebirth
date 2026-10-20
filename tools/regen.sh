#!/usr/bin/env bash
# Regenerasi aset + paksa Godot mengimpor ulang, supaya tangkapan layar tidak memakai cache lama.
set -e
cd "$(dirname "$0")/.."
python3 tools/maps_gen.py
if [ "$1" != "--map-only" ]; then
  python3 tools/assets_gen.py
fi
rm -f .godot/imported/*.ctex .godot/imported/*.md5
/home/ubuntu/.local/bin/godot --headless --path . --import >/dev/null 2>&1 || true
echo "aset diperbarui"
