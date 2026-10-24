#!/usr/bin/env python3
"""Membuat musik latar dan efek suara sederhana (WAV mono 22,05 kHz).

Semua nada disintesis di sini supaya tidak ada berkas berlisensi pihak lain
yang masuk ke repo. Jalankan: python3 tools/gen_audio.py
Hasil: assets/audio/*.wav
"""
import math
import os
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")

NOTE = {}
_names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
for octave in range(2, 7):
    for i, n in enumerate(_names):
        NOTE["%s%d" % (n, octave)] = 440.0 * (2 ** ((octave - 4) + (i - 9) / 12.0))


def env(i, n, attack=0.01, release=0.25):
    """Envelope sederhana: serang cepat, luruh eksponensial."""
    t = i / SR
    total = n / SR
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, max(0.0, (total - t) / release))
    return a * r


def tone(buf, start, dur, freq, amp=0.22, wave_type="tri", detune=0.0):
    n = int(dur * SR)
    for i in range(n):
        idx = start + i
        if idx >= len(buf):
            break
        t = i / SR
        ph = 2 * math.pi * (freq + detune) * t
        if wave_type == "sine":
            s = math.sin(ph)
        elif wave_type == "square":
            s = 1.0 if math.sin(ph) >= 0 else -1.0
        elif wave_type == "saw":
            s = 2.0 * ((freq * t) % 1.0) - 1.0
        else:  # triangle
            s = 2.0 * abs(2.0 * ((freq * t) % 1.0) - 1.0) - 1.0
        buf[idx] += s * amp * env(i, n)


def noise(buf, start, dur, amp=0.12, decay=0.9):
    n = int(dur * SR)
    seed = 12345
    for i in range(n):
        idx = start + i
        if idx >= len(buf):
            break
        seed = (1103515245 * seed + 12345) & 0x7FFFFFFF
        r = (seed / 0x7FFFFFFF) * 2.0 - 1.0
        buf[idx] += r * amp * math.exp(-i / (SR * dur * decay))


def write_wav(name, buf):
    peak = max(1e-6, max(abs(v) for v in buf))
    scale = 0.86 / peak if peak > 0.86 else 1.0
    data = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * scale)) * 32767)) for v in buf)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(data)
    print("  %-16s %5.1f s  %6.0f KB" % (name, len(buf) / SR, os.path.getsize(path) / 1024))


# ------------------------------------------------------------------ musik
def bgm_explore():
    """Loop 8 birama, progresi C - Am - F - G, arpeggio lembut."""
    bpm = 96.0
    beat = 60.0 / bpm
    bars = 8
    total = int(bars * 4 * beat * SR) + SR // 2
    buf = [0.0] * total
    prog = [("C4", ["C4", "E4", "G4", "E4"]), ("A3", ["A3", "C4", "E4", "C4"]),
            ("F3", ["F3", "A3", "C4", "A3"]), ("G3", ["G3", "B3", "D4", "B3"])]
    for bar in range(bars):
        root, arp = prog[bar % 4]
        bar_start = int(bar * 4 * beat * SR)
        # bass tiap 2 ketuk
        for k in (0, 2):
            tone(buf, bar_start + int(k * beat * SR), beat * 1.8, NOTE[root] / 2, 0.16, "sine")
        # arpeggio 8 nada per birama
        for k in range(8):
            note = arp[k % 4]
            octave = 2 if k >= 4 else 1
            tone(buf, bar_start + int(k * beat * 0.5 * SR), beat * 0.45,
                 NOTE[note] * octave, 0.10, "tri")
        # ketukan ringan
        for k in range(4):
            noise(buf, bar_start + int(k * beat * SR), 0.06, 0.05)
    return buf


def bgm_final():
    """Loop 4 birama, nada rendah dan tegang untuk The Source."""
    bpm = 112.0
    beat = 60.0 / bpm
    bars = 8
    total = int(bars * 4 * beat * SR) + SR // 2
    buf = [0.0] * total
    seq = [("D3", ["D3", "F3", "A3", "F3"]), ("A#2", ["A#2", "D3", "F3", "D3"]),
           ("F2", ["F2", "A2", "C3", "A2"]), ("C3", ["C3", "E3", "G3", "E3"])]
    for bar in range(bars):
        root, arp = seq[bar % 4]
        bar_start = int(bar * 4 * beat * SR)
        tone(buf, bar_start, beat * 4, NOTE[root] / 2, 0.20, "saw")
        for k in range(8):
            tone(buf, bar_start + int(k * beat * 0.5 * SR), beat * 0.35,
                 NOTE[arp[k % 4]] * 2, 0.075, "square")
        for k in (0, 2):
            noise(buf, bar_start + int(k * beat * SR), 0.10, 0.07)
    return buf


# ------------------------------------------------------------------ efek
def sfx_coin():
    buf = [0.0] * int(0.28 * SR)
    tone(buf, 0, 0.09, NOTE["B5"], 0.30, "square")
    tone(buf, int(0.07 * SR), 0.16, NOTE["E6"], 0.28, "square")
    return buf


def sfx_click():
    buf = [0.0] * int(0.09 * SR)
    tone(buf, 0, 0.05, 880, 0.18, "square")
    noise(buf, 0, 0.05, 0.06)
    return buf


def sfx_ok():
    buf = [0.0] * int(0.55 * SR)
    for i, n in enumerate(["C5", "E5", "G5", "C6"]):
        tone(buf, int(i * 0.075 * SR), 0.22, NOTE[n], 0.24, "tri")
    return buf


def sfx_err():
    buf = [0.0] * int(0.35 * SR)
    tone(buf, 0, 0.30, NOTE["A2"], 0.22, "square", detune=-6)
    tone(buf, 0, 0.30, NOTE["G#2"], 0.18, "square")
    return buf


def sfx_portal():
    buf = [0.0] * int(0.95 * SR)
    steps = 24
    for i in range(steps):
        f = 260 + i * 42
        tone(buf, int(i * 0.03 * SR), 0.16, f, 0.16, "sine")
    for i in range(6):
        tone(buf, int((0.35 + i * 0.07) * SR), 0.25, NOTE["E6"] * (1 + i * 0.02), 0.09, "tri")
    return buf


def sfx_badge():
    buf = [0.0] * int(0.9 * SR)
    for i, n in enumerate(["G4", "B4", "D5", "G5"]):
        tone(buf, int(i * 0.09 * SR), 0.5, NOTE[n], 0.20, "tri")
    tone(buf, int(0.36 * SR), 0.5, NOTE["B5"], 0.12, "sine")
    return buf


def sfx_step():
    buf = [0.0] * int(0.07 * SR)
    noise(buf, 0, 0.06, 0.05, decay=1.6)
    return buf


def main():
    os.makedirs(OUT, exist_ok=True)
    print("membuat audio:")
    write_wav("bgm_explore", bgm_explore())
    write_wav("bgm_final", bgm_final())
    write_wav("sfx_coin", sfx_coin())
    write_wav("sfx_click", sfx_click())
    write_wav("sfx_ok", sfx_ok())
    write_wav("sfx_err", sfx_err())
    write_wav("sfx_portal", sfx_portal())
    write_wav("sfx_badge", sfx_badge())
    write_wav("sfx_step", sfx_step())
    print("selesai.")


if __name__ == "__main__":
    main()
