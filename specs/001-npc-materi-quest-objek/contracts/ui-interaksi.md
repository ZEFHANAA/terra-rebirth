# Kontrak Interaksi UI

Kontrak ini mengikat perilaku yang dilihat pemain: kapan prompt muncul, apa yang terjadi saat
tombol interaksi ditekan, dan apa yang muncul setelah tantangan dijawab. Semua nilai di sini
diverifikasi oleh `scripts/autotest.gd`.

## 1. Prompt Interaksi

| Kondisi | Prompt yang tampil | Aksi saat tombol interaksi |
|---|---|---|
| Pemain berjarak dekat dengan NPC | `[E] Bicara <nama NPC>` | `talk_to_npc(npc_id)` |
| Pemain berjarak dekat dengan objek aktif | `[E] Periksa <label objek>` | `inspect_object(obj_id)` |
| Pemain berjarak dekat portal terbuka | `[E] Masuk <wilayah>` | pindah wilayah |
| Portal terkunci | `[E] <alasan terkunci>` | toast alasan, tidak berpindah |
| Tidak ada target | tidak ada prompt | tidak terjadi apa-apa |

Aturan: dialog tidak pernah terbuka sendiri; selalu butuh tombol interaksi.

## 2. Dialog NPC

1. Dialog menampilkan nama dan peran NPC.
2. Baris pertama untuk NPC `materi`: `Materi <bidang> — pilih soal dan contoh pada objek
   bertanda ? di peta.`
3. Baris berikutnya: satu baris per tantangan wilayah, berisi `<judul>: <materi>`.
4. Baris terakhir: `Quest dimulai dari benda bertanda ? di peta, bukan dari NPC.`
5. Menekan tombol interaksi saat baris selesai mengetik akan maju ke baris berikutnya; pada
   baris terakhir dialog tertutup.
6. Menutup dialog **tidak** membuka tantangan dan **tidak** mengubah progres.

NPC `info`, `shop`, dan `gate` memakai dialog masing-masing dan tetap tidak membuka tantangan.

## 3. Dialog Objek dan Pembukaan Tantangan

1. Memeriksa objek membuka dialog berjudul `<label>` dengan subjudul `Objek ditemukan`.
2. Setelah baris terakhir ditutup:
   - objek dengan `challenge` → panel tantangan terbuka untuk tantangan tersebut;
   - objek dengan `bank: true` → panel terbuka untuk soal bank pertama yang belum selesai;
   - tidak ada soal tersisa → toast `Semua soal terminal di wilayah ini selesai.`
3. Objek yang tantangannya sudah selesai tidak membuka panel lagi.

## 4. Panel Tantangan

| Kejadian | Umpan balik |
|---|---|
| Jawaban benar | Opsi ditandai warna aksen, panel menampilkan pembahasan, tombol `Lanjut` muncul |
| Jawaban salah (pertama pada tantangan itu) | Opsi dinonaktifkan, teks `Belum tepat…`, nyawa wilayah berkurang 1 |
| Jawaban salah (tantangan sama, sudah pernah salah) | Teks `Belum tepat…`, nyawa tidak berubah |
| Percobaan salah kedua | Petunjuk tambahan ditampilkan |
| Nyawa wilayah mencapai 0 | Panel ditutup, reset dijalankan (bagian 5) |

Menutup panel tanpa menjawab tidak mengubah progres dan tidak memotong nyawa.

## 5. Reset Karena Nyawa Habis

1. Panel tantangan ditutup seketika.
2. Toast tampil 4 detik: `Nyawa habis — semua progres dan badge direset. Uang dan barang
   tetap tersimpan.`
3. Setelah 2 detik, peta Kota Unggul dimuat ulang dan pemain berada di titik awal kota.
4. Toast lanjutan tampil 3,6 detik: `Mulai lagi dari Kota Unggul. Bicara ke NPC pengajar
   untuk materi, lalu cari objek bertanda ?.`
5. HUD menampilkan badge `0/4`, uang sesuai sebelum reset, dan nyawa `3/3`.
6. Layar Peta menampilkan seluruh tantangan `0/N`, badge `0/4`, dan hanya Kota Unggul terbuka.

## 6. Yang Tidak Boleh Terjadi

- Dialog NPC membuka tantangan.
- Reset menghapus uang, item, komponen, atau kode peserta.
- Panel tantangan tetap terbuka setelah reset.
- Pemain tertahan di wilayah yang nyawanya habis tanpa jalan kembali.
- Objek membuka tantangan dari wilayah lain.
