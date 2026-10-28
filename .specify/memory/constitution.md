# Konstitusi Terra Rebirth

Dokumen ini menetapkan prinsip yang mengikat setiap spec, plan, dan task pada proyek
Terra Rebirth. Bila sebuah rencana bertentangan dengan prinsip di sini, rencananya yang
harus berubah — bukan prinsipnya.

## Prinsip Inti

### I. Konten Berbahasa Indonesia

Semua teks yang dilihat pemain — dialog NPC, judul tantangan, soal, pembahasan, tombol,
toast, dan layar penutup — ditulis dalam bahasa Indonesia yang wajar. Istilah teknis
(primary key, JOIN, cipher, sensor pH) tetap dalam bentuk aslinya karena itu bagian dari
materi yang diajarkan. Nama variabel dan komentar kode boleh berbahasa teknis.

### II. Kurikulum sebagai Sumber Kebenaran

Isi permainan mengikuti empat bidang materi: Basis Data, Sistem Operasi, Kriptografi, dan
Internet of Things, dengan pemetaan wilayah → bidang → tantangan yang sudah ditetapkan.
Setiap tantangan wajib punya pembahasan singkat yang muncul setelah dijawab, sehingga
berfungsi sebagai umpan balik formatif. Tidak ada soal yang materinya tidak tercakup pada
wilayah tersebut.

### III. Satu Jalur Progres: Badge

Satu-satunya penanda progres adalah badge wilayah (Nature, Core, Cipher, Aqua) dan jumlah
tantangan per wilayah. Tidak ada level, XP, atau syarat progres ganda. Badge diberikan
hanya setelah seluruh tantangan pada satu wilayah selesai, dan badge itulah kunci wilayah
berikutnya. Wilayah hub (Kota Unggul) dan wilayah final tidak memberi badge.

### IV. Hukuman Tidak Boleh Mengunci Permanen

Mekanik nyawa hanya boleh menghapus progres, tidak boleh menghapus hal yang sudah dibeli
atau identitas pemain. Saat nyawa sebuah wilayah habis: seluruh progres tantangan dan
badge direset, pemain dikembalikan ke Kota Unggul, tetapi uang, item, komponen perangkat
yang sudah dibeli, dan kode peserta tetap tersimpan. Pemain harus selalu bisa melanjutkan
permainan dari awal tanpa kehilangan modal belajar.

### V. Tes Wajib Hijau Sebelum Diserahkan

Perubahan tidak dianggap selesai sebelum `scripts/audit_konten.gd` dan `scripts/autotest.gd`
lulus dengan 0 kegagalan, dan build Web berhasil. Tes ditulis untuk mengunci perilaku yang
diminta, bukan untuk menyesuaikan diri pada implementasi yang sudah ada.

### VI. Eksplorasi, Bukan Menu

Pemain membuka interaksi dengan berjalan mendekati NPC atau objek lalu menekan tombol
interaksi; dialog tidak terbuka otomatis. Materi dipelajari lewat percakapan dengan NPC
pengajar, sedangkan tantangan dimulai dari objek di peta (papan, buku, terminal, perangkat).
Menu Peta hanya untuk berpindah wilayah, bukan untuk memulai quest.

### VII. Perubahan Terkendali

Repositori utama milik pemain tidak disentuh saat mengerjakan revisi: pekerjaan dilakukan di
worktree terpisah. Tidak ada commit, push, atau deploy tanpa izin eksplisit. Setiap
perubahan harus bisa dijelaskan sebagai jawaban atas permintaan yang benar-benar ada.

## Batasan Teknis

- Mesin: Godot 4.7 (GDScript), renderer Compatibility, resolusi 1280×720.
- Target: Web (WebAssembly) dan desktop.
- Data permainan berupa GDScript (`data/content.gd`, `data/question_bank.gd`), bukan basis
  data eksternal; penyimpanan pemain di `user://save_terra.json`.
- Tidak ada dependensi jaringan saat bermain.

## Alur Kerja

1. Spec ditulis lebih dulu dan direview sebelum plan.
2. Plan menjelaskan file dan alur yang berubah, tanpa menambah fitur di luar spec.
3. Task dipecah kecil dan bisa diverifikasi satu per satu.
4. Implementasi diikuti audit konten, autotest, dan build.
5. Konvergensi: kode diperiksa terhadap spec; selisih dicatat sebagai task baru.

## Tata Kelola

Konstitusi ini berlaku untuk semua spec pada proyek ini. Perubahannya hanya boleh dilakukan
atas persetujuan pemilik proyek, dan setiap revisi konstitusi dicatat pada bagian riwayat di
bawah. Kompleksitas tambahan harus dibenarkan oleh kebutuhan yang tertulis di spec.

**Versi**: 1.0.0 | **Ditetapkan**: 2026-10-28 | **Terakhir diubah**: 2026-10-28
