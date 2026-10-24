#!/usr/bin/env bash
cd "$(dirname "$0")"
echo "Buka http://localhost:8000 di browser"
python3 -m http.server 8000
