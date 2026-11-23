---

description: "Task list for NPC Pengajar, Quest dari Objek, dan Reset Nyawa"
---

# Tasks: NPC Pengajar, Quest dari Objek, dan Reset Nyawa

**Input**: Design documents from `/specs/001-npc-materi-quest-objek/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/ui-interaksi.md

**Tests**: Tes disertakan karena SC-001, SC-002, dan SC-005 di spec mewajibkan verifikasi
otomatis lewat `scripts/audit_konten.gd` dan `scripts/autotest.gd`.

**Organization**: Task dikelompokkan per user story agar tiap cerita bisa diuji sendiri.

**Catatan status**: implementasi fitur ini sudah ada di worktree
`/home/ubuntu/.hermes/cache/scratch/tr-work` (belum di-commit). Checkbox sengaja dibiarkan
kosong; setiap task diverifikasi lewat perintah yang tertera di task verifikasi, bukan lewat
status commit.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: boleh jalan paralel (file berbeda, tanpa dependensi)
- **[Story]**: US1 (NPC mengajar), US2 (quest dari objek), US3 (reset nyawa)
- Semua path relatif terhadap root proyek Godot

## Path Conventions

Single project Godot: `data/`, `scripts/`, `scripts/ui/`, `scenes/`, `specs/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Memastikan pekerjaan dilakukan di tempat yang benar dan alat uji siap.

- [ ] T001 Konfirmasi worktree aktif dan basis commit di `/home/ubuntu/.hermes/cache/scratch/tr-work` dengan `git rev-parse --short HEAD` dan `git status --short`
- [ ] T002 [P] Pastikan konstitusi proyek terbaca di `.specify/memory/constitution.md` dan tidak ada prinsip yang dilanggar plan
- [ ] T003 [P] Siapkan Xvfb pada `DISPLAY=:99` agar `scenes/AutoTest.tscn` bisa dijalankan

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Struktur data dan jalur sinyal yang dipakai ketiga user story.

**⚠️ CRITICAL**: Tidak ada user story yang bisa dikerjakan sebelum fase ini selesai.

- [ ] T004 Tambahkan `_lesson_lines(map)` di `scripts/main.gd` yang menyusun baris materi dari `lesson.text` atau `explain` setiap tantangan wilayah (D1 di research.md)
- [ ] T005 [P] Tambahkan keadaan `map_lives` dan `penalized` beserta sinyal `lives_changed(map_id, lives)` di `scripts/game_state.gd`; `map_lives` kosong berarti 3 nyawa
- [ ] T006 [P] Tambahkan dukungan `objects[]` pada setiap wilayah di `data/content.gd` dengan field `id`, `label`, `x`, `y`, `challenge`, `bank`, `text`
- [ ] T007 Sambungkan objek peta ke interaksi di `scripts/world.gd`: gambar penanda `?`, tampilkan prompt `[E] Periksa <label>`, pancarkan `inspect_object(obj_id)`
- [ ] T008 Tampilkan sisa nyawa wilayah di HUD `scripts/ui/hud.gd` dan sambungkan ke sinyal `lives_changed`

**Checkpoint**: Fondasi siap — US1, US2, US3 bisa dikerjakan.

---

## Phase 3: User Story 1 - Belajar materi dari NPC di setiap wilayah (Priority: P1) 🎯 MVP

**Goal**: Setiap wilayah non-Kota punya tiga NPC, semuanya menyampaikan materi, dan tidak
ada NPC yang membuka tantangan.

**Independent Test**: Masuk satu wilayah, ajak bicara ketiga NPC, pastikan tiap dialog
bermateri dan tidak ada panel tantangan yang terbuka.

- [ ] T009 [P] [US1] Tambahkan NPC ketiga pada setiap wilayah non-Kota (`hutan`, `pabrik`, `candi`, `danau`, `source`) di `data/content.gd`, masing-masing dengan `id`, `name`, `role`, `sprite`, `x`, `y`, `action: "materi"`; Kota Unggul tetap empat NPC
- [ ] T010 [US1] Ubah `_on_talk_npc` di `scripts/main.gd` agar setiap NPC beraksi `materi` memanggil `_lesson_lines` dan membuka dialog materi (FR-002)
- [ ] T011 [US1] Tambahkan baris penutup dialog `Quest dimulai dari benda bertanda ? di peta, bukan dari NPC.` pada `_lesson_lines` di `scripts/main.gd` (FR-003)
- [ ] T012 [US1] Nonaktifkan layar pelajaran mandiri sebelum tantangan di `scripts/ui/puzzle_panel.gd` sehingga pengajaran hanya lewat NPC
- [ ] T013 [P] [US1] Perluas audit di `scripts/audit_konten.gd`: setiap wilayah non-Kota tepat tiga NPC dan tidak ada NPC dengan `action == "quest"` (SC-001)
- [ ] T014 [P] [US1] Perluas `scripts/autotest.gd`: dialog NPC berisi baris materi dan menutup dialog tidak menambah `done` maupun membuka panel (SC-002)

**Checkpoint**: US1 berfungsi dan bisa diuji sendiri; ini MVP.

---

## Phase 4: User Story 2 - Memulai tantangan dari objek di peta (Priority: P2)

**Goal**: Tantangan hanya terbuka dari objek peta, termasuk soal bank yang berurutan.

**Independent Test**: Periksa satu objek → hanya tantangan tertaut yang terbuka; periksa
objek yang tantangannya selesai → tidak ada panel baru.

- [ ] T015 [P] [US2] Tetapkan `challenge` atau `bank: true` untuk setiap objek di seluruh wilayah pada `data/content.gd`: `kota-papan`, `kota-buku`, `hutan-terminal`, `pabrik-terminal`, `candi-terminal`, `candi-meja`, `danau-terminal`, `danau-meja`, `source-pilar`, `source-altar`, `source-inti`, `source-gerbang` (FR-004). The Source tidak punya objek bank karena tidak punya soal bank
- [ ] T016 [US2] Implementasikan `_on_inspect_object` dan `_resolve_object` di `scripts/main.gd`: dialog objek dulu, panel tantangan setelah dialog ditutup; objek yang tantangannya sudah selesai tidak membuka panel (FR-005)
- [ ] T017 [US2] Implementasikan `_open_next_bank_challenge` di `scripts/main.gd` untuk objek `bank: true`: buka soal bank pertama yang belum selesai, dan tampilkan toast `Semua soal terminal di wilayah ini selesai.` bila habis
- [ ] T018 [US2] Hapus pembukaan tantangan otomatis setelah satu tantangan selesai di `scripts/main.gd` sehingga pemain harus kembali ke objek (D6)
- [ ] T019 [P] [US2] Perluas audit di `scripts/audit_konten.gd`: setiap objek punya `challenge` valid di wilayah yang sama atau `bank: true`, dan objek tidak memberi `coins`, `items`, maupun `components`
- [ ] T020 [P] [US2] Perluas `scripts/autotest.gd`: memeriksa objek membuka tantangan yang tepat dan tidak membuka tantangan wilayah lain

**Checkpoint**: US1 + US2 berfungsi; alur belajar → mengerjakan utuh.

---

## Phase 5: User Story 3 - Nyawa habis mereset progres, bukan barang (Priority: P3)

**Goal**: Tiga jawaban salah pada tantangan berbeda menghapus progres dan badge, tetapi
uang, item, komponen, dan kode peserta tetap.

**Independent Test**: Habiskan nyawa satu wilayah, lalu bandingkan `coins`, `items`,
`components` sebelum dan sesudah reset; `done` harus kosong dan `badges` kosong.

- [ ] T021 [US3] Implementasikan `note_mistake(map_id, cid)` di `scripts/game_state.gd`: satu tantangan hanya memotong satu nyawa lewat `penalized[cid]`, nyawa tidak pernah negatif (FR-006)
- [ ] T022 [US3] Implementasikan `_fail_map(map_id)` di `scripts/game_state.gd`: kosongkan `badges`, `done`, `outro_seen`, `bank_picks`, `penalized`, `post_picks`, `post_answers`, `post_done`, `sus_answers`, `sus_done`, `map_lives`, `ending_choice`; pertahankan `player_code`, `coins`, `items`, `components`; set `current_map = "kota"`; simpan; pancarkan `progress_changed`, `lives_changed`, `map_failed` (FR-007, FR-008)
- [ ] T023 [US3] Implementasikan `_on_map_failed` di `scripts/main.gd`: tutup panel tantangan, tampilkan toast `Nyawa habis — semua progres dan badge direset. Uang dan barang tetap tersimpan.`, tunggu 2 detik, muat Kota Unggul, lalu toast `Mulai lagi dari Kota Unggul. Bicara ke NPC pengajar untuk materi, lalu cari objek bertanda ?.` (FR-009)
- [ ] T024 [US3] Segarkan HUD dan layar Peta setelah reset di `scripts/ui/hud.gd` dan `scripts/main.gd` (`_open_maps`) sehingga badge `0/4`, uang tetap, dan hanya Kota Unggul terbuka (FR-010)
- [ ] T025 [P] [US3] Perluas `scripts/autotest.gd`: reset menghapus `done`/`badges` tetapi `coins`, `items`, `components`, `player_code` identik sebelum dan sesudah; wilayah berikutnya terkunci lagi; setelah reset selesaikan `kota-1` dan `kota-2` lalu pastikan `Game.map_unlocked("hutan")` benar (SC-003, SC-004, SC-006, FR-011)

- [ ] T032 [P] [US3] Tambahkan assertion di `scripts/autotest.gd`: setelah reset, `save_game()` lalu `load_game()` tidak mengembalikan `done`/`badges` lama (edge case spec baris 106)
- [ ] T033 [P] [US3] Tambahkan assertion di `scripts/autotest.gd`: tantangan yang sudah dibayar tidak memberi koin lagi setelah reset, karena `earned` tidak ikut dihapus (FR-012)

**Checkpoint**: Ketiga user story berfungsi dan bisa diuji terpisah.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verifikasi menyeluruh dan kebersihan worktree.

- [ ] T026 Jalankan audit konten: `godot --headless --path . --script res://scripts/audit_konten.gd` dan pastikan `0 gagal` (SC-005)
- [ ] T027 Jalankan autotest: `DISPLAY=:99 godot --path . res://scenes/AutoTest.tscn` dan pastikan `0 gagal` (SC-005)
- [ ] T028 [P] Ekspor Web: `godot --headless --path . --export-release "Web" build/web/index.html`, lalu pastikan `build/web/index.html` ada dengan ukuran > 0 (Prinsip V)
- [ ] T029 [P] Jalankan `git diff --check` dan hapus file probe/sementara (`tools/probe_*.gd`, `scenes/Probe*.tscn`) dari worktree
- [ ] T030 [P] Perbarui `DOKUMENTASI_PROTOTIPE.md` agar mencantumkan aturan tiga NPC, quest dari objek, dan konsekuensi reset
- [ ] T031 Validasi manual mengikuti `specs/001-npc-materi-quest-objek/quickstart.md` bagian 3

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: tanpa dependensi
- **Foundational (Phase 2)**: butuh Phase 1; memblokir semua user story
- **User Stories (Phase 3–5)**: butuh Phase 2
  - US1 tidak bergantung pada US2/US3
  - US2 tidak bergantung pada US1, tetapi memakai `_lesson_lines` untuk konsistensi teks
  - US3 tidak bergantung pada US1/US2; hanya butuh `penalized` dan `map_lives` dari T005
- **Polish (Phase 6)**: butuh seluruh user story yang ingin dikirim

### User Story Dependencies

- **US1 (P1)**: bisa mulai setelah Phase 2 — independen
- **US2 (P2)**: bisa mulai setelah Phase 2 — independen, integrasi ringan dengan T004
- **US3 (P3)**: bisa mulai setelah Phase 2 — independen

### Within Each User Story

- Konten (`data/content.gd`) sebelum logika yang membacanya
- Logika `game_state.gd` sebelum alur `main.gd` yang memanggilnya
- Implementasi sebelum perluasan audit/autotest
- Audit dan autotest harus 0 gagal sebelum pindah fase

### Parallel Opportunities

- T002 dan T003 paralel
- T005 dan T006 paralel (file berbeda)
- T013 dan T014 paralel (audit vs autotest)
- T019 dan T020 paralel
- T028, T029, T030 paralel di fase Polish

---

## Parallel Example: User Story 1

```bash
# Konten dan validasi bisa jalan bersamaan setelah T004–T008 selesai:
Task: "T009 Tambahkan NPC ketiga di data/content.gd"
Task: "T013 Perluas audit tiga NPC di scripts/audit_konten.gd"
Task: "T014 Perluas autotest dialog NPC di scripts/autotest.gd"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Selesaikan Phase 1 dan Phase 2
2. Selesaikan Phase 3 (US1)
3. **BERHENTI dan VALIDASI**: jalankan audit + autotest, lalu uji dialog tiga NPC di satu wilayah
4. Demo bila siap

### Incremental Delivery

1. Setup + Foundational → fondasi siap
2. US1 → uji → demo (materi bisa diakses dari NPC)
3. US2 → uji → demo (tantangan dari objek, termasuk bank berurutan)
4. US3 → uji → demo (reset dengan retensi uang/barang)
5. Setiap tahap tidak merusak tahap sebelumnya karena audit dan autotest dijalankan ulang

---

## Notes

- [P] = file berbeda, tanpa dependensi
- Label [US*] menjaga ketertelusuran ke spec.md
- Jangan commit/push/deploy tanpa izin pemilik repo
- Video demo bukan bagian dari task repo; perekaman dilakukan di salinan terpisah
