# Dokumentasi Prototipe Terra Rebirth v0.8 (Godot)

Dokumen ini menjelaskan prototipe yang dibangun dan bagaimana ia menjawab poin-poin revisi pada Bab I dan Bab III proposal.

---

## 1. Ringkasan

| Aspek | Keterangan |
|---|---|
| Judul produk | Terra Rebirth |
| Jenis | RPG edukasi 2D top-down, single player |
| Mesin | Godot 4.7 (GDScript), renderer Compatibility |
| Resolusi | 1280×720, stretch `canvas_items` / aspect `keep` |
| Durasi main | ± 35–50 menit untuk 50 tantangan (22 inti + 8 puzzle bank + 20 soal bank) |
| Materi | Basis Data, Sistem Operasi, Kriptografi, Internet of Things |
| Platform | Web (WebAssembly), Windows/Linux (ekspor desktop) |
| Instrumen | Post-test 20 soal + SUS 10 butir (one-group posttest-only), rekap otomatis + ekspor CSV |

## 2. Pemetaan materi → tantangan

| Wilayah | Bidang | Tantangan | Tipe |
|---|---|---|---|
| Kota Unggul (Map 1) | Tutorial & hub, tanpa badge | Aturan Perjalanan; Arti Sebuah Badge | mcq, mcq |
| Hutan Pengetahuan (Map 2) | Basis Data → Badge Nature | Kunci Tabel; Relasi Satu ke Banyak; Menyusun Query | build (SQL), order, build (SQL) |
| Pabrik Limbah (Map 3) | Sistem Operasi → Badge Core | Keadaan Proses; Urutan Penjadwalan; Memilih Penjadwalan; Sumber Daya Bersama | order, order, order, order |
| Candi Kuno (Map 4) | Kriptografi → Badge Cipher | Mengenali Sandi; Memutar Cakram; Analisis Frekuensi; Memilih Metode; Jejak Hash | cipher, cipher, order, build, cipher |
| Danau Citra (Map 5) | IoT → Badge Aqua | Memilih Komponen; Fungsi Daya dan Pengolahan; Merakit Perangkat; Alur Data ke Dasbor | craft, order, **wire**, order |
| The Source (Map 6) | Integrasi 4 bidang, tanpa badge | Ujian Data; Ujian Sandi; Ujian Sistem; Ujian Perangkat | mcq (boss HP 4) |

Wilayah materi (Map 2–Map 5) masing-masing menambah **5 soal pilihan ganda dari bank soal** yang
dibuka lewat **Terminal Soal**, sehingga total 22 tantangan inti + 8 puzzle bank + 20 soal bank = **50 tantangan**
saat dimainkan. Soal bank diundi per peserta dan disimpan pada `bank_picks`, jadi soal tidak
berganti saat terminal dibuka ulang.

Setiap tantangan memiliki pembahasan singkat yang muncul setelah dijawab, sehingga berfungsi sebagai *feedback* formatif — bukan sekadar benar/salah.

**Cara tantangan dibuka (eksplorasi, bukan menu):**

Sejak revisi, alur tiap wilayah punya dua lapis yang jelas: **belajar dari NPC**, lalu **mengerjakan
tantangan dari benda di peta**. NPC tidak lagi membuka tantangan.

| Wilayah | Objek pemicu tantangan | Catatan |
|---|---|---|
| Kota Unggul | Papan Pengumuman → Aturan Perjalanan; Buku Aturan → Arti Sebuah Badge | 2 objek, tanpa bank soal |
| Hutan Pengetahuan | Papan Data, Buku Registri, Catatan Lapangan → 3 tantangan inti; **Terminal Soal** → 5 soal bank | |
| Pabrik Limbah | Panel Proses, Ruang Kendali, Mesin Utama, Jadwal Lini → 4 tantangan inti; **Terminal Soal** → 5 soal bank | |
| Candi Kuno | Prasasti Tua, Meja Sandi, Relief Sandi, Gapura Terkunci, Sumur Pesan → 5 tantangan inti; **Terminal Soal** → 5 soal bank | |
| Danau Citra | Dermaga Sensor, Meja Perakitan, Menara Sinyal, Pos Pemantau → 4 tantangan inti; **Terminal Soal** → 5 soal bank | Tantangan perakitan terkunci sampai 4 komponen perangkat (sensor pH air, papan rangkaian & kabel jumper, mikrokontroler ber-WiFi, sumber daya) **dibeli di toko Pedagang, Kota Unggul** |
| The Source | Inti Sumber, Pilar Data, Altar Sandi, Gerbang Akhir → 4 ujian integrasi melawan boss | |

**NPC pengajar** ada tiga di setiap wilayah selain Kota Unggul (Kota Unggul empat, karena satu di
antaranya pedagang). Semua NPC menyampaikan materi wilayahnya; rincian ada di bagian 3g.

## 3. Mekanik yang menjawab revisi proposal

**a. Badge tidak lagi diberikan setiap jawaban benar.**
Badge hanya diberikan sekali, setelah tantangan terakhir pada suatu wilayah selesai (`Game.complete_challenge` memeriksa `is_map_cleared`). Ini menghilangkan inkonsistensi *activity diagram* yang ditunjukkan dosen.

**b. Gating tunggal: badge (tanpa level/XP).**
Wilayah berikutnya hanya terbuka bila badge wilayah sebelumnya sudah dimiliki, sesuai Bab II 2.5 dan Tabel 2.5 ("badge sebagai kunci akses, bukan atribut"). Kartu peta dan penjaga gerbang menampilkan alasan penguncian, misalnya "Terkunci — selesaikan seluruh quest Hutan Pengetahuan". Level dan XP dihapus seluruhnya agar tidak ada syarat progres ganda yang bertentangan dengan rancangan.

**c. Progres terukur tanpa angka XP.**
Satu-satunya penanda progres adalah **4 badge** (Nature, Core, Cipher, Aqua) dan jumlah tantangan tiap map (`%d/%d tantangan · %d/4 badge`). Map 1 (hub) dan Map 6 (final) tidak memberi badge. Data progres disimpan otomatis (`user://save_terra.json`).

**d. Eksplorasi dan ekonomi kecil.**
Pemain harus berjalan mendekati NPC/objek (jarak < 26 px) lalu menekan `E`; dialog tidak lagi terbuka otomatis. Setiap puzzle di Map 2-Map 5 selesai memberi **+10 uang** (Map 1 dan Map 6 tidak memberi uang). Uang dibelanjakan di **Pedagang**: 4 komponen perangkat (total 120 uang) wajib dibeli sebelum perakitan Map 5, dan **Lensa Analisis** (20 uang) membuka petunjuk. Ini menambahkan lapisan *resource management* sederhana seperti pada RPG, tanpa mengganggu tujuan pembelajaran.

**e. Tantangan akhir dan ending bercabang.**
The Source menampilkan **bar HP boss** yang berkurang tiap ujian integrasi yang lulus (4 → 0). Setelah seluruh ujian selesai, pemain mengerjakan **post-test dan SUS**, lalu memilih salah satu dari dua keputusan (menyegel sumber atau menyusun ulang protokol); teks layar penutup menyesuaikan pilihan tersebut — sesuai Bab II 2.6.

**f. Instrumen terintegrasi, tanpa pre-test.**
Rancangan penelitian adalah *one-group posttest-only* (Bab III 3.1), sehingga hanya **post-test 20 soal** (5 soal tiap materi) dan **SUS 10 butir** yang dipakai; keduanya berada di dalam game (`scripts/ui/asesmen.gd`) dan terbuka otomatis setelah Map 6 selesai. Nilai post-test = benar/20 × 100 dengan batas tuntas **70**; skor SUS memakai pola ganjil `(x-1)` dan genap `(5-x)` dikali 2,5, dibandingkan dengan acuan **68,0** (Hyzy dkk., 2022). Data peserta (kode, tanggal, durasi, nilai, benar per materi, SUS) disimpan di `user://records_terra.json` dan dapat diekspor ke CSV.

**g. Tiga NPC pengajar di setiap wilayah (tambahan sesuai arahan dosen penguji).**
Setiap wilayah selain Kota Unggul punya **tiga NPC**, dan semuanya mengajar — bukan hanya satu tokoh
istimewa. Materi tidak ditulis ulang di dialog: `_lesson_lines()` di `scripts/main.gd` menyusun baris
percakapan dari `lesson`/`explain` setiap tantangan wilayah tersebut, sehingga materi NPC selalu
sama dengan yang diujikan. Dialog ditutup dengan kalimat yang menegaskan bahwa tantangan **tidak**
dimulai dari NPC, melainkan dari benda bertanda `?` di peta.

**h. Quest dimulai dari objek di peta (tambahan sesuai arahan dosen penguji).**
Memisahkan "belajar dari orang" dan "mengerjakan dari benda" membuat pemain melewati materi lebih
dulu, dan memberi alasan untuk menjelajah. Objek membuka tantangan yang tertaut **setelah** dialog
objek selesai (`_on_inspect_object` → `_resolve_object`). Objek yang tantangannya sudah selesai tidak
membuka apa pun. Untuk wilayah materi, **Terminal Soal** membuka soal bank berikutnya yang belum
selesai (`_open_next_bank_challenge`), dan menyelesaikan satu soal **tidak** otomatis membuka soal
berikutnya — pemain harus kembali ke terminal.

**i. Nyawa tiga per wilayah; reset menghapus progres, bukan pembelian.**
Aturan lengkapnya:

- Setiap wilayah punya **3 nyawa**, ditampilkan di HUD sebagai `Nyawa n/3` (berlaku juga di Kota
  Unggul dan The Source, bukan hanya wilayah ber-bank soal).
- Satu jawaban salah memotong satu nyawa, tetapi **satu tantangan hanya bisa memotong satu nyawa**
  (`penalized[cid]`), supaya satu soal sulit tidak menghabiskan wilayah.
- Ketika nyawa mencapai 0 (`Game._fail_map`): **seluruh progres tantangan dan badge di semua wilayah
  dihapus**, undian soal, status post-test/SUS, dan pilihan ending ikut dikosongkan, lalu pemain
  dikembalikan ke Kota Unggul. Panel tantangan ditutup dan muncul pesan: *"Nyawa habis — semua
  progres dan badge direset. Uang dan barang tetap tersimpan."*
- Yang **tetap** dimiliki pemain: uang, item (mis. Lensa Analisis), komponen perangkat yang sudah
  dibeli, dan kode peserta. Jadi perakitan di Danau Citra tidak perlu membeli ulang.
- **Koin hanya dibayar sekali per tantangan** (`earned`), termasuk setelah reset — mengulang wilayah
  tidak menjadi cara menambah uang tanpa batas.
- Setelah reset, penguncian wilayah kembali mengikuti badge: hanya Kota Unggul terbuka, dan pemain
  dapat menyelesaikan Kota lalu masuk Hutan Pengetahuan seperti pertama kali.

**j. Dua ragam quest: kuis pilihan ganda dan puzzle; setiap NPC punya cerita sendiri.**

- **Kuis pilihan ganda** (Terminal Soal): 5 soal acak dari bank 50 soal materi tersebut. Jawaban
  salah memotong **1 nyawa**.
- **Puzzle** (benda rusak di peta atau NPC pendamping): diambil acak dari **bank 10 puzzle per
  materi** (`data/puzzle_bank.gd`), ragamnya **mengurutkan langkah/sintaks** (`order`) dan
  **isi bagian rumpang** (`fill`). Salah menjawab **tidak** memotong satu nyawa, tetapi langsung
  menghabiskan nyawa wilayah (`fatal`), sehingga progres direset dan pemain kembali ke Kota Unggul.
- Setiap wilayah materi punya **2 slot puzzle**: satu ditawarkan NPC yang berbeda dari NPC pengajar
  (mis. Asisten Arsip di Hutan), satu dibuka dari **benda rusak** yang diperbaiki (Pompa Rusak,
  Katup Macet, Lonceng Retak, Pipa Bocor).
- Seluruh **19 NPC punya cerita sendiri** (`story`) yang ditampilkan lebih dulu setiap kali diajak
  bicara, sehingga dunia terasa hidup; materi tetap disampaikan sesudahnya.

**k. Tampilan panel menyatu dengan dunia hutan (bukan UI modern).**

- Seluruh layar dalam game memakai tema **papan kayu + kertas lusuh**: bingkai kayu berpakuh dengan
  lumut di sudut, pita kayu untuk kepala panel, kertas berserat untuk soal dan pilihan jawaban, serta
  tombol papan kayu dan tombol daun.
- Judul dan penanda bagian memakai huruf pixel (`PressStart2P`), teks isi tetap huruf bulat agar
  nyaman dibaca.
- Nyawa wilayah tampil sebagai **tiga hati** di kepala panel, bukan angka saja.
- Tekstur dibuat ulang lewat `tools/gen_ui_textures.py` (9-patch 4x) sehingga bisa disesuaikan tanpa
  aplikasi pengolah gambar.
- Dua koreksi setelah pemeriksaan gambar: (1) bayangan huruf pixel diturunkan menjadi **1 px** karena
  offset 2 px pada huruf kecil terbaca seperti teks dobel; (2) butir/serat tekstur hanya digambar di
  **cincin tepi** tekstur, karena bagian tengah 9-patch diregangkan sehingga butir berubah menjadi garis
  putus-putus atau pola berulang yang menutupi huruf.
- **Tema per wilayah.** Panel kuis dan puzzle memakai bahan wilayahnya sendiri, bukan satu gaya
  seragam, supaya terasa bagian dari peta:

  | Wilayah | Bingkai | Kertas soal | Warna aksen |
  |---|---|---|---|
  | 01 Kota Unggul | kayu jati + paku emas | kertas tua kekuningan | emas |
  | 02 Hutan Pengetahuan | kayu berlumut | kertas daun kehijauan | hijau daun |
  | 03 Pabrik Limbah | pelat besi + rivet + karat | pelat logam abu terang | jingga karat |
  | 04 Candi Kuno | batu pahat keemasan | kertas pasir | kuning batu |
  | 05 Danau Citra | kayu apung kebiruan | kertas basah bertetes | biru air |
  | 06 The Source | obsidian berserat kristal | kertas kristal keunguan | ungu |

  Warna huruf soal ikut menyesuaikan kertas tiap wilayah, dan tombol papan memakai warna bahan
  wilayah yang sama. Tema dipasang lewat `UiKit.set_theme(map_id)` saat panel dibuka.

**l. Layar jeda, jurnal misi, dan penanda tujuan.**

- **Layar jeda (`scripts/ui/pause_menu.gd`).** `Esc` saat bermain membuka panel jeda; pohon scene
  dijeda sehingga pemain benar-benar berhenti. Isinya penggeser **Musik**, **Efek Suara** (ujung
  kirinya **Mati**), dan **Kecepatan Teks** (0,5x–2,0x), lalu tombol **Lanjutkan**, **Jurnal Misi**, **Ulangi Wilayah Ini**,
  dan **Kembali ke Menu Utama**. Ketiga setelan disimpan bersama simpanan permainan (`bgm_db`,
  `sfx_db`, `text_speed`), jadi tidak perlu diatur ulang tiap sesi. Tombol Peta Wilayah tetap di `M`,
  sedangkan `Esc` tidak lagi melompat ke peta.
- **Ulangi wilayah** memanggil `Game.restart_map(map_id)`: progres dan nyawa wilayah itu dikembalikan,
  tetapi **uang, barang, komponen, dan badge tetap**. Tombolnya meminta penegasan sekali tekan
  ("Yakin? Progres wilayah ini direset") supaya tidak terpencet tanpa sengaja.
- **Jurnal misi (`scripts/screens/journal.gd`).** Satu layar dua kolom: kiri daftar enam wilayah
  beserta `selesai/total` dan status kunci; kanan rincian tantangan wilayah terpilih. Tiap baris
  menuliskan status (`OK` atau nomor), judul tantangan, dan **pemicunya** — nama benda atau NPC yang
  harus ditemui. Data pemicu berasal dari `Content.trigger_of(map_id, challenge_id)`, yang mencari
  objek ber-`challenge` sama, lalu objek `bank`/`puzzle` wilayah, lalu NPC pemberi quest. Jurnal bisa
  dibuka dengan `J` saat bermain, dari layar jeda, atau dari Peta Wilayah.
- **Penanda tujuan.** Tombol **Tandai** di jurnal menaruh belah ketupat emas berdenyut di atas benda
  atau NPC pemicu (`world.mark_objective()`), dan panah kompas HUD menunjuk ke sana sampai pemain
  mendekat (±130 px). Ini menjawab keluhan "harus ke mana?" tanpa memaksa pemain menghafal koordinat.
- **Mode Riset dibuka dengan Ctrl+R.** Tombolnya tidak lagi dipasang di menu utama karena layar itu berisi data pengujian (peserta, nilai, SUS, durasi), bukan fitur pemain; dari layar judul atau layar Peta Wilayah tekan **Ctrl+R**. Kodenya, ekspor CSV, dan ringkasan rata-rata tetap utuh untuk keperluan Bab IV.
- **Layar judul diringkas.** Hanya tersisa label *GAME EDUKASI*, judul, satu baris tagline, empat tombol (Mulai Perjalanan, Lanjutkan, Peta Wilayah, Pengaturan), dan nomor versi kecil di pojok kiri bawah. Baris identitas kelompok, kata *prototipe*, dan daftar tombol tidak lagi ditulis di judul.
- **Daftar kontrol pindah ke layar jeda.** Blok **KONTROL** berisi `WASD / panah  jalan · E interaksi · J jurnal · M peta · Esc menu`. Ini sekaligus membetulkan dua kekurangan baris lama: panah tidak pernah disebut padahal berfungsi, dan tombol J (jurnal) belum tertulis di mana pun. Blok ini disembunyikan saat panel dipakai sebagai layar pengaturan dari judul.
- **Pengaturan di layar judul.** Tombol **Pengaturan** di bawah tombol Peta Wilayah membuka panel yang sama dalam mode ringkas (tiga penggeser + Kembali), sehingga pemain bisa menyetel bunyi sebelum masuk peta. Setelan disimpan di berkas terpisah `user://settings_terra.json`, bukan di simpanan permainan — kalau ikut simpanan, pemain yang baru menyetel volume akan dianggap sudah punya simpanan dan tombol "Lanjutkan" menyala padahal belum pernah bermain.
- **Koleksi badge.** Angka badge di HUD (`0 / 4  ›`) bisa diklik dan membuka layar berisi empat kartu: ikon, nama badge, asal wilayah, jumlah tantangan, dan status **Sudah dikumpulkan** atau **Selesaikan n/N tantangan …**. Badge yang belum didapat ditampilkan redup. Jumlah tantangan diambil dari `Game.map_total()`, bukan dari data peta mentah, supaya cocok dengan angka di HUD (10/11/12/11).
- Pesan singkat (toast) disembunyikan saat jurnal/jeda dibuka dan lapisan jurnal berada di atas HUD,
  supaya tidak ada tulisan yang menembus panel — kesalahan yang sama seperti kasus toast di Peta
  Wilayah.

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
| HUD | Pil uang dan badge (tanpa level/XP), label nama wilayah ber-outline agar terbaca di peta apa pun, tombol Peta/Menu lebih kecil |
| Peta wilayah | Kartu 3×2 dengan potongan gambar peta, status kunci, dan tombol "Masuk" berwarna |
| Pop-up badge | Tombol "Lanjut" jadi tombol utama, ikon lebih besar |

Komponen bersama ada di `scripts/ui/ui_kit.gd` (`panel_style`, `screen_style`, `chip`, `primary_button`, `dropdown`, `card`, `rule`), sehingga satu perubahan warna berlaku untuk semua layar.

## 6. Arsitektur

```
Main.tscn (Control)
└── main.gd            state: title | map | research | playing | ending
    ├── title.gd
    ├── map_select.gd
    ├── research.gd    rekap peserta + ringkasan rata-rata + ekspor CSV + asesmen
    ├── world.gd       dibangun dari assets/maps/<id>.json
    │   ├── player.gd
    │   ├── npc (Area2D)
    │   └── portal.gd
    ├── hud.gd
    ├── dialog_box.gd
    ├── puzzle_panel.gd   mcq | build | order | fill | cipher | craft | wire + bar HP boss
    ├── shop_panel.gd     toko (uang)
    └── badge_popup.gd
Autoload: Game (game_state.gd) — badge, progres, simpan/muat, rekap peserta, audio
Audio: assets/audio/*.wav (sintesis tools/gen_audio.py) — bgm_explore/bgm_final,
  sfx klik/ok/salah/koin/badge/portal; penggeser volume di layar jeda
Data: data/content.gd — seluruh konten teks & kunci jawaban
```

Seluruh konten berada di `data/content.gd`, terpisah dari logika. Menambah soal berarti menambah satu `Dictionary` — tidak perlu menyentuh kode UI. Ini memudahkan revisi setelah uji ahli/media.

## 7. Hasil uji fungsional

Uji integrasi otomatis (`godot --headless --path . res://scenes/AutoTest.tscn`) — **284 cek, 0 gagal**:

| No | Yang diuji | Hasil |
|---|---|---|
| 1 | Transisi judul → gameplay; dialog **tidak** terbuka otomatis saat masuk peta | OK |
| 2 | Kota Unggul: 4 NPC, NPC pemberi tugas terdaftar, `E` menutup dialog lalu membuka tantangan | OK |
| 3 | Toko: membeli komponen (uang berkurang sesuai harga), Lensa Analisis ditahan selama komponen belum lengkap | OK |
| 4 | Penjaga gerbang menyebut syarat badge; map terkunci menampilkan alasan | OK |
| 5 | Hutan: 5 objek pencarian, temuan tampil lalu tantangan terbuka | OK |
| 6 | Danau: tidak ada komponen di peta; perakitan terkunci sebelum 4 komponen dibeli di toko | OK |
| 7 | Seluruh 50 tantangan (22 inti + 8 puzzle bank + 20 soal bank) pada 6 map dapat diselesaikan | OK |
| 8 | Satu quest selesai **belum** memberi badge; satu map hanya memberi satu badge | OK |
| 9 | Badge diberikan setelah seluruh quest satu map selesai dan membuka map berikutnya | OK |
| 10 | Map 1 (hub) tidak memberi badge, tetapi membuka Map 2 setelah quest pengantar | OK |
| 11 | Post-test: 20 soal diundi dari bank 200 soal (5 tiap materi), 4 opsi, kunci valid | OK |
| 12 | Penilaian: 20 benar = 100 (tuntas), 10 benar = 50 (belum tuntas) | OK |
| 13 | SUS: jawaban paling positif 100, tengah 75, paling negatif 0 | OK |
| 14 | Panel asesmen: mulai dari halaman kode peserta, ringkasan bila sudah selesai, bisa ditutup | OK |
| 15 | Data peserta tersimpan (kode, tanggal, nilai, SUS, durasi, benar per materi) | OK |
| 16 | Ekspor CSV: header benar, kolom SUS kosong bila kuesioner belum diisi | OK |
| 17 | Boss The Source tampil dengan HP 4 | OK |
| 18 | Keputusan ending tersimpan dan teks ending mengikuti pilihan pemain | OK |
| 19 | Simpan & muat mengembalikan badge, progres tantangan, dan status asesmen | OK |
| 20 | Kasus batas: batal asesmen, post-test tanpa SUS, SUS menyusul, kode peserta ganda, SUS tidak lengkap, tantangan ganda, durasi lintas sesi, jawaban kosong, berkas rekap rusak, peserta baru | OK |
| 21 | Layar jeda: `Esc` membuka jeda (bukan peta), pohon scene benar-benar berhenti, ketiga penggeser tersimpan di berkas setelan | OK |
| 22 | Ulangi wilayah: progres dan nyawa wilayah kembali, uang/inventori/komponen/badge tetap | OK |
| 23 | Jurnal misi: enam wilayah terdaftar, jumlah baris sama dengan jumlah tantangan, tiap baris punya pemicu yang valid (benda/NPC), tidak ada quest yatim | OK |
| 24 | Setelan di layar judul: tersimpan di berkas sendiri, terbaca lagi saat game dibuka, dan tidak membuat tombol "Lanjutkan" menyala | OK |
| 25 | Koleksi badge: empat kartu, status didapat/belum, jumlah tantangan tiap wilayah sesuai HUD, bisa ditutup dan permainan lanjut | OK |
| 26 | Ringkasan Mode Riset: rata-rata post-test, ketuntasan (n/N dan %), rata-rata SUS (hanya yang mengisi), rata-rata durasi, rata-rata benar per materi, dan data kosong tidak error | OK |
| 27 | Layar judul bersih: tidak ada tombol Mode Riset, tidak ada baris kontrol/identitas/kata prototipe, dan Ctrl+R dari judul membuka Mode Riset lalu kembali ke judul | OK |
| 28 | Layar jeda memuat daftar kontrol (WASD/panah, E, J, M, Esc), daftar itu disembunyikan di layar pengaturan, dan HUD hilang saat jeda lalu muncul lagi setelah ditutup | OK |
| 29 | Puzzle kabel IoT (wire): papan menampilkan 6 komponen bergambar (4 asli + 2 pengganggu, tanpa pembeda warna), kertas soal besar disembunyikan, penghitung kabel dan lampu perangkat tampil serta bertambah, klik dua pin memasang kabel, kurang kabel hanya diperingatkan tanpa hukuman, klik ulang pasangan atau tombol cabut melepas kabel, salah sambung menggagalkan wilayah (fatal), dan sambungan benar dalam urutan klik terbalik menyalakan perangkat | OK |
| 30 | Lensa Analisis: keenam jenis tantangan (pilihan ganda, SQL, urutan, sandi, rakit komponen, kabel IoT) memberi satu kalimat petunjuk, isi rumpang punya petunjuk dari kata jawaban, menekan Lensa tanpa persediaan tidak memotong apa pun, Lensa hanya terpakai saat petunjuknya muncul, dan soal tanpa bahan petunjuk tidak memotong Lensa | OK |
| 31 | NPC pengajar: setiap wilayah punya NPC, Kota Unggul tepat 4, nama unik, tiap NPC punya cerita sendiri, aksi yang dipanggil dikenal mesin dialog, dan nama yang disebut di dialog benar-benar ada di peta | OK |
| 32 | Audit tata letak: tidak ada teks terpotong, tidak ada kontrol keluar jendela 1280×720, isi gulir tidak lebih lebar dari wadahnya, enam tombol kartu peta rata 2 baris × 3, label benda/NPC di enam peta tidak saling menimpa, dan seluruh 50 panel tantangan muat tanpa menggulir | OK |
| 33 | Tampilan NPC di enam peta: tinggi gambar seragam, kaki menyentuh titik pijak, nama tepat di bawah kaki, tanda seru di tengah atas kepala, tidak ada label benda yang menutupi badan, tidak berdiri di dinding/air, dan tidak tertutup kanopi pohon | OK |
| 34 | Pohon di depan pemain memudar (tembus pandang) sehingga karakter tidak hilang di balik daun | OK |
| 35 | Benda yang dicari (papan, buku, terminal) tidak tertutup kanopi pohon di peta mana pun | OK |
| 36 | Urutan gambar (siapa menimpa siapa): titik urut seluruh aktor — NPC, benda, dan pohon — berada tepat di kakinya, sehingga pemain yang lewat di depan benar-benar tergambar di depan | OK |
| 37 | Animasi NPC: setiap NPC punya minimal dua gambar, ukurannya sama, gambarnya tidak kembar, dan animasinya benar-benar diputar | OK |
| 38 | Portal: setiap peta punya portal dan status kuncinya sesuai kemajuan; tampilan terkunci (bergembok, cahaya redup) berbeda jelas dari terbuka (bercahaya, berkilau) — status diuji otomatis, rupa diperiksa dari tangkapan layar | OK |

Sepuluh kasus batas diuji khusus karena paling mudah rusak saat konten direvisi:

1. **Batal di halaman kode peserta** — tidak dianggap selesai dan tidak menulis baris data.
2. **Post-test dikirim, SUS belum** — baris peserta tetap tersimpan dengan kolom SUS kosong, bukan angka palsu.
3. **SUS dikirim setelahnya** — baris yang sama diperbarui, bukan ditambah (satu peserta = satu baris).
4. **Kode peserta berbeda** — menjadi baris baru di rekap.
5. **SUS tidak lengkap** — ditolak, skor tidak dihitung.
6. **Tantangan diselesaikan dua kali** — uang tidak bertambah dua kali.
7. **Durasi lintas sesi** — waktu dihitung dari akumulasi bermain, bukan selisih jam dinding (jeda antar sesi tidak ikut terhitung).
8. **Jawaban post-test kosong** — dinilai 0 dan tidak tuntas, bukan error.
9. **Berkas rekap rusak** — dibaca sebagai daftar kosong, game tetap berjalan.
10. **Peserta baru** — `reset` mengosongkan kode peserta agar data peserta sebelumnya tidak tertimpa.

Audit isi konten (`godot --headless --script res://scripts/audit_konten.gd`) — **1686 cek, 0 gagal**: struktur 6 peta, 50 tantangan (puzzle konsep + 5 soal bank per wilayah materi), bank soal 200 butir (50 per materi: id unik, 4 opsi unik, kunci valid, pembahasan, sebaran kunci), undian post-test 20 soal (5 per materi, stabil untuk peserta yang sama, berbeda antar peserta), aturan 3 nyawa per wilayah, kelengkapan kunci jawaban tiap tantangan, tipe tantangan (`mcq`/`build`/`order`/`cipher`/`craft`/`wire`/`fill`) beserta data yang dibutuhkan tiap tipe, 20 soal post-test (sebaran kunci A/B/C/D = 5/5/5/5, tiap kunci menunjuk opsi yang valid), 10 butir SUS (polaritas bergantian positif–negatif), sandi Caesar (ciphertext digeser 3 menghasilkan kata yang diharapkan), keterjangkauan seluruh NPC/objek/portal dari titik awal tiap peta, keberadaan seluruh berkas aset (tilemap, sprite NPC, ikon badge), rujukan silang objek → tantangan dan badge → HUD, serta aturan toko: 4 komponen perangkat, harga, dan uang yang tersedia; ditambah pemeriksaan 19 NPC pengajar (tiap wilayah punya NPC, Kota Unggul tepat 4, cerita tiap NPC tidak kosong dan tidak kembar, aksi dialog dikenal, nama yang disebut ada di peta) dan ketersediaan bahan petunjuk Lensa untuk ketujuh tipe tantangan.

Uji memakai berkas sendiri (`records_autotest.json`, `save_autotest.json`) dan menghapusnya setelah selesai, sehingga menjalankan tes tidak pernah menghapus `records_terra.json` berisi data peserta asli.

Audit yang sama dijalankan juga pada build web hasil ekspor (`godot --headless --main-pack build/web/index.pck --script res://scripts/audit_konten.gd`) untuk memastikan build yang diunggah benar-benar memuat konten terbaru, bukan versi lama; jumlah ceknya mengikuti versi konten yang diekspor.

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
| Pabrik Limbah nyaris tanpa penghuni (0 properti) | peta 3 hanya punya grid + jalur; aset properti industri belum pernah dibuat | dibuat 16 aset prosedural (`tools/gen_props.py`) + penata otomatis (`tools/place_props.py`): aula pabrik, cerobong, tangki, mesin, konveyor, pipa, peti, puing → **55 properti** |
| Candi Cipher & The Source terasa kosong | masing-masing hanya 20 dan 14 semak/pilar | pilar utuh & patah, relief, puing, rak server, terminal, pylon, dan **monolit inti** sebagai landmark → **60** dan **48 properti** |
| Pemain tidak tahu harus ke mana | objek/NPC hanya ditandai `!`, peta 40×22 terlalu luas untuk dicari manual | panah tujuan di tepi layar: arah + nama + jarak meter, hilang saat sudah dekat atau saat panel soal terbuka |
| Ujung jalur terasa buntu tanpa alasan | jalur bercabang berakhir di rumput kosong | ujung jalur yang benar-benar buntu diberi penutup visual (peti/puing) |
| Peta tampak hilang separuh (layar gelap) | sprite latar peta ber-`z_index -10`, jadi tergambar **di belakang** lapisan latar aplikasi | urutan z ditata: latar aplikasi −100, peta −50, bayangan −10, aktor 0 |

Batas jujur: hasil ini belum setara Citampi Stories yang seluruhnya digambar tangan. Yang sudah tercapai adalah hilangnya kesan pixel dan tampilan yang konsisten satu gaya. Bila tim ingin kualitas komersial, langkah berikutnya adalah mengganti sprite AI dengan gambar tangan (Krita/Figma) memakai ukuran kanvas yang sama (96×136 per frame, 48 px per tile) — kode game tidak perlu diubah.

### Art pass v0.8 (audio & NPC)

- Musik sintetis `bgm_explore.wav` dipakai di lima wilayah; `bgm_final.wav` dipakai di The Source.
- Efek klik, jawaban benar/salah, koin, badge, dan portal tersambung ke gameplay; besar bunyi diatur lewat penggeser **Musik** dan **Efek Suara** di layar jeda; ujung kiri penggeser bertanda **Mati** sehingga game bisa dibisukan tanpa tombol terpisah di HUD.
- NPC membalik arah hadap kiri/kanan sesuai posisi pemain (sprite belum punya pose samping).
- Plang TOKO kini ditempatkan di depan kios, tidak lagi terbalik oleh variasi flip properti.
- Dermaga Danau Citra mendapat tiang penyangga vertikal; diverifikasi pada gambar sumber peta.

## 8. Video

| Berkas | Isi | Durasi |
|---|---|---|
| `dokumentasi/gameplay-lengkap-6map.mp4` | **Permainan penuh 6 wilayah** → post-test 20 soal → SUS 10 butir → keputusan akhir → penutup | 7 mnt 25 dtk |
| `dokumentasi/gameplay-kota.mp4` | Satu wilayah: judul → hub → dialog → dua tantangan → peta | 52 dtk |
| `dokumentasi/gameplay-toko-rakit.mp4` | Potongan fokus: toko Pedagang (4 komponen perangkat) → perakitan perangkat di Danau Citra | 22 dtk |
| `dokumentasi/gameplay-tour.mp4` | Dua wilayah: kota → peta → hutan → temukan objek → tantangan → peta | 78 dtk |
| `dokumentasi/gameplay-terbaru.mp4` | Build terkini (dengan musik): kota → toko Pedagang → jalan ke gerbang (terkunci) → quest selesai → gerbang terbuka → masuk Hutan | 57 dtk |

Ketiganya direkam dari build Godot asli lewat Xvfb + ffmpeg (`tools/rekam.sh`), bukan animasi atau mockup. Video permainan penuh memakai mode demo `full` yang memainkan 50 tantangan, post-test, dan SUS secara otomatis (50/50 tantangan, 4/4 badge, nilai post-test 100, SUS 75).

## 9. Daftar tangkapan layar (folder `dokumentasi/`)

| Berkas | Isi | Saran caption laporan |
|---|---|---|
| `title.png` | Layar judul | "Antarmuka awal Terra Rebirth" |
| `map.png` | Peta wilayah | "Peta wilayah dengan status kunci berbasis badge" |
| `hub.png` | Kota Unggul dengan 4 NPC | "Hub Kota Unggul: Kepala Kota, Penjaga Gerbang, Pedagang, Peneliti" |
| `play.png` | Eksplorasi Hutan Pengetahuan | "Antarmuka permainan: HUD, uang, badge, dan lingkungan" |
| `cari.png` | Objek pencarian di Hutan | "Objek pencarian sebagai pemicu quest di Hutan Pengetahuan" |
| `near.png` | Prompt interaksi NPC | "Prompt interaksi `[E] Bicara` saat mendekati NPC" |
| `dialog.png` | Dialog NPC | "Dialog naratif dan penyampaian misi" |
| `puzzle.png` | Tantangan SQL builder | "Tantangan Basis Data: menyusun query" |
| `order.png` | Tantangan urutan | "Tantangan Sistem Operasi: urutan penjadwalan proses" |
| `cipher.png` | Tantangan sandi Caesar | "Tantangan Kriptografi: memutar cakram sandi" |
| `craft.png` | Puzzle kabel IoT (wire) | "Tantangan IoT: menyambung kabel antar komponen yang dibeli di toko" |
| `lensa.png` | Petunjuk Lensa Analisis | "Lensa memberi satu kalimat petunjuk tanpa membocorkan jawaban" |
| `boss.png` | Tantangan boss The Source | "Tantangan akhir: bar HP boss The Source" |
| `pilih.png` | Keputusan akhir | "Keputusan pemain yang menentukan ending" |
| `shop.png` | Toko (uang) | "Pedagang: membeli 4 komponen perangkat (120 uang) dan Lensa Analisis (20 uang)" |
| `badge.png` | Popup badge | "Pemberian badge setelah tantangan akhir wilayah" |
| `ending.png` | Layar penutup | "Layar akhir dan rekap statistik pemain" |
| `asesmen.png` | Post-test & SUS | "Instrumen post-test dan SUS di dalam game" |
| `rekap.png` | Rekap peserta | "Rekap data peserta dan ekspor CSV" |
| `research.png` | Mode riset (rekap) | "Rekap data peserta: nilai post-test per materi, status tuntas, dan skor SUS" |
| `tujuan.png` | Panah penunjuk tujuan | "HUD menunjuk objek/NPC terdekat beserta jarak" |
| `gameplay-kota.mp4` | Rekaman 52 detik: judul → Kota Unggul → jalan ke Kepala Kota → dialog → 2 tantangan → peta wilayah | "Rekaman alur permainan satu wilayah" |

### Peta utuh (folder `dokumentasi/maps/`)

Tiap wilayah juga dirender utuh 40×22 petak lewat `tools/fullmap.gd` (SubViewport 1920×1056,
tanpa kamera pemain) agar keseluruhan tata letak terlihat dalam satu gambar:

| Berkas | Wilayah | Jumlah properti |
|---|---|---|
| `full-kota.png` | Kota Unggul (hub) | 251 |
| `full-hutan.png` | Hutan Pengetahuan | 274 |
| `full-pabrik.png` | Pabrik Limbah | 55 |
| `full-candi.png` | Candi Cipher | 60 |
| `full-danau.png` | Danau Citra | 165 |
| `full-source.png` | The Source | 48 |

## 10. Batasan prototipe (jujur untuk Bab III)

1. Musik latar dan efek suara sintetis tersedia (`assets/audio/`); belum direkam atau disunting melalui Audacity.
2. NPC kini menoleh ke arah pemain secara horizontal; lembar sprite tetap menghadap depan (belum ada pose samping/belakang).
3. Satu slot penyimpanan; belum ada manajemen beberapa pemain dalam satu perangkat (kode peserta diisi manual saat asesmen).
4. Post-test berisi 20 butir (5 per materi) dan SUS 10 butir, tetapi validasi isi oleh ahli materi dan uji coba instrumen (validitas/reliabilitas) belum dilakukan.
5. Peta dibuat prosedural dari skrip, belum melalui Tiled seperti disebut pada Bab II — perlu disesuaikan di laporan (lihat catatan berikut).
6. Objek pencarian dan NPC didefinisikan di `data/content.gd`, bukan di dalam berkas peta, agar peta tidak perlu digambar ulang saat konten berubah.
7. Bar HP boss bersifat naratif (berkurang per ujian integrasi yang lulus), belum ada pertarungan real-time.
8. Ekspor yang diuji: Web. Ekspor Windows/Linux memerlukan template ekspor Godot yang belum disertakan.

## 11. Kesesuaian dengan dokumen terbaru (Draf Kelompok 1)

Rujukan: *Pengembangan dan Evaluasi Game RPG Edukasi Terra Rebirth sebagai Media Pembelajaran Konsep Informatika*, draf Bab I–III (penomoran subbab di bawah mengikuti draf tersebut). Setiap butir dokumen diperiksa terhadap prototipe; status "sesuai" berarti perilaku di game dapat ditunjukkan saat pengujian.

| Butir dokumen | Tuntutan | Status di prototipe |
|---|---|---|
| 1.4 Batasan masalah | Enam map, quest & puzzle tiap materi, badge sebagai syarat map berikutnya, uang & toko di Kota Unggul, post-test di map terakhir | Sesuai — 6 map, 50 tantangan (22 inti + 8 puzzle + 20 soal bank), gating badge, toko 5 barang, post-test di Map 6 |
| 2.2.4 Tabel 2.2 | Mekanika: eksplorasi, dialog/NPC, quest, tantangan konsep, umpan balik & coba ulang, progresi badge, ekonomi uang–toko | Sesuai — lihat §3 |
| 2.5 Tabel 2.4 | Badge setelah **seluruh** quest satu map; uang 1× per puzzle di Map 2–5 | Sesuai — `badge` hanya terbit saat `map_done == map_total`; uang 10 per puzzle, sekali |
| 2.5 Tabel 2.5 | Urutan akses: Map 1 bebas, Map 2 syarat quest pengantar, Map 3–6 syarat badge sebelumnya | Sesuai — kunci akses tunggal adalah badge |
| 2.6 Tabel 2.6 | Latar, materi, NPC pendamping, dan reward tiap map | Sesuai — nama map, NPC (Kepala Kota, Penjaga Gerbang, Pedagang, Peneliti Lingkungan, Peneliti Hutan, Teknisi Mesin, Penjaga Arsip, Inventor) dan badge |
| 3.2 GDLC | Enam tahap: initiation, pre-production, production, testing, beta, release | Terdokumentasi — §4–§7 memetakan tahap testing/beta ke uji alpha (207 cek) dan uji isi (1456 cek) |
| 3.3 Tabel 3.1 | Target pengguna mahasiswa, kontrol sederhana | Sesuai — WASD/arrow, `E` interaksi, `M` peta, `Esc` menu; tanpa syarat pengalaman bermain |
| 3.6.1–3.6.4 | Capaian pembelajaran Basis Data, Sistem Operasi, Kriptografi, IoT | Sesuai — tiap butir a–d/ a–c dipetakan ke tantangan (lihat §2) |
| 3.8 | Populasi mahasiswa, purposive sampling, target 30 responden, data tidak lengkap dikeluarkan | Sesuai sebagian — mode riset mencatat kode peserta, durasi, dan kelengkapan; target 30 ditampilkan di layar Data Peserta; keputusan mengeluarkan data tidak lengkap dilakukan peneliti |
| 3.9 Tabel 3.3 | Post-test 20 soal (5 tiap materi), skor 1/0, nilai = benar/20 × 100; SUS 10 butir skala 1–5 | Sesuai — 20 butir (5/5/5/5), SUS 10 butir polaritas bergantian |
| 3.10 | Urutan: informed consent → main Map 1–6 → post-test → SUS; durasi 60 menit | Sesuai — layar persetujuan, asesmen terbuka otomatis di akhir Map 6, durasi tercatat; batas 60 menit dicatat manual oleh peneliti |
| 3.11 | Statistik deskriptif, batas tuntas 70, skor SUS ×2,5, acuan 68, interpretasi Tabel 3.4 | Sesuai — rekap per peserta & per materi, ekspor CSV, interpretasi "dapat diterima / perlu diperbaiki" |
| 3.12 | Etika: sukarela, data dikodekan, bukan nilai akademik | Sesuai — kode peserta, tanpa nama, data lokal `user://records_terra.json` |
| Arahan penguji (revisi tambahan) | Tiga NPC pengajar per wilayah, quest dimulai dari objek di peta, dan nyawa habis mereset progres tanpa menghapus uang/barang | Sesuai — lihat §3g–§3i; dikunci oleh `autotest.gd` (207 cek) dan `audit_konten.gd` (1456 cek) |
| 2.3 & 3.2.3 | Perangkat: Godot, GDScript, Blender, GitHub, Tiled, Krita, Dialogic, Audacity, Figma | **Belum seluruhnya** — lihat catatan di bawah |

### Catatan ketidaksesuaian alat (perlu diputuskan sebelum sidang)

| Alat di dokumen | Kenyataan di prototipe | Opsi |
|---|---|---|
| Tiled (Bab II 2.3.4, 3.2.3) | Tata letak peta dihasilkan `tools/maps_gen.py` menjadi JSON, dimuat `world.gd` | (a) ubah kalimat dokumen, atau (b) konversi peta ke `.tmx` + importer Tiled |
| Dialogic (2.3.6, 3.2.3) | Dialog memakai komponen kustom `dialog_box.gd` + data di `content.gd` | (a) ubah kalimat dokumen, atau (b) pasang add-on Dialogic dan pindahkan percakapan ke timeline |
| Krita & Blender (2.3.2, 2.3.5) | Sprite dan latar dibuat prosedural (Python) + bantuan model gambar, dirapikan manual | (a) tulis "aset dibuat secara digital (generator + penyuntingan manual)", atau (b) produksi ulang aset di Krita/Blender |
| Audacity (2.3.7) | Musik & efek suara disintesis lewat `tools/gen_audio.py` (WAV 22,05 kHz), belum disunting di Audacity | (a) tulis "audio dibuat dengan sintesis digital", atau (b) sunting/rapikan hasilnya di Audacity sebelum sidang |
| Figma (2.3.8) | Antarmuka dibangun langsung dengan kontrol Godot (`ui_kit.gd`) | (a) ubah menjadi "rancangan antarmuka dibuat sebagai sketsa/layout di Figma, lalu diimplementasikan di Godot", atau (b) buat berkas Figma terpisah |

Prinsipnya: klaim alat pada Bab II harus sama dengan yang benar-benar dipakai. Butir yang tidak dapat dibuktikan saat sidang paling mudah dijadikan bahan sanggahan, sedangkan butir isi (materi, badge, uang, post-test, SUS) sudah dapat ditunjukkan langsung lewat permainan dan layar Data Peserta.