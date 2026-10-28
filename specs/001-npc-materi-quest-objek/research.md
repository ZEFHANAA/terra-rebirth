# Phase 0 — Riset dan Keputusan Desain

Fitur ini menumpang pada kode yang sudah ada, sehingga "riset" di sini berarti memilih
bentuk implementasi yang paling kecil risikonya terhadap tiga hal: konten kurikulum, aturan
progres badge, dan penyimpanan pemain.

## D1. Sumber teks materi NPC

**Decision**: Dialog materi disusun oleh `_lesson_lines(map)` dari field `lesson.text` atau
`explain` pada setiap tantangan wilayah tersebut, bukan dari teks baru di `content.gd`.

**Rationale**: Materi tetap satu sumber dengan soal, sehingga tidak mungkin NPC mengajarkan
konsep yang tidak diujikan. Menambah soal baru otomatis memperbarui materi NPC.

**Alternatives considered**:
- Menulis dialog materi terpisah per NPC — ditolak karena cepat menyimpang dari soal dan
  menggandakan pekerjaan penulisan.
- Menampilkan layar materi mandiri sebelum tantangan — ditolak karena memutus alur
  eksplorasi dan menduplikasi panel.

## D2. Pemicu tantangan: objek peta, bukan NPC

**Decision**: Tantangan dibuka lewat `objects[]` pada tiap wilayah (`challenge` untuk satu
tantangan, `bank: true` untuk soal berurutan dari bank). NPC tidak lagi punya aksi `quest`.

**Rationale**: Memisahkan "belajar dari orang" dan "mengerjakan dari benda" membuat pemain
melewati materi dulu. Objek juga memberi alasan eksplorasi peta.

**Alternatives considered**:
- NPC memberi quest setelah dialog materi — ditolak karena pemain bisa menekan interaksi
  berulang dan melewati dialog, sehingga materi terlewat.
- Menu daftar tantangan — ditolak oleh konstitusi (eksplorasi, bukan menu).

## D3. Granularitas hukuman nyawa

**Decision**: Satu tantangan hanya bisa memotong satu nyawa, dicatat di `penalized[cid]`.
Jawaban salah berulang pada tantangan yang sama tidak menambah potongan.

**Rationale**: Tanpa batas ini, satu soal sulit bisa menghabiskan tiga nyawa sekaligus dan
terasa tidak adil. Dengan batas ini, pemain harus salah pada tiga tantangan berbeda.

**Alternatives considered**:
- Setiap jawaban salah memotong nyawa — ditolak, terlalu kejam pada soal tipe `build` yang
  butuh percobaan.
- Nyawa sebagai timer — ditolak, menambah kompleksitas tanpa manfaat belajar.

## D4. Cakupan reset saat nyawa habis

**Decision**: `_fail_map` mengosongkan `badges`, `done`, `outro_seen`, `bank_picks`,
`penalized`, `post_picks`, `map_lives`, `post_answers`, `post_done`, `sus_answers`,
`sus_done`, `ending_choice`, dan mengembalikan `current_map` ke `kota`. `coins`, `items`,
`components`, dan `player_code` tidak disentuh.

**Rationale**: Progres adalah capaian belajar dan boleh diulang; uang dan barang adalah
hasil usaha yang sudah dibelanjakan, dan menghapusnya melanggar Prinsip IV. `player_code`
adalah identitas peserta untuk rekap penelitian, bukan progres.

**Alternatives considered**:
- Reset seluruh save (termasuk uang) — ditolak, pemain kehilangan modal membeli komponen
  Danau dan tidak bisa menyelesaikan wilayah terakhir tanpa grinding ulang.
- Reset hanya wilayah yang gagal — ditolak karena badge wilayah lain akan membuka kembali
  wilayah berikutnya, sehingga hukuman tidak terasa dan urutan kurikulum dilanggar.

## D5. Cara memberi tahu pemain dan memulihkan keadaan

**Decision**: `_fail_map` memancarkan `map_failed`, lalu `main._on_map_failed` menutup panel
tantangan, menampilkan toast berisi konsekuensi reset, menunggu 2 detik, memuat ulang Kota
Unggul, dan menampilkan toast petunjuk lanjutan.

**Rationale**: Satu jalur sinyal menjaga HUD, layar Peta, dan peta dunia ikut menyegarkan
lewat `progress_changed` dan `lives_changed` tanpa masing-masing layar tahu detail reset.

**Alternatives considered**:
- Restart aplikasi — ditolak, terasa seperti crash dan memutus sesi penelitian.
- Dialog modal penjelasan — ditolak karena menghentikan alur dan menambah satu layar baru.

## D6. Urutan soal pada objek bank

**Decision**: Objek dengan `bank: true` membuka tantangan bank pertama yang belum selesai
(`_open_next_bank_challenge`), dan setiap penyelesaian tidak otomatis membuka soal
berikutnya.

**Rationale**: Pemain harus kembali ke terminal untuk soal berikutnya, sehingga progres
terlihat dan tidak ada panel yang terbuka sendiri tanpa aksi.

**Alternatives considered**:
- Panel otomatis lanjut ke soal berikutnya — ditolak karena pemain kehilangan kendali dan
  sulit berhenti di tengah.

## D7. Verifikasi

**Decision**: Perilaku baru dikunci oleh `autotest.gd` (dialog NPC berisi materi, objek
membuka tantangan, reset menghapus progres tetapi mempertahankan uang/item/komponen) dan
`audit_konten.gd` (tiga NPC per wilayah non-Kota, setiap objek tertaut tantangan yang ada,
objek tidak memberi komponen).

**Rationale**: Tes menangkap regresi pada aturan yang mudah rusak saat konten ditambah, dan
audit menangkap kesalahan data yang tidak terlihat saat bermain.

**Alternatives considered**:
- Verifikasi manual saja — ditolak, karena 22 tantangan dan 6 wilayah terlalu besar untuk
  dicek tangan setiap perubahan.
