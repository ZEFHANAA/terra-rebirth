# Dokumentasi Prototipe Terra Rebirth v0.5 (Godot)

Dokumen ini menjelaskan prototipe yang dibangun dan bagaimana ia menjawab poin-poin revisi pada Bab I dan Bab III proposal.

---

## 1. Ringkasan

| Aspek | Keterangan |
|---|---|
| Judul produk | Terra Rebirth |
| Jenis | RPG edukasi 2D top-down, single player |
| Mesin | Godot 4.7 (GDScript), renderer Compatibility |
| Resolusi | 1280×720, stretch `canvas_items` / aspect `keep` |
| Durasi main | ± 20–30 menit untuk 17 tantangan |
| Materi | Basis Data, Sistem Operasi, Kriptografi, Internet of Things |
| Platform | Web (WebAssembly), Windows/Linux (ekspor desktop) |
| Instrumen | Pre-test, Post-test, SUS, rekap otomatis + ekspor CSV |

## 2. Pemetaan materi → tantangan

| Wilayah | Bidang | Tantangan | Tipe |
|---|---|---|---|
| Kota Unggul | Tutorial & hub | Aturan Perjalanan; Arti Sebuah Badge | mcq |
| Hutan Pengetahuan | Basis Data | Kunci Tabel; Menyusun Query; Membaca Hasil | mcq, build (SQL), mcq |
| Pabrik Limbah | Sistem Operasi | Keadaan Proses; Urutan Penjadwalan; Memilih Penjadwalan | mcq, order, mcq |
| Candi Kuno | Kriptografi | Mengenali Sandi; Memutar Cakram; Analisis Frekuensi | mcq, cipher, mcq |
| Danau Citra | IoT | Memilih Komponen; Merakit Alur Data; Membaca Data Sensor | mcq, **craft**, mcq |
| The Source | Integrasi 4 bidang | Ujian Data; Ujian Sandi; Ujian Sistem | mcq |

Setiap tantangan memiliki pembahasan singkat yang muncul setelah dijawab, sehingga berfungsi sebagai *feedback* formatif — bukan sekadar benar/salah.

**Cara tantangan dibuka (eksplorasi, bukan menu):**

| Wilayah | Pemicu tantangan |
|---|---|
| Kota Unggul | Bicara dengan **Kepala Kota** (tanda `!`) |
| Hutan Pengetahuan | Periksa 3 objek: Papan Data, Catatan Lapangan, Sampel Air |
| Pabrik Limbah | Bicara dengan teknisi |
| Candi Kuno | Bicara dengan penjaga candi |
| Danau Citra | Bicara dengan **Inventor**; tantangan ke-2 terkunci sampai 3 komponen (sensor, mikrokontroler, modul Wi-Fi) ditemukan di peta |
| The Source | Bicara dengan penjaga gerbang final; 3 tantangan melawan boss |

## 3. Mekanik yang menjawab revisi proposal

**a. Badge tidak lagi diberikan setiap jawaban benar.**
Badge hanya diberikan sekali, setelah tantangan terakhir pada suatu wilayah selesai (`Game.complete_challenge` memeriksa `is_map_cleared`). Ini menghilangkan inkonsistensi *activity diagram* yang ditunjukkan dosen.

**b. Gating berlapis (level + badge).**
Wilayah berikutnya hanya terbuka bila level minimum **dan** badge wilayah sebelumnya terpenuhi. Kartu peta menampilkan alasan penguncian, misalnya "Butuh Lv 3 + badge Nature".

**c. Progres terukur.**
XP 30 per tantangan, ambang level `[0, 60, 140, 230, 320, 410]`, total 510 XP → level 6. Data progres disimpan otomatis (`user://save_terra.json`).

**d. Eksplorasi dan ekonomi kecil.**
Pemain harus berjalan mendekati NPC/objek (jarak < 26 px) lalu menekan `E`; dialog tidak lagi terbuka otomatis. Setiap tantangan selesai memberi **+10 Keping Data** yang bisa dibelanjakan di **Pedagang** (Lensa Analisis, 20 keping) untuk membuka petunjuk. Ini menambahkan lapisan *resource management* sederhana seperti pada RPG, tanpa mengganggu tujuan pembelajaran.

**e. Tantangan akhir dan ending bercabang.**
The Source menampilkan **bar HP boss** yang berkurang tiap tantangan selesai (3 → 0). Setelah badge Guardian diperoleh, pemain memilih salah satu dari dua keputusan (menyegel sumber atau menyusun ulang protokol) dan teks layar penutup menyesuaikan pilihan tersebut — sesuai Bab II 2.6.

**f. Instrumen terintegrasi.**
Pre-test, Post-test, dan SUS berada di dalam game (menu *Mode Riset*), sehingga peneliti tidak perlu memindahkan responden ke aplikasi lain. Skor SUS dihitung otomatis dengan pola ganjil `(x-1)` dan genap `(5-x)`, dikali 2,5.

## 4. Catatan art pass v0.4 (peta & sprite)

Versi sebelumnya memakai palet acak per tile sehingga terlihat seperti prototipe kasar. Perbaikan yang dilakukan:

| Masalah lama | Perbaikan |
|---|---|
| Warna acak, NPC neon | Satu palet terbatas (3 tingkat per warna) untuk semua peta dan sprite |
| Empat bangunan identik | Empat tipe fasad (balai kota, toko berkanopi, rumah, penginapan) dengan warna khas |
| Tepi hutan seperti pagar | Kanopi digambar sebagai satu massa daun, batang hanya muncul sesekali |
| Air seperti ubin berulang | Noise multi-oktaf + gradasi kedalaman + buih tepi |
| Karakter melayang | Bayangan kontak untuk pemain, NPC, dan objek |
| Label nama ber-outline tebal | Label berlatar pil gelap, ukuran 8 px |
| Peta terasa kosong | Lampu, bangku, warung, papan, pot, batu, dan riak kolam |

Alur kerja aset: `./tools/regen.sh` (generator → hapus cache impor → `godot --import`). Tanpa langkah ini Godot tetap memakai tekstur lama di `.godot/imported/`.

## 5. Catatan UI pass v0.5 (antarmuka)

Setelah peta diperbaiki, layar-layar antarmuka diselaraskan agar tidak terasa seperti dua game berbeda.

| Layar | Perubahan |
|---|---|
| Layar judul | Panel gradien di kiri, chip "PROTOTIPE / v0.5", CTA emas, karakter dengan bayangan, deretan badge, baris kontrol di kaki layar |
| Panel tantangan | Kepala panel berisi chip wilayah + "TANTANGAN n DARI m", soal dalam kartu bergaris emas, opsi setinggi 50 px, tombol aksi rata kanan, tombol "Lanjut" berwarna |
| Dropdown query | Gaya dropdown sendiri: teks terang di atas latar gelap (sebelumnya teks gelap di latar gelap) |
| Kotak dialog | Potret NPC 56×84 di kiri, nama + peran di kepala, jarak baris 6 px, penanda "[E] lanjut" |
| HUD | Pil level/XP/keping data, label nama wilayah ber-outline agar terbaca di peta apa pun, tombol Peta/Menu lebih kecil |
| Peta wilayah | Kartu 3×2 dengan potongan gambar peta, status kunci, dan tombol "Masuk" berwarna |
| Pop-up badge | Tombol "Lanjut" jadi tombol utama, ikon lebih besar |

Komponen bersama ada di `scripts/ui/ui_kit.gd` (`panel_style`, `screen_style`, `chip`, `primary_button`, `dropdown`, `card`, `rule`), sehingga satu perubahan warna berlaku untuk semua layar.

## 6. Arsitektur

```
Main.tscn (Control)
└── main.gd            state: title | map | research | playing | ending
    ├── title.gd
    ├── map_select.gd
    ├── research.gd    4 tab: pre / post / sus / rekap
    ├── world.gd       dibangun dari assets/maps/<id>.json
    │   ├── player.gd
    │   ├── npc (Area2D)
    │   └── portal.gd
    ├── hud.gd
    ├── dialog_box.gd
    ├── puzzle_panel.gd   mcq | build | order | cipher | craft + bar HP boss
    ├── shop_panel.gd     toko Keping Data
    └── badge_popup.gd
Autoload: Game (game_state.gd) — XP, level, badge, progres, simpan/muat, rekap
Data: data/content.gd — seluruh konten teks & kunci jawaban
```

Seluruh konten berada di `data/content.gd`, terpisah dari logika. Menambah soal berarti menambah satu `Dictionary` — tidak perlu menyentuh kode UI. Ini memudahkan revisi setelah uji ahli/media.

## 7. Hasil uji fungsional

Uji integrasi otomatis (`godot --headless --path . res://scenes/AutoTest.tscn`) — **35 cek, 0 gagal**:

| No | Yang diuji | Hasil |
|---|---|---|
| 1 | Transisi judul → gameplay | OK |
| 2 | Dialog **tidak** terbuka otomatis saat masuk peta | OK |
| 3 | Kota Unggul memiliki 4 NPC | OK |
| 4 | Bicara dengan Kepala Kota membuka dialog misi | OK |
| 5 | Tekan `E` menutup dialog dan membuka tantangan | OK |
| 6 | Hutan memiliki 3 objek pencarian | OK |
| 7 | Memeriksa objek menampilkan teks temuan | OK |
| 8 | Objek membuka tantangan terkait | OK |
| 9 | Objek komponen menambah koleksi komponen | OK |
| 10 | Perakitan terkunci sebelum 3 komponen lengkap | OK |
| 11 | Tantangan `craft` dapat diselesaikan | OK |
| 12–13 | Seluruh 17 tantangan pada 6 wilayah dapat diselesaikan | OK |
| 14 | Badge tidak diberikan di tengah wilayah | OK |
| 15 | XP bertambah 30 per tantangan | OK |
| 16 | Level naik pada ambang 60 XP | OK |
| 17 | Wilayah level-2 terbuka tanpa badge | OK |
| 18 | Wilayah bersyarat badge tetap terkunci | OK |
| 19 | Badge diberikan setelah tantangan terakhir | OK |
| 20 | Wilayah berikutnya terbuka setelah badge | OK |
| 21 | Keping Data bertambah tiap tantangan | OK |
| 22 | Membeli Lensa mengurangi keping dan menambah item | OK |
| 23 | Lensa terpakai saat membuka petunjuk | OK |
| 24 | Boss The Source tampil dengan HP 3 | OK |
| 25 | Keputusan ending tersimpan | OK |
| 26 | Teks ending mengikuti keputusan pemain | OK |
| 27 | Simpan & muat mengembalikan progres | OK |

Uji manual pada build web: memuat layar judul, klik *Mulai Perjalanan*, berjalan ke NPC, dialog, panel tantangan, dan peta wilayah berjalan tanpa error konsol.

### Catatan art pass v0.6 (karakter)

Sprite karakter digambar ulang mengikuti gaya referensi tim: **outline tebal, cel-shading 3 tingkat, warna kontras tinggi, dan kain yang bergerak** (sabuk + syal). Ukuran naik dari 16x24 ke **24x32 px** agar ada ruang untuk detail tersebut; collision, ukuran tile, dan posisi NPC tidak berubah (titik tumpu kaki tetap di pixel yang sama).

| Sebelum (16x24) | Sesudah (24x32) |
|---|---|
| Kepala kotak, tanpa leher/dagu | Kepala dengan poni, cambang, leher, dagu, mulut |
| Badan satu blok, lengan menempel | Torso menyempit, kerah, bahu terang, lengan terpisah + tangan |
| Tanpa identitas | Jas gelap, **sabuk merah**, **syal krem**, ujung sabuk menjuntai |
| Warna flat | Tiap bahan 3 tingkat (base / shadow / highlight) |
| Kaki menyatu | Dua kaki dengan langkah bergantian + sepatu |
| Animasi = badan naik 1 px | Badan bergoyang, kaki melangkah, lengan mengayun |

Semua NPC memakai templat yang sama dengan palet berbeda (kepala kota ochre, peneliti hijau, penjaga baja, dan seterusnya), jadi gaya seluruh karakter konsisten. Perbandingan: `dokumentasi/karakter-before-after.png`.

Penilaian visual: sprite lama 4,5/10 -> sprite baru 8/10 (uji zoom di dalam game).

### Catatan art pass v0.7 (gaya kartun halus, referensi Citampi Stories)

Masukan penguji: "jangan kaya pixel". Penyebab kesan pixel ada tiga hal: ukuran tile 16 px, filter tekstur `nearest`, dan font piksel. Ketiganya diganti.

| Aspek | v0.6 (pixel) | v0.7 (kartun) |
|---|---|---|
| Tile peta | 16 px | **48 px** |
| Filter tekstur | `nearest` (tegas per pixel) | **`linear`** (halus) |
| Sprite karakter | 24×32 px, digambar per pixel | **96×144 px per frame**, chibi kartun |
| Kamera | zoom 2×, diam di tengah peta | zoom 1,5×, **mengikuti pemain** |
| Font UI | PressStart2P (piksel) | **Baloo 2** (membulat) |
| Latar judul | gradasi + siluet piksel | ilustrasi pemandangan kartun |

Cara aset dibuat:
1. Karakter (pemain + 4 NPC), gedung, pohon, semak, dan ilustrasi latar dibuat dengan bantuan model gambar AI, lalu latarnya dipotong otomatis (`rembg`, model `u2net`) sehingga menjadi PNG transparan.
2. Potongan itu dirakit jadi spritesheet 4 frame × 4 arah. Arah kiri memakai aset samping apa adanya, arah kanan adalah cerminnya. Animasi jalan dibuat dengan menggeser bagian bawah pinggul secara mendatar (shear 13°): baris tepat di pinggul tidak bergeser sama sekali sehingga tidak ada garis sambung, sedangkan telapak bergeser ±11 px antar frame dan badan ikut memantul.
3. Tanah (rumput, jalan tanah, air, plaza batu) tetap digambar prosedural dengan Python: tepi organik hasil mask + blur, bercak permukaan, bayangan kontak di bawah tiap properti.
4. Ikon objek 48×48 digambar vektor (supersample 4×) di `tools/icons48.py`.

### Perbaikan akhir v0.7 (kedalaman & posisi)

| Masalah yang dilaporkan penguji | Penyebab | Perbaikan |
|---|---|---|
| Pemain seperti "menginjak pohon" | pohon/gedung dibakar ke dalam gambar peta, jadi selalu di bawah pemain | properti dipindah jadi objek runtime (`*.props.json`, 251 objek di Kota Unggul) di node ber-`y_sort_enabled`; pemain kini lewat **di belakang** pohon |
| Kaki tidak terlihat melangkah | frame lama hanya menggeser badan 1–3 px | animasi 4 frame dengan geser mendatar di bawah pinggul (13°, telapak ±11 px) + badan memantul, 9 fps |
| Karakter tampak terpotong di pinggang | kesalahan potong: separuh kanan tubuh bawah diambil dengan lebar 0 px sehingga hilang | perbaikan rentang potong; kini seluruh tubuh bawah utuh, sambungan pinggul tidak bergerak |
| Kaki pemain tertutup semak saat mulai di Hutan | titik awal (21,19) berdiri tepat di belakang barisan semak | titik awal Hutan dipindah ke (18,18) yang bebas properti |
| Pemain bisa menembus NPC | NPC hanya sprite, tidak punya bodi tabrakan | tiap NPC diberi `StaticBody2D` 72×40 (menutup badan, bukan hanya kaki); bodi pemain 44×16 (diuji: pemain berhenti 58 px dari titik NPC, sprite tidak lagi bertumpuk, prompt interaksi tetap muncul) |
| NPC terlihat seperti gambar tempelan | potongan latar menyisakan "badge" oval di belakang tiap NPC | latar dipotong ulang dengan model **BiRefNet** (rembg) sehingga badge hilang; tepi menyatu dengan peta |
| NPC tampak kaku/diam | hanya satu frame, tidak ada animasi | animasi `idle_down` 2 frame (kolom 0 dan 2) pada 1,6 fps, jadi NPC ikut "bernapas" |
| Pemain berjalan ke pohon lalu "hilang" | kanopi pohon menutupi sprite pemain, dan objek Papan Data di Hutan berada di tengah rumpun pohon yang tidak bisa dicapai | kanopi pohon dibuat memudar (alpha 0,42) saat pemain lewat di belakangnya; Papan Data dipindah dari (8,13) ke (12,9) di area terbuka; Penjaga Gerbang dipindah dari (33,14) ke (33,13) karena (33,14) ternyata tile solid |
| Pemain bisa menembus gedung dan lampu | prop hanya gambar, tanpa bodi tabrakan | gedung (110×46) dan lampu (16×10) diberi `StaticBody2D`; pohon & semak sengaja tanpa tabrakan karena membuat jalur Hutan terputus, diganti efek kanopi memudar |
| NPC tertutup semak | NPC berdiri 1 petak dari pagar, jadi tertutup semak yang lebih dekat ke kamera | posisi 4 NPC digeser ke petak bebas properti (`data/content.gd`) |
| Objek interaktif bisa tertutup | urutan gambar objek sama dengan properti | objek diberi bias urutan +8 px tanpa mengubah posisi tampilan |
| Bercak tanah kosong di tengah kota | plaza kecil tanpa penghuni | ditambah lampu taman sebagai properti |
| Peta tampak hilang separuh (layar gelap) | sprite latar peta ber-`z_index -10`, jadi tergambar **di belakang** lapisan latar aplikasi | urutan z ditata: latar aplikasi −100, peta −50, bayangan −10, aktor 0 |

Batas jujur: hasil ini belum setara Citampi Stories yang seluruhnya digambar tangan. Yang sudah tercapai adalah hilangnya kesan pixel dan tampilan yang konsisten satu gaya. Bila tim ingin kualitas komersial, langkah berikutnya adalah mengganti sprite AI dengan gambar tangan (Krita/Figma) memakai ukuran kanvas yang sama (96×136 per frame, 48 px per tile) — kode game tidak perlu diubah.

## 8. Video

| Berkas | Isi | Durasi |
|---|---|---|
| `dokumentasi/gameplay-kota.mp4` | Satu wilayah: judul → hub → dialog → dua tantangan → peta | 46 dtk |
| `dokumentasi/gameplay-tour.mp4` | Dua wilayah: kota → peta → hutan → temukan objek → tantangan → peta | 70 dtk |

Keduanya direkam dari build Godot asli lewat Xvfb + ffmpeg (`tools/rekam.sh`), bukan animasi atau mockup.

## 9. Daftar tangkapan layar (folder `dokumentasi/`)

| Berkas | Isi | Saran caption laporan |
|---|---|---|
| `title.png` | Layar judul | "Antarmuka awal Terra Rebirth" |
| `map.png` | Peta wilayah | "Peta wilayah dengan status kunci berbasis level dan badge" |
| `hub.png` | Kota Unggul dengan 4 NPC | "Hub Kota Unggul: Kepala Kota, Penjaga Gerbang, Pedagang, Peneliti" |
| `play.png` | Eksplorasi Hutan Pengetahuan | "Antarmuka permainan: HUD, XP, dan lingkungan" |
| `cari.png` | Objek pencarian di Hutan | "Objek pencarian: Papan Data, Catatan Lapangan, Sampel Air" |
| `near.png` | Prompt interaksi NPC | "Prompt interaksi `[E] Bicara` saat mendekati NPC" |
| `dialog.png` | Dialog NPC | "Dialog naratif dan penyampaian misi" |
| `puzzle.png` | Tantangan SQL builder | "Tantangan Basis Data: menyusun query" |
| `order.png` | Tantangan urutan | "Tantangan Sistem Operasi: urutan penjadwalan proses" |
| `cipher.png` | Tantangan sandi Caesar | "Tantangan Kriptografi: memutar cakram sandi" |
| `craft.png` | Perakitan perangkat IoT | "Tantangan IoT: merakit perangkat dari komponen yang dikumpulkan" |
| `boss.png` | Tantangan boss The Source | "Tantangan akhir: bar HP boss The Source" |
| `pilih.png` | Keputusan akhir | "Keputusan pemain yang menentukan ending" |
| `shop.png` | Toko Keping Data | "Pedagang: menukar Keping Data dengan Lensa Analisis" |
| `badge.png` | Popup badge | "Pemberian badge setelah tantangan akhir wilayah" |
| `ending.png` | Layar penutup | "Layar akhir dan rekap statistik pemain" |
| `research.png` | Mode Riset | "Instrumen pre-test di dalam game" |
| `gameplay-kota.mp4` | Rekaman 46 detik: judul → Kota Unggul → jalan ke Kepala Kota → dialog → 2 tantangan → peta wilayah | "Rekaman alur permainan satu wilayah" |

## 10. Batasan prototipe (jujur untuk Bab III)

1. Belum ada efek suara dan musik latar.
2. Satu slot penyimpanan; belum ada manajemen beberapa pemain dalam satu perangkat (kode responden diisi manual di Mode Riset).
3. Soal masih 17 butir; validasi isi oleh ahli materi belum dilakukan.
4. Peta dibuat prosedural dari skrip, belum melalui Tiled seperti disebut pada Bab II — perlu disesuaikan di laporan (lihat catatan berikut).
5. Objek pencarian dan NPC didefinisikan di `data/content.gd`, bukan di dalam berkas peta, agar peta tidak perlu digambar ulang saat konten berubah.
6. Bar HP boss bersifat naratif (berkurang per tantangan selesai), belum ada pertarungan real-time.
7. Ekspor yang diuji: Web. Ekspor Windows/Linux memerlukan template ekspor Godot yang belum disertakan.

## 11. Catatan penyesuaian laporan

Bab II proposal menyebut **Godot + GDScript + Tiled + Dialogic**. Prototipe ini memakai Godot + GDScript, tetapi peta dibangun dari JSON hasil generator dan dialog ditulis sebagai komponen kustom. Dua pilihan untuk laporan:

- **Diubah**: tulis "peta dan dialog diimplementasikan sebagai modul kustom di dalam Godot", atau
- **Disamakan**: tambahkan konversi peta ke `.tmx` dan pasang add-on Dialogic pada revisi berikutnya.

Yang penting, klaim teknologi di Bab II harus sama dengan yang benar-benar dipakai — inilah jenis ketidaksesuaian yang paling mudah ditembak saat sidang.
