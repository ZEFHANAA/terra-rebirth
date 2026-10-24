@echo off
cd /d "%~dp0"
echo Menyajikan Terra Rebirth di http://localhost:8000
start "" http://localhost:8000
python -m http.server 8000
