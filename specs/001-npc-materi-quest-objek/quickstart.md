# Quickstart — Cara Memvalidasi Fitur

Panduan singkat untuk membuktikan fitur bekerja, baik lewat tes otomatis maupun dengan
bermain sendiri. Detail perilaku ada di [contracts/ui-interaksi.md](./contracts/ui-interaksi.md)
dan bentuk data di [data-model.md](./data-model.md).

## Prasyarat

- Godot 4.7.2 di `~/.local/bin/godot`
- Proyek di worktree revisi (bukan repo utama), mis. `/home/ubuntu/.hermes/cache/scratch/tr-work`
- Untuk tes scene: Xvfb pada `DISPLAY=:99`

## 1. Audit Konten

```bash
cd /home/ubuntu/.hermes/cache/scratch/tr-work
/home/ubuntu/.local/bin/godot --headless --path . --script res://scripts/audit_konten.gd
```

Harapan: `=== N cek, 0 gagal ===`, termasuk pemeriksaan bahwa setiap wilayah non-Kota punya
tepat tiga NPC, setiap objek tertaut tantangan yang ada, setiap objek ber-`bank` berada di
wilayah yang benar-benar punya soal bank, dan objek tidak memberi komponen.

## 2. Autotest Perilaku

```bash
cd /home/ubuntu/.hermes/cache/scratch/tr-work
DISPLAY=:99 /home/ubuntu/.local/bin/godot --path . res://scenes/AutoTest.tscn
```

Harapan: `=== HASIL: N cek, 0 gagal ===`, mencakup:
- dialog NPC berisi baris materi dan tidak membuka tantangan;
- objek membuka tantangan yang tertaut;
- reset menghapus `done` dan `badges` tetapi mempertahankan uang, item, dan komponen;
- setelah reset, wilayah berikutnya terkunci kembali.

## 3. Validasi Manual di Permainan

```bash
cd /home/ubuntu/.hermes/cache/scratch/tr-work
/home/ubuntu/.local/bin/godot --path .
```

1. Mulai perjalanan, dekati Kepala Kota, tekan interaksi → dialog materi muncul.
2. Tutup dialog → pastikan tidak ada panel tantangan yang terbuka.
3. Dekati Papan Pengumuman, periksa → dialog objek, lalu tantangan "Aturan Perjalanan".
4. Selesaikan dua tantangan Kota, lalu buka Peta → Hutan Pengetahuan bisa dimasuki.
5. Di Hutan, ajak bicara ketiga NPC → masing-masing memberi materi, tanpa tantangan.
6. Periksa Terminal Soal → soal bank pertama; jawab salah → nyawa `2/3`.
7. Selesaikan soal itu, buka terminal lagi, ulangi sampai nyawa `0`.
8. Setelah reset: pesan reset muncul, kembali ke Kota, uang tetap, badge `0/4`,
   layar Peta menampilkan `0/N` dan Hutan terkunci lagi.

## 4. Build Web (opsional)

```bash
cd /home/ubuntu/.hermes/cache/scratch/tr-work
/home/ubuntu/.local/bin/godot --headless --path . --export-release "Web" build/web/index.html
```

Harapan: ekspor selesai tanpa error dan folder `build/web` bisa dibuka lewat server statis.

## 5. Kriteria Lulus

- Audit dan autotest 0 gagal.
- Tidak ada dialog NPC yang membuka tantangan.
- Reset tidak mengubah uang, item, komponen, atau kode peserta.
- Setelah reset pemain bisa menyelesaikan Kota lalu masuk Hutan seperti pertama kali.
