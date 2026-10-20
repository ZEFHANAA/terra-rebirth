# Terra Rebirth — Prototipe Game RPG Edukasi (Godot 4)

Prototipe permainan RPG edukasi untuk penelitian **"Pengembangan dan Evaluasi Game RPG Edukasi Terra Rebirth sebagai Media Pembelajaran Konsep Informatika"** (Kelompok 1, Program Studi Informatika).

Dibangun dengan **Godot 4.7 + GDScript** sesuai Bab II proposal. Aset visual dibuat khusus untuk proyek ini: tanah dan tata letak peta digambar prosedural dengan Python di `tools/`, sedangkan karakter, gedung, pohon, dan ilustrasi latar dibuat dengan bantuan model gambar AI lalu dirapikan (pemotongan latar otomatis + perakitan spritesheet). Tidak ada aset pihak ketiga berlisensi, sehingga aman untuk laporan.

## Main langsung di browser

**https://zefhanaa.github.io/terra-rebirth/**

Tidak perlu instalasi apa pun — cukup buka tautannya di Chrome/Firefox (desktop atau Android). Butuh internet saat pertama kali memuat (±38 MB).

Untuk mencoba versi terbaru dari kode sumber, lihat bagian [Cara menjalankan](#1-cara-menjalankan) di bawah.

---

## 1. Cara menjalankan

### A. Lewat build web (paling cepat, tanpa instalasi)
```bash
cd build/web
python3 -m http.server 8000
# buka http://localhost:8000
```
Di Windows: klik dua kali `jalankan-web.bat` (butuh Python terpasang).
Build web **tidak bisa** dibuka langsung dengan klik dua kali `index.html` (browser memblokir WebAssembly dari `file://`).

### B. Lewat Godot Editor
1. Pasang Godot 4.7 (https://godotengine.org/download).
2. `Import` → pilih `project.godot` pada folder ini → `Open`.
3. Tekan **F5**.

### C. Ekspor ulang
Preset Web sudah tersedia di `export_presets.cfg`:
```bash
godot --headless --path . --export-release "Web" build/web/index.html
```

### D. Video demo
`dokumentasi/gameplay-kota.mp4` — rekaman 46 detik dari layar judul sampai Kota Unggul selesai (2 tantangan + peta wilayah terbuka), direkam langsung dari build Godot.

Merekam ulang:
```bash
Xvfb :99 -screen 0 1280x720x24 &
./tools/rekam.sh dokumentasi/gameplay-kota.mp4 64   # lalu potong 46 detik
```

---

## 2. Kontrol

| Tombol | Fungsi |
|---|---|
| `W A S D` / panah | Berjalan |
| `E` | Bicara dengan NPC, lanjut dialog, berinteraksi |
| `M` | Buka peta wilayah |
| `Esc` | Menu / tutup panel |
| Klik mouse | Memilih jawaban, menyusun query, menggeser cakram sandi |

---

## 3. Alur permainan

Permainan **tidak membuka dialog atau soal secara otomatis**. Pemain masuk ke peta, berjalan mencari NPC/objek, lalu menekan `E` untuk berinteraksi — sesuai Bab II 2.4 (eksplorasi → menemukan misi → tantangan → umpan balik → penguatan konsep → XP).

1. **Kota Unggul** (tutorial & hub) — 4 NPC:
   - **Kepala Kota** (tanda `!`) memberi tugas dan membuka 2 tantangan pengantar.
   - **Penjaga Gerbang** menjelaskan syarat level + badge sebelum portal terbuka.
   - **Pedagang** menjual **Lensa Analisis** (20 Keping Data) — sekali pakai untuk membuka petunjuk.
   - **Peneliti Lingkungan** memberi konteks cerita (danau tercemar).
   Setiap tantangan selesai memberi **+10 Keping Data**.
2. **Hutan Pengetahuan** (Basis Data) — 3 objek pencarian (**Papan Data**, **Catatan Lapangan**, **Sampel Air**) menyimpan petunjuk; tiap objek membuka satu tantangan → **Badge Nature**.
3. **Pabrik Limbah** (Sistem Operasi) — 3 tantangan → **Badge Core**.
4. **Candi Kuno** (Kriptografi) — 3 tantangan → **Badge Cipher**.
5. **Danau Citra** (Internet of Things) — tantangan pertama membuka pencarian **3 komponen** (sensor, mikrokontroler, modul Wi-Fi); tantangan kedua **merakit perangkat** dari komponen yang sudah dikumpulkan; tantangan ketiga menguji hasil rakit → **Badge Aqua**.
6. **The Source** (final dungeon) — 3 tantangan melawan **boss** (HP berkurang tiap tantangan selesai) → **Badge Guardian** → **keputusan akhir** pemain (segel sumber / susun ulang protokol) yang menentukan teks ending.

Total **17 tantangan**, **510 XP**, 6 level, 5 badge.

**Aturan gating (sesuai revisi Bab II):**
- Badge **hanya** diberikan setelah tantangan terakhir pada suatu wilayah selesai — bukan setiap jawaban benar.
- Wilayah berikutnya terbuka bila **level minimum terpenuhi DAN badge wilayah sebelumnya sudah dimiliki**.

**Lima tipe tantangan:**
- `mcq` — pilihan ganda konsep.
- `build` — menyusun query SQL lewat dropdown (SELECT / FROM / JOIN / WHERE / ORDER BY).
- `order` — menyusun urutan langkah (penjadwalan proses, alur data IoT).
- `cipher` — memutar cakram Caesar untuk membaca pesan.
- `craft` — merakit perangkat IoT dari komponen yang dikumpulkan di peta (Danau Citra).

---

## 4. Mode Riset (instrumen penelitian)

Menu **Mode Riset** pada layar judul berisi empat tab:
- **Pre-Test** — 8 soal pilihan ganda.
- **Post-Test** — 8 soal dengan kunci berbeda.
- **SUS** — 10 pernyataan skala 1–5 (pola ganjil/genap), skor akhir dihitung otomatis.
- **Rekap** — tabel seluruh responden (kode, pre, post, N-gain, SUS) + tombol ekspor CSV.

Data disimpan di `user://records_terra.json` (Godot) dan dapat diekspor ke CSV untuk diolah di Excel/SPSS.

---

## 5. Struktur folder

```
project.godot            konfigurasi proyek (1280x720, autoload Game)
scenes/Main.tscn         scene tunggal, seluruh UI dibangun dari skrip
data/content.gd          6 peta, 17 tantangan, dialog NPC, syarat level & badge
scripts/game_state.gd    autoload: XP, level, badge, progres, simpan/muat, rekap
scripts/main.gd          orkestrator layar + input + transisi
scripts/player.gd        CharacterBody2D + AnimatedSprite2D 4 arah
scripts/world.gd         membangun peta (collision, 4 NPC, objek pencarian, portal)
scripts/portal.gd        gerbang antar wilayah (terkunci/terbuka)
scripts/ui/              ui_kit, hud, dialog_box, puzzle_panel, badge_popup, shop_panel
scripts/screens/         title, map_select, research, ending
scripts/autotest.gd      uji integrasi otomatis (35 cek)
tools/assets_gen.py      generator sprite, NPC, badge, panel, latar judul
tools/maps_gen.py        generator 6 peta 40x22 tile + JSON collision
tools/shot.sh            pengambil tangkapan layar otomatis (Xvfb + ffmpeg)
assets/                  hasil generator: sprites, ui, maps, fonts
dokumentasi/             tangkapan layar untuk laporan Bab III
build/web/               hasil ekspor web (siap disajikan lewat server lokal)
```

---

## 6. Uji otomatis

```bash
godot --headless --path . res://scenes/AutoTest.tscn
```
Menguji: eksplorasi objek → dialog → tantangan (mcq/build/order/cipher/craft) → XP → level → badge → gating antar-wilayah → keping data & toko → boss → keputusan ending → simpan/muat.
Hasil terakhir: **35 cek, 0 gagal**.

---

## 6b. Rekaman

- `dokumentasi/gameplay-kota.mp4` — satu wilayah (46 dtk)
- `dokumentasi/gameplay-tour.mp4` — dua wilayah, termasuk objek di Hutan (70 dtk)

Rekam ulang: `./tools/rekam.sh /tmp/out.mp4 70 tour` (demo: `rekam` atau `tour`).

## 6c. Karakter

Sprite **96x136 per frame**, 4 arah × 3 frame, gaya chibi kartun halus (bukan pixel art):

- Sumber gambar: model gambar AI (Pollinations) → dipotong latarnya dengan `rembg` (`u2net`),
  lalu dirakit jadi spritesheet oleh `/tmp/build_chars.py` (lihat catatan di bagian 7).
- `tools/icons48.py` — ikon objek 48×48 digambar vektor (supersample 4×) agar tetap tajam.
- Arah: depan, belakang, kanan, kiri (kiri = cermin dari kanan); 3 frame dengan geseran halus
  untuk kesan melangkah.
- Titik tumpu tetap di kaki, jadi collision (`22×12`) dan posisi di peta konsisten.

## 7. Aset

Aset peta/UI dibuat sendiri lewat skrip; sprite karakter & properti dibuat dengan bantuan AI
lalu dirapikan (bukan aset pihak ketiga, tidak ada lisensi yang dilanggar):
- `assets/sprites/hero.png` — 96×136 per frame, 3 kolom × 4 baris.
- `assets/sprites/npc_*.png` — kepala kota, peneliti, penjaga, pedagang (sel per 96×136).
- `assets/sprites/obj_sign.png`, `obj_part.png` — objek pencarian 48×48 (digambar vektor).
- `assets/ui/badge_*.png` — 5 ikon badge.
- `assets/ui/title_bg.png`, `ending_bg.png` — ilustrasi latar (AI, watermark dipotong).
- `assets/maps/*.png` + `*.json` — 6 peta 40×22 tile (**48 px**), JSON memuat grid solid, spawn,
  posisi NPC, dan portal; `thumb_*.png` versi kecil untuk kartu peta wilayah.
- Tanah (rumput, jalan tanah, air, plaza batu) digambar prosedural: tepi organik, bercak halus,
  bayangan kontak — tanpa pola ubin yang terlihat berulang.
- Properti (gedung, pohon, semak, bunga) ditempel dengan urutan kedalaman (painter's algorithm).
- Karakter, NPC, dan objek punya bayangan kontak (dibuat saat runtime di `world.gd`).
- `assets/fonts/Baloo2.ttf` — font UI membulat, lisensi SIL Open Font License 1.1.

Regenerasi aset: `./tools/regen.sh` (menjalankan kedua generator lalu memaksa Godot mengimpor ulang; butuh Pillow).
Peta gaya kartun dibuat dengan `python3 /tmp/mapmix.py <id>` (butuh `maps_gen.py`, `cartoon_map2.py`, dan folder aset AI).
Tanpa langkah impor ulang, Godot masih memakai tekstur lama di `.godot/imported/` — ini penyebab umum "aset sudah diubah tapi tidak berubah di layar".
