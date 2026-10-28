# Feature Specification: NPC Pengajar, Quest dari Objek, dan Reset Nyawa

**Feature Branch**: `001-npc-materi-quest-objek`

**Created**: 2026-10-28

**Status**: Implemented (spec ditulis sebagai dokumentasi atas revisi yang sudah dikerjakan)

**Input**: User description: "Tiap wilayah ada tiga NPC, belajar lewat interaksi dengan NPC,
quest dimulai dari tempat/benda di peta. Kalau nyawa habis, semua progres dan badge direset,
tapi uang dan item/komponen yang sudah dibeli tetap disimpan."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Belajar materi dari NPC di setiap wilayah (Priority: P1)

Pemain masuk ke sebuah wilayah, mendekati NPC, menekan tombol interaksi, lalu menerima
penjelasan materi wilayah tersebut dalam bentuk dialog. Setiap wilayah selain Kota Unggul
menyediakan tiga NPC, dan setiap NPC memberikan bahan belajar — bukan hanya satu NPC
istimewa. Dialog NPC juga memberi tahu bahwa tantangan tidak dimulai dari mereka.

**Why this priority**: Tanpa materi yang bisa diakses kapan saja di peta, pemain hanya
menghadapi soal tanpa bekal. Ini inti dari sisi edukatif permainan.

**Independent Test**: Masuk ke satu wilayah, ajak bicara ketiga NPC satu per satu, dan
pastikan masing-masing menampilkan dialog bermateri yang berbeda.

**Acceptance Scenarios**:

1. **Given** pemain berada di Hutan Pengetahuan, **When** pemain mendekati dan mengajak
   bicara Peneliti Hutan, **Then** dialog materi Basis Data terbuka dan bisa dilanjutkan
   sampai selesai tanpa memulai tantangan apa pun.
2. **Given** pemain mengajak bicara NPC kedua atau ketiga di wilayah yang sama, **When**
   dialog selesai, **Then** tidak ada tantangan yang terbuka dan tidak ada progres yang
   bertambah.
3. **Given** pemain mengajak bicara NPC yang sama dua kali, **When** dialog diulang,
   **Then** materi tampil lagi tanpa menggandakan progres atau hadiah.

---

### User Story 2 - Memulai tantangan dari objek di peta (Priority: P2)

Pemain menemukan objek penanda di peta (papan pengumuman, buku aturan, papan data, buku
registri, terminal soal, perangkat), memeriksanya, membaca keterangan singkat, lalu
tantangan yang berkaitan terbuka. Objek yang sama tidak membuka tantangan yang sudah
diselesaikan.

**Why this priority**: Memisahkan "belajar dari orang" dan "mengerjakan tantangan dari
benda" membuat alur eksplorasi punya dua lapis yang jelas, dan mencegah pemain melewatkan
materi karena tantangan muncul terlalu cepat.

**Independent Test**: Di satu wilayah, periksa satu objek dan pastikan hanya tantangan yang
tertaut pada objek itu yang terbuka; periksa objek yang tantangannya sudah selesai dan
pastikan tidak ada panel baru.

**Acceptance Scenarios**:

1. **Given** pemain berada di dekat Papan Pengumuman di Kota Unggul, **When** pemain
   memeriksa objek tersebut, **Then** dialog objek terbuka, lalu tantangan "Aturan
   Perjalanan" muncul setelah dialog selesai.
2. **Given** tantangan pada satu objek sudah diselesaikan, **When** pemain memeriksa objek
   itu lagi, **Then** tidak ada tantangan baru yang terbuka.
3. **Given** pemain memeriksa Terminal Soal di Hutan Pengetahuan, **When** dialog selesai,
   **Then** soal berikutnya dari bank soal Basis Data terbuka secara berurutan.

---

### User Story 3 - Nyawa habis mereset progres, bukan barang (Priority: P3)

Ketika pemain menjawab salah pada tantangan-tantangan berbeda sampai nyawa wilayah habis,
seluruh progres tantangan dan badge dihapus, pemain dikembalikan ke Kota Unggul, dan diberi
pesan yang menjelaskan apa yang terjadi. Uang, item, komponen perangkat yang sudah dibeli,
dan kode peserta tetap utuh sehingga pemain bisa mengulang perjalanan tanpa kehilangan
modal.

**Why this priority**: Hukuman harus terasa, tetapi tidak boleh membuat pemain kehilangan
hal yang sudah dibeli dengan usaha. Tanpa aturan ini, reset bisa terasa seperti kehilangan
permanen dan mematikan motivasi.

**Independent Test**: Habiskan nyawa satu wilayah lewat tiga jawaban salah pada tantangan
berbeda, lalu periksa bahwa jumlah tantangan selesai dan badge kembali nol sementara uang,
item, dan komponen tidak berubah.

**Acceptance Scenarios**:

1. **Given** pemain punya uang 20 dan satu komponen perangkat, **When** nyawa wilayah habis,
   **Then** uang tetap 20, komponen tetap dimiliki, progres tantangan 0, dan badge kosong.
2. **Given** nyawa wilayah habis saat panel tantangan terbuka, **When** reset terjadi,
   **Then** panel tertutup, pesan reset muncul, dan pemain kembali ke Kota Unggul.
3. **Given** progres sudah direset, **When** pemain membuka layar Peta, **Then** hanya Kota
   Unggul yang terbuka dan wilayah berikutnya terkunci lagi.
4. **Given** pemain mengulang perjalanan setelah reset, **When** menyelesaikan Kota Unggul
   kembali, **Then** Hutan Pengetahuan bisa dimasuki seperti pertama kali.

---

### Edge Cases

- Jawaban salah berulang pada tantangan yang sama hanya memotong satu nyawa, sehingga satu
  soal sulit tidak menghabiskan seluruh wilayah.
- Menjawab salah saat nyawa tinggal satu langsung memicu reset tanpa panel pembahasan.
- Item yang sudah dibeli tetapi belum dipakai tetap tersimpan setelah reset.
- Komponen perangkat yang sudah dibeli tetap ada, sehingga perakitan di Danau Citra tidak
  perlu membeli ulang.
- Reset tidak menghapus kode peserta karena itu identitas, bukan progres.
- Setelah reset, simpan/muat tidak mengembalikan progres lama.
- Wilayah yang seluruh tantangannya selesai tidak bisa kehilangan nyawa lagi karena tidak
  ada tantangan tersisa yang bisa dijawab salah.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Setiap wilayah selain Kota Unggul MUST memiliki tiga NPC di peta.
- **FR-002**: Setiap NPC MUST memberikan dialog materi, bukan membuka tantangan.
- **FR-003**: Dialog NPC MUST menyatakan bahwa tantangan dimulai dari objek di peta.
- **FR-004**: Setiap objek tantangan MUST membuka tantangan yang tertaut padanya setelah
  dialog objek selesai.
- **FR-005**: Objek MUST NOT membuka tantangan yang sudah diselesaikan.
- **FR-006**: Setiap wilayah MUST memiliki tiga nyawa; satu jawaban salah memotong satu
  nyawa, dan satu tantangan hanya bisa memotong satu nyawa.
- **FR-007**: Ketika nyawa sebuah wilayah mencapai nol, sistem MUST menghapus seluruh
  progres tantangan dan badge pada semua wilayah.
- **FR-008**: Reset MUST mempertahankan uang, item, komponen yang sudah dibeli, dan kode
  peserta.
- **FR-009**: Reset MUST mengembalikan pemain ke Kota Unggul dan menampilkan pesan yang
  menjelaskan konsekuensinya.
- **FR-010**: Setelah reset, penguncian wilayah MUST kembali mengikuti kepemilikan badge
  (kosong), sehingga hanya Kota Unggul yang terbuka.
- **FR-011**: Setelah reset, pemain MUST dapat menyelesaikan Kota Unggul kembali
  dan memasuki Hutan Pengetahuan tanpa menghapus simpanan atau memulai ulang
  aplikasi.
- **FR-012**: Koin MUST hanya diberikan sekali untuk setiap tantangan, termasuk
  setelah progres direset; reset MUST NOT menjadi cara memperoleh koin berulang.
- **FR-013**: Setiap wilayah materi MUST memuat dua ragam quest: kuis pilihan ganda
  (jawaban salah memotong satu nyawa) dan puzzle (gagal langsung menghabiskan nyawa
  wilayah).
- **FR-014**: Puzzle MUST beragam bentuknya, minimal mengurutkan langkah/sintaks
  (`order`) dan mengisi bagian rumpang (`fill`).
- **FR-015**: Bank kuis MUST berisi 50 soal per materi dan hanya 5 yang ditampilkan
  per wilayah; bank puzzle MUST berisi 10 puzzle per materi dan dipilih acak.
- **FR-016**: Pemilihan soal kuis dan puzzle MUST acak per sesi, MUST NOT memakai
  seed tetap per peserta, dan MUST NOT menampilkan soal yang sama dua kali dalam
  satu wilayah.
**FR-017**: Setiap NPC MUST memiliki cerita sendiri yang ditampilkan sebelum
  materi, dan quest MUST dapat dimulai dari NPC lain atau dari benda rusak yang
  diperbaiki, bukan hanya dari satu jenis pemicu.

**FR-018**: Panel kuis dan puzzle MUST memakai tema visual wilayahnya sendiri
  (bahan bingkai, kertas soal, warna aksen, dan warna huruf), bukan satu gaya
  seragam untuk semua peta; tema dipasang saat panel dibuka dan dikembalikan ke
  tema dasar saat panel ditutup.

### Key Entities

- **NPC pengajar**: tokoh di peta dengan nama, peran, posisi, dan kumpulan baris materi.
- **Objek peta**: benda yang bisa diperiksa; punya label, keterangan, dan tautan ke satu
  tantangan atau ke bank soal.
- **Tantangan**: soal pada satu wilayah dengan tipe tertentu, jawaban benar, dan pembahasan.
- **Nyawa wilayah**: sisa kesempatan menjawab salah pada satu wilayah.
- **Progres**: daftar tantangan yang sudah selesai dan badge yang sudah diperoleh.
- **Bank puzzle**: 10 puzzle per materi dengan tipe `order` atau `fill`, pembahasan,
  dan kunci jawaban; undiannya disimpan agar tidak berganti saat panel dibuka ulang.
- **Cerita NPC**: dua baris atau lebih kisah pribadi tiap NPC yang ditampilkan lebih
  dulu sebelum materi.
- **Dompet dan inventaris**: uang, item sekali pakai, dan komponen perangkat yang dimiliki
  pemain; tidak terpengaruh reset.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% wilayah non-Kota memiliki tepat tiga NPC, terverifikasi oleh audit konten.
- **SC-002**: 0 tantangan dapat dimulai dari dialog NPC, terverifikasi oleh autotest.
- **SC-003**: Setelah tiga jawaban salah pada tantangan berbeda, jumlah tantangan selesai
  kembali 0 dan badge kembali kosong.
- **SC-004**: Pada skenario reset, uang, item, dan komponen sebelum dan sesudah reset
  identik.
- **SC-005**: Audit konten dan autotest lulus dengan 0 kegagalan setelah perubahan.
- **SC-006**: Pemain dapat menyelesaikan ulang Kota Unggul lalu memasuki Hutan Pengetahuan
  setelah reset, tanpa hambatan.

## Assumptions

- Permainan dimainkan satu pemain, tanpa jaringan, dengan penyimpanan lokal.
- Kode peserta dibuat sekali di awal dan tidak dianggap bagian dari progres.
- Materi setiap wilayah sudah ditetapkan kurikulum, sehingga NPC hanya menyampaikan ulang.
- Uang hanya diperoleh dari tantangan wilayah Map 2–Map 5, sekali untuk setiap tantangan;
  reset tidak memberi kompensasi dan tidak membuka kesempatan memperoleh koin yang sama
  dua kali.
- Jumlah nyawa per wilayah tetap tiga; tidak ada item yang menambah nyawa pada revisi ini.
