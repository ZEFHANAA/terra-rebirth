# Phase 1 — Data Model

Model di bawah ini menggambarkan bentuk data yang dipakai permainan. Semua konten bersifat
statis di `data/content.gd`; hanya keadaan pemain yang berubah dan disimpan.

## Entitas Konten (statis)

### Wilayah (Map)

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | String | `kota`, `hutan`, `pabrik`, `candi`, `danau`, `source` |
| `name` | String | Nama tampil, mis. "Hutan Pengetahuan" |
| `material` | String | Bidang materi wilayah |
| `badge` | String | Id badge; kosong untuk Kota dan The Source |
| `req_badge` / `req_clear` | String | Syarat membuka wilayah |
| `npcs` | Array | Daftar NPC wilayah |
| `objects` | Array | Daftar objek pemicu tantangan |
| `challenges` | Array | Daftar tantangan wilayah |
| `intro` | Array[String] | Baris konteks wilayah |

### NPC

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | String | Unik dalam satu wilayah |
| `name`, `role` | String | Nama dan peran yang tampil di dialog |
| `sprite` | String | Nama sprite di `assets/` |
| `x`, `y` | int | Posisi tile |
| `action` | String | `materi`, `info`, `shop`, `gate` |
| `dialog` | Array[String] | Baris tambahan; untuk `materi` dipakai sebagai kalimat pembuka peran |

Aturan: setiap wilayah non-Kota wajib punya tepat 3 NPC; tidak ada `action == "quest"`.

### Objek Peta

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | String | Unik, mis. `kota-papan`, `hutan-terminal` |
| `label` | String | Nama yang tampil saat didekati |
| `x`, `y` | int | Posisi tile |
| `challenge` | String | Id tantangan yang dibuka (opsional) |
| `bank` | bool | `true` bila membuka soal bank berikutnya |
| `text` | Array[String] | Keterangan objek sebelum tantangan terbuka |

Aturan: objek harus punya salah satu dari `challenge` atau `bank`, dan `challenge` harus
merujuk tantangan yang ada di wilayah yang sama.

### Tantangan

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | String | Mis. `kota-1`, `hutan-b1` |
| `title` | String | Judul tantangan |
| `type` | String | `mcq`, `build`, `order`, `craft`, `cipher` |
| `lesson` / `explain` | Dictionary / String | Sumber teks materi untuk NPC |
| `bank_materi` | String | Menandai tantangan yang soalnya diundi dari bank |
| `answer`, `options`, `items`, `slots` | varies | Bergantung tipe tantangan |

## Entitas Keadaan Pemain (disimpan)

| Field | Tipe | Dipertahankan saat reset? |
|---|---|---|
| `player_code` | String | Ya — identitas peserta |
| `coins` | int | Ya — hasil usaha, dipakai beli komponen |
| `items` | Dictionary | Ya — mis. `lensa` |
| `components` | Dictionary | Ya — komponen perangkat Danau |
| `earned` | Dictionary | Ya — riwayat tantangan yang koinnya sudah dibayar; mencegah koin ganda setelah reset |
| `done` | Dictionary | Tidak — dikosongkan |
| `badges` | Array[String] | Tidak — dikosongkan |
| `map_lives` | Dictionary | Tidak — dikosongkan (kembali ke 3 per wilayah) |
| `penalized` | Dictionary | Tidak — dikosongkan |
| `bank_picks` | Dictionary | Tidak — undian soal dibuat ulang |
| `puzzle_picks` | Dictionary | Tidak — undian puzzle dibuat ulang |
| `outro_seen` | Dictionary | Tidak |
| `post_answers`, `post_done`, `post_picks` | varies | Tidak |
| `sus_answers`, `sus_done` | varies | Tidak |
| `ending_choice` | String | Tidak |
| `current_map` | String | Dikembalikan ke `kota` |

## Transisi Keadaan Nyawa

```text
nyawa wilayah = 3
  ├─ jawab benar            → tantangan selesai, nyawa tetap
  ├─ jawab salah (tantangan belum pernah salah)
  │     → penalized[cid] = true, nyawa -= 1
  │        ├─ nyawa > 0 → simpan, lanjut di wilayah
  │        └─ nyawa = 0 → RESET (lihat di bawah)
  └─ jawab salah (tantangan sama, sudah pernah salah) → tidak ada perubahan nyawa

RESET
  1. kosongkan progres, badge, nyawa, undian, status asesmen
  2. pertahankan kode peserta, uang, item, komponen
  3. current_map = "kota"
  4. simpan, pancarkan progress_changed + lives_changed + map_failed
  5. main: tutup panel, toast penjelasan, muat Kota Unggul
```

## Sinyal yang Menjaga Konsistensi

| Sinyal | Pemakai |
|---|---|
| `lives_changed(map_id, lives)` | HUD (nyawa), layar Peta |
| `progress_changed()` | HUD (badge/tantangan), layar Peta, portal gerbang |
| `map_failed(map_id)` | `main._on_map_failed` — toast dan pemuatan ulang Kota |
| `challenge_completed(id)` | Pembaruan portal dan toast wilayah |
| `badge_earned(id, name)` | Popup badge |

## Aturan Validasi

- Nyawa tidak pernah negatif; nilai 0 langsung memicu reset.
- `map_lives` kosong berarti semua wilayah kembali ke 3 nyawa.
- Badge hanya bertambah lewat `complete_challenge` saat `is_map_cleared` benar.
- Objek tidak boleh memberi `coins`, `items`, atau `components`.
- Reset tidak boleh menghapus `player_code`, agar rekap post-test tetap terhubung ke peserta.
