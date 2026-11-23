# Implementation Plan: NPC Pengajar, Quest dari Objek, dan Reset Nyawa

**Branch**: `001-npc-materi-quest-objek` | **Date**: 2026-10-28 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-npc-materi-quest-objek/spec.md`

## Summary

Tiga perubahan yang saling terkait: (1) setiap wilayah non-Kota punya tiga NPC dan semua NPC
menyampaikan materi wilayahnya, (2) tantangan hanya dimulai dari objek di peta, bukan dari
dialog NPC, dan (3) nyawa wilayah yang habis menghapus seluruh progres serta badge, tetapi
mempertahankan uang, item, komponen, dan kode peserta, lalu mengembalikan pemain ke Kota
Unggul. Pendekatan teknis: konten NPC/objek ditambah di `data/content.gd`; `main.gd`
memisahkan jalur dialog NPC (materi) dari jalur objek (tantangan); `game_state.gd`
memusatkan aturan nyawa dan reset sehingga HUD, peta, dan penyimpanan konsisten.

## Technical Context

**Language/Version**: GDScript, Godot 4.7.2 (stable, renderer Compatibility)

**Primary Dependencies**: Godot engine standard library; tanpa addon eksternal; audio dan
aset sprite dari `assets/`

**Storage**: Konten berupa GDScript (`data/content.gd`, `data/question_bank.gd`); progres
pemain disimpan sebagai JSON di `user://save_terra.json`

**Testing**: Skrip Godot headless — `scripts/audit_konten.gd` (audit konten) dan
`scripts/autotest.gd` lewat `scenes/AutoTest.tscn`; dijalankan dengan `DISPLAY=:99` karena
tes memuat scene permainan

**Target Platform**: Web (WebAssembly) dan desktop Linux/Windows

**Project Type**: Aplikasi game 2D single-project (satu repo, satu executable)

**Performance Goals**: 60 fps pada 1280×720; waktu muat peta di bawah 1 detik

**Constraints**: Offline penuh saat bermain; seluruh teks pemain berbahasa Indonesia;
tanpa level/XP; resolusi tetap 1280×720 dengan stretch `canvas_items`

**Scale/Scope**: 6 wilayah, 22 tantangan statis + 20 soal bank (42 total saat dimainkan),
4 badge, 3 NPC per wilayah non-Kota

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Prinsip | Cara plan memenuhinya | Status |
|---|---|---|
| I. Konten berbahasa Indonesia | Semua dialog NPC, label objek, dan pesan reset ditulis dalam bahasa Indonesia | LULUS |
| II. Kurikulum sebagai sumber kebenaran | Materi NPC diambil dari `lesson`/`explain` tantangan wilayah yang sama, bukan teks baru di luar kurikulum | LULUS |
| III. Satu jalur progres: badge | Plan tidak menambah level/XP; badge tetap hanya dari `is_map_cleared` | LULUS |
| IV. Hukuman tidak mengunci permanen | Reset menghapus `done`, `badges`, `penalized`, `map_lives`, status post-test/SUS; `coins`, `items`, `components`, `player_code` tidak disentuh | LULUS |
| V. Tes wajib hijau | Autotest dan audit konten diperluas untuk perilaku baru; keduanya harus 0 gagal sebelum dianggap selesai | LULUS |
| VI. Eksplorasi, bukan menu | Interaksi tetap lewat jarak dekat + tombol interaksi; tantangan hanya dari objek | LULUS |
| VII. Perubahan terkendali | Pekerjaan di worktree terpisah; tanpa commit/push/deploy tanpa izin | LULUS |

Tidak ada pelanggaran yang perlu dijustifikasi.

## Project Structure

### Documentation (this feature)

```text
specs/001-npc-materi-quest-objek/
├── plan.md              # Dokumen ini
├── research.md          # Keputusan desain dan alternatif yang ditolak
├── data-model.md        # Entitas, field, dan transisi keadaan
├── quickstart.md        # Cara memvalidasi fitur
├── contracts/
│   └── ui-interaksi.md  # Kontrak interaksi pemain ↔ NPC/objek/panel
└── tasks.md             # Output /speckit-tasks (belum dibuat)
```

### Source Code (repository root)

```text
DOKUMENTASI_PROTOTIPE.md # Dokumen prototipe untuk laporan/dosen; ikut diperbarui (T030)
README.md                # Ringkasan proyek dan cara menjalankan

data/
├── content.gd           # MAPS: npcs, objects, challenges, badge, intro
└── question_bank.gd     # Bank soal per materi (dipakai objek bertanda bank)

scripts/
├── main.gd              # Alur layar: _on_talk_npc, _on_inspect_object, _resolve_object,
│                        #   _open_next_bank_challenge, _on_map_failed, _lesson_lines, _open_maps
├── game_state.gd        # Autoload Game: nyawa, note_mistake, _fail_map, simpan/muat
├── world.gd             # Peta, NPC, objek, radius interaksi, prompt
├── audit_konten.gd      # Audit struktur konten (NPC, objek, tautan tantangan)
├── autotest.gd          # Tes perilaku (dialog, objek, reset, retensi)
└── ui/
    ├── puzzle_panel.gd  # Panel tantangan: MCQ, build, order, craft, cipher
    ├── hud.gd           # Nyawa, uang, badge
    ├── dialog_box.gd    # Kotak dialog NPC dan objek
    ├── shop_panel.gd    # Toko komponen
    └── asesmen.gd       # Post-test dan kuesioner SUS

scenes/
├── Main.tscn            # Scene utama permainan
└── AutoTest.tscn        # Scene pembungkus autotest

.specify/                # Konfigurasi spec-kit (konstitusi, template, feature.json)
specs/                   # Dokumen spec per fitur
```

**Structure Decision**: Struktur single-project Godot yang sudah ada dipertahankan. Tidak
ada folder baru di kode permainan; seluruh perubahan terjadi di file yang sudah ada
(`content.gd`, `main.gd`, `game_state.gd`, `puzzle_panel.gd`, `autotest.gd`,
`audit_konten.gd`). Dokumen spec-kit hidup di `.specify/` dan `specs/` dan tidak ikut
diekspor ke build.

## Complexity Tracking

Tidak ada pelanggaran konstitusi, sehingga tabel ini tidak diisi.
