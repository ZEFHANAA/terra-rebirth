class_name Content
extends RefCounted

## Seluruh materi permainan Terra Rebirth.
## Dipisah dari logika agar mudah diperbarui tanpa menyentuh kode UI.
##
## Struktur mengikuti Bab III dokumen penelitian:
##   Map 1 Kota Unggul  : hub, tutorial, quest pengantar (tanpa materi utama)
##   Map 2 Hutan        : Basis Data
##   Map 3 Pabrik       : Sistem Operasi
##   Map 4 Candi        : Kriptografi
##   Map 5 Danau        : Internet of Things
##   Map 6 The Source   : integrasi keempat materi + post-test 20 soal
##
## Progresi: badge hanya diberikan setelah SELURUH quest pada satu map selesai,
## dan badge itulah syarat membuka map berikutnya (Tabel 2.2 & 2.5).

## Nilai batas ketuntasan post-test (Bab III 3.11).
const PASSING_SCORE := 70
## Nilai acuan rata-rata SUS (Hyzy dkk., 2022).
const SUS_REFERENCE := 68.0
## Empat materi pembelajaran beserta urutan penyajiannya.
const MATERI := ["Basis Data", "Sistem Operasi", "Kriptografi", "Internet of Things"]

## Uang hanya diberikan untuk puzzle di Map 2 sampai Map 5 (Bab II 2.5,
## Tabel 2.4). Map 1 (hub/tutorial) dan Map 6 (post-test) tidak memberi uang.
const COINS_PER_CHALLENGE := 10
const COINS_MAPS := ["hutan", "pabrik", "candi", "danau"]

## Empat komponen perangkat pemantau air yang WAJIB DIBELI di toko Kota Unggul
## sebelum perakitan di Danau Citra (Tabel 2.4 dan 2.6; Bab III 3.6.4).
const COMPONENT_IDS := ["sensor", "papan", "mcu", "daya"]
const COMPONENT_TOTAL := 4

## Titik awal pemain per peta (dipakai world.gd dan audit_konten.gd).
const SPAWNS := {
	"kota": Vector2(30, 22),
	"hutan": Vector2(18, 18),
	"pabrik": Vector2(19, 18),
	"candi": Vector2(19, 19),
	"danau": Vector2(27, 12),
	"source": Vector2(12, 17),
}

## Barang yang dijual pedagang di Kota Unggul (Tabel 2.6 "membeli item").
## "component": true menandai komponen perangkat IoT — membelinya langsung
## mencatat komponen sebagai dimiliki (bukan barang sekali pakai).
const SHOP := {
	"sensor": {
		"name": "Sensor pH Air", "price": 35, "component": true,
		"desc": "Mengukur tingkat keasaman (pH) air.",
	},
	"papan": {
		"name": "Papan Rangkaian & Kabel Jumper", "price": 25, "component": true,
		"desc": "Menghubungkan sensor dengan mikrokontroler.",
	},
	"mcu": {
		"name": "Mikrokontroler Berkemampuan WiFi", "price": 40, "component": true,
		"desc": "Memproses data sensor, mengirim lewat WiFi (MQTT).",
	},
	"daya": {
		"name": "Sumber Daya", "price": 20, "component": true,
		"desc": "Kabel USB atau baterai untuk menyalakan perangkat.",
	},
	"lensa": {
		"name": "Lensa Analisis", "price": 20,
		"desc": "Sekali pakai. Membuka petunjuk tantangan.",
	},
}

const MAPS := [
	{
		"id": "kota", "name": "Kota Unggul", "material": "Tutorial & Hub",
		"desc": "Pusat kota. Temui Kepala Kota, terima quest pengantar, dan pelajari aturan main.",
		"badge": "", "badge_name": "",
		"npc_name": "Kepala Kota", "npc_role": "Pemberi tugas", "npc_sprite": "kepala",
		"npcs": [
			{"id": "kepala", "name": "Kepala Kota", "role": "Pemberi tugas", "sprite": "kepala", "x": 30, "y": 12, "action": "quest"},
			{"id": "gerbang", "name": "Penjaga Gerbang", "role": "Penjaga jalan", "sprite": "penjaga", "x": 52, "y": 18, "action": "gate",
				"dialog": [
					"Gerbang ini hanya terbuka bagi yang sudah menyelesaikan seluruh quest di wilayahnya. Bukan karena aku pelit, tapi karena wilayah di luar sana tidak bersahabat bagi yang belum siap.",
					"Aturannya satu: selesaikan semua quest di satu wilayah, maka badge wilayah itu kau dapat. Badge itulah kunci gerbang berikutnya."
				]},
			{"id": "pedagang", "name": "Pedagang", "role": "Penjual item & komponen", "sprite": "pedagang", "x": 14, "y": 18, "action": "shop",
				"dialog": [
					"Uang? Aku terima. Uang itu bukan badge, jadi ia tidak membuka gerbang apa pun — hanya bisa ditukar barang di sini.",
					"Aku juga menyimpan komponen perangkat pemantau air: sensor pH, papan rangkaian dan kabel jumper, mikrokontroler ber-WiFi, serta sumber daya. Tanpa keempatnya, perakitan di Danau Citra tidak akan jalan.",
					"Lensa Analisis paling laris. Sekali pakai, tapi cukup untuk membuka petunjuk saat kau benar-benar buntu."
				]},
			{"id": "peneliti", "name": "Peneliti Lingkungan", "role": "Peneliti", "sprite": "peneliti", "x": 40, "y": 22, "action": "info",
				"dialog": [
					"Aku mencatat kerusakan lingkungan di enam wilayah. Polanya selalu sama: data kacau, mesin berhenti, pesan tak terbaca, lalu alat pemantau mati.",
					"Karena itu perjalananmu disusun berurutan: Basis Data di Hutan, Sistem Operasi di Pabrik, Kriptografi di Candi, lalu IoT di Danau. Yang terakhir adalah sumbernya.",
					"Jangan lompat urutan. Konsep di wilayah awal dipakai lagi di wilayah akhir."
				]},
		],
		"req_badge": "", "req_clear": "",
		"intro": [
			"Selamat datang di Kota Unggul, pengembara. Dulu kota ini makmur, sampai catatan data, mesin, sandi, dan perangkat pemantau kami rusak satu per satu.",
			"Kami butuh seseorang yang memahami cara kerja keempatnya. Bukan sekadar menghafal, tetapi mampu memakainya saat keadaan mendesak.",
			"Aturannya sederhana: selesaikan seluruh quest di satu wilayah, dan kau memperoleh badge wilayah itu. Badge itulah yang membuka jalan berikutnya. Satu quest saja belum cukup."
		],
		"challenges": [
			{
				"id": "kota-1", "title": "Aturan Perjalanan", "type": "mcq",
				"prompt": "Kepala Kota menjelaskan syarat membuka wilayah baru. Manakah yang benar?",
				"options": [
					"Menyelesaikan seluruh quest wilayah dan memperoleh badge wilayah tersebut",
					"Membeli item pembuka di pedagang kota",
					"Berbicara dengan semua NPC yang ada di kota",
					"Menunggu waktu permainan berjalan cukup lama"
				],
				"answer": 0,
				"explain": "Akses wilayah ditentukan oleh badge wilayah sebelumnya. Badge baru diberikan setelah seluruh quest pada satu wilayah selesai, sehingga progres permainan mengikuti urutan penguasaan materi."
			},
			{
				"id": "kota-2", "title": "Arti Sebuah Badge", "type": "mcq",
				"prompt": "Dalam rancangan Terra Rebirth, badge berfungsi sebagai apa?",
				"options": [
					"Hiasan profil tanpa pengaruh pada permainan",
					"Bukti penguasaan konsep satu wilayah yang membuka wilayah berikutnya",
					"Mata uang untuk membeli item di toko",
					"Pengganti nilai akhir mata kuliah"
				],
				"answer": 1,
				"explain": "Badge bukan atribut tambahan. Badge diikat pada kriteria kompetensi di akhir wilayah dan berfungsi sebagai kunci akses, sehingga progres permainan mengikuti urutan penguasaan materi."
			}
		]
	},
	{
		"id": "hutan", "name": "Hutan Pengetahuan", "material": "Basis Data",
		"desc": "Catatan sumber air rusak dan lokasi pencemaran hilang. Susun ulang data untuk menemukannya.",
		"badge": "nature", "badge_name": "Nature Data Crystal",
		"npc_name": "Peneliti Hutan", "npc_role": "Ahli data lingkungan", "npc_sprite": "peneliti",
		"req_badge": "", "req_clear": "kota",
		"intro": [
			"Kau datang tepat waktu. Arsip hutan ini kacau: tabel sumber air terpisah dari tabel lokasi, dan tidak ada yang tahu titik mana yang paling tercemar.",
			"Aku butuh seseorang yang bisa membaca relasi antartabel dan menyusun query. Tanpa itu, kami hanya menebak-nebak."
		],
		"objects": [
			{"id": "hutan-cari-1", "label": "Papan Data", "x": 12, "y": 9, "challenge": "hutan-1",
				"text": [
					"Papan ini mencatat sumber air, tetapi kolom lokasinya kosong. Tidak ada yang tahu baris mana milik titik mana.",
					"Untuk memperbaikinya, kau harus tahu kolom mana yang bisa menjadi primary key dan kolom mana yang menghubungkan kedua tabel."
				]},
			{"id": "hutan-cari-2", "label": "Buku Registri", "x": 15, "y": 13, "challenge": "hutan-2",
				"text": [
					"Registri ini mencatat daftar lokasi. Satu lokasi bisa memiliki banyak sumber air, tetapi satu sumber air hanya berada di satu lokasi.",
					"Kalau kau bisa menentukan di tabel mana kunci penghubungnya diletakkan, relasinya bisa dipulihkan."
				]},
			{"id": "hutan-cari-3", "label": "Catatan Lapangan", "x": 38, "y": 11, "challenge": "hutan-3",
				"text": [
					"Catatan ini menyebut dua tabel yang terpisah: sumber air dan lokasi. Tidak ada query yang bisa menggabungkannya.",
					"Kalau kau bisa menulis query yang menghubungkan keduanya, daftar titik tercemar bisa disusun ulang."
				]},
			{"id": "hutan-cari-4", "label": "Papan Daftar Lokasi", "x": 36, "y": 8, "challenge": "hutan-4",
				"text": [
					"Papan ini berisi seluruh lokasi yang pernah dicatat, termasuk tiga lokasi yang belum memiliki data sumber air sama sekali.",
					"Kalau kau memakai penggabungan biasa, ketiga lokasi itu akan hilang dari laporan. Pilih jenis penggabungan yang tepat."
				]},
			{"id": "hutan-cari-5", "label": "Sampel Air", "x": 33, "y": 20, "challenge": "hutan-5",
				"text": [
					"Sampel terakhir. Angkanya sudah terkumpul, tetapi belum diurutkan, jadi tidak ada yang tahu titik mana yang paling mendesak.",
					"Urutkan hasilnya, lalu tentukan titik pertama yang harus ditangani."
				]}
		],
		"challenges": [
			{
				"id": "hutan-1", "title": "Kunci Tabel", "type": "mcq",
				"prompt": "Perhatikan tabel sumber air berikut. Kolom mana yang berperan sebagai primary key?",
				"table": {
					"head": ["id_sumber", "nama", "ph", "id_lokasi"],
					"rows": [
						["SA-01", "Mata Air Tujuh", "4.8", "L-03"],
						["SA-02", "Sungai Biru", "5.9", "L-01"],
						["SA-03", "Sumur Tua", "6.3", "L-02"]
					]
				},
				"options": ["id_sumber", "nama", "ph", "id_lokasi"],
				"answer": 0,
				"explain": "id_sumber bersifat unik dan tidak boleh kosong, sehingga dapat menjadi primary key. Kolom id_lokasi adalah foreign key yang merujuk ke tabel lokasi, sedangkan nama dan pH bisa berubah atau berulang."
			},
			{
				"id": "hutan-2", "title": "Relasi Satu ke Banyak", "type": "mcq",
				"prompt": "Satu lokasi dapat memiliki banyak sumber air, tetapi satu sumber air hanya berada pada satu lokasi. Di tabel mana foreign key harus diletakkan?",
				"options": [
					"Di tabel sumber_air, sebagai kolom id_lokasi yang merujuk ke tabel lokasi",
					"Di tabel lokasi, sebagai kolom id_sumber yang merujuk ke tabel sumber_air",
					"Di kedua tabel, agar datanya saling mencerminkan",
					"Tidak perlu foreign key, cukup nama lokasi ditulis ulang di setiap baris"
				],
				"answer": 0,
				"explain": "Pada relasi satu ke banyak, foreign key diletakkan di sisi 'banyak', yaitu tabel sumber_air. Dengan begitu satu baris lokasi dapat dirujuk oleh banyak baris sumber air tanpa mengulang data lokasi."
			},
			{
				"id": "hutan-3", "title": "Menyusun Query", "type": "build",
				"prompt": "Susun query untuk menampilkan nama sumber air beserta nama lokasinya, hanya untuk sumber air dengan pH di bawah 6,5, diurutkan dari pH terendah.",
				"tables": "sumber_air (id_sumber, nama, ph, id_lokasi)  ·  lokasi (id_lokasi, nama_lokasi)",
				"parts": [
					{"pre": "SELECT", "answer": "s.nama, l.nama_lokasi", "options": ["s.nama, l.nama_lokasi", "s.nama, s.ph", "l.nama_lokasi, l.id_lokasi"]},
					{"pre": "FROM", "answer": "sumber_air s", "options": ["sumber_air s", "lokasi s", "sumber_air l"]},
					{"pre": "JOIN", "answer": "lokasi l ON s.id_lokasi = l.id_lokasi", "options": ["lokasi l ON s.id_lokasi = l.id_lokasi", "lokasi l", "sumber_air l ON l.id_sumber = s.id_lokasi"]},
					{"pre": "WHERE", "answer": "s.ph < 6.5", "options": ["s.ph < 6.5", "l.ph < 6.5", "s.ph > 6.5"]},
					{"pre": "ORDER BY", "answer": "s.ph ASC", "options": ["s.ph ASC", "s.nama ASC", "s.ph DESC"]}
				],
				"explain": "Query lengkap: SELECT s.nama, l.nama_lokasi FROM sumber_air s JOIN lokasi l ON s.id_lokasi = l.id_lokasi WHERE s.ph < 6.5 ORDER BY s.ph ASC;  — JOIN menghubungkan kedua tabel melalui kolom relasi, WHERE menyaring baris, dan ORDER BY mengurutkan hasil."
			},
			{
				"id": "hutan-4", "title": "Memilih Jenis JOIN", "type": "mcq",
				"prompt": "Laporan harus tetap menampilkan seluruh lokasi, termasuk lokasi yang belum memiliki data sumber air. Jenis JOIN mana yang tepat?",
				"options": [
					"LEFT JOIN, dengan tabel lokasi sebagai tabel kiri",
					"INNER JOIN, karena hanya baris yang cocok yang dibutuhkan",
					"CROSS JOIN, agar semua kombinasi baris muncul",
					"Tidak perlu JOIN, cukup dua query terpisah"
				],
				"answer": 0,
				"explain": "INNER JOIN hanya mengembalikan baris yang memiliki pasangan di kedua tabel, sehingga lokasi tanpa data sumber air akan hilang. LEFT JOIN mempertahankan seluruh baris tabel kiri dan mengisi nilai kosong pada kolom tabel kanan bila tidak ada pasangan."
			},
			{
				"id": "hutan-5", "title": "Tantangan Akhir: Membaca Hasil", "type": "mcq", "final": true,
				"prompt": "Query dijalankan dan menghasilkan tabel berikut. Titik mana yang harus ditangani lebih dahulu?",
				"table": {
					"head": ["nama", "nama_lokasi", "ph"],
					"rows": [
						["Mata Air Tujuh", "Hulu Danau", "4.8"],
						["Sungai Biru", "Hilir Pabrik", "5.9"],
						["Sumur Tua", "Kota Unggul", "6.3"]
					]
				},
				"options": [
					"Mata Air Tujuh, karena pH-nya paling rendah (paling asam)",
					"Sumur Tua, karena pH-nya paling mendekati normal",
					"Sungai Biru, karena lokasinya di hilir pabrik",
					"Semua sama saja, urutannya tidak berpengaruh"
				],
				"answer": 0,
				"explain": "Hasil query sudah diurutkan menaik (ASC), sehingga baris pertama adalah pH terendah. pH 4,8 berada paling jauh di bawah ambang normal, jadi titik itu paling mendesak ditangani."
			}
		]
	},
	{
		"id": "pabrik", "name": "Pabrik Limbah", "material": "Sistem Operasi",
		"desc": "Mesin pengolahan berhenti. Atur proses dan sumber daya agar pabrik kembali bekerja.",
		"badge": "core", "badge_name": "Core Fragment",
		"npc_name": "Teknisi Mesin", "npc_role": "Operator pabrik", "npc_sprite": "teknisi",
		"req_badge": "nature", "req_clear": "",
		"intro": [
			"Mesinnya tidak rusak. Masalahnya penjadwalan: proses saling menunggu sumber daya yang dipegang proses lain, lalu semuanya berhenti.",
			"Kalau kau bisa membaca keadaan proses dan mengatur urutannya, mesin ini bisa hidup lagi dalam hitungan menit."
		],
		"challenges": [
			{
				"id": "pabrik-1", "title": "Keadaan Proses", "type": "mcq",
				"prompt": "Sebuah proses baru saja menyelesaikan operasi I/O. Keadaan proses tersebut berubah menjadi apa?",
				"options": ["Running", "Ready", "Waiting", "Terminated"],
				"answer": 1,
				"explain": "Setelah I/O selesai, proses tidak langsung berjalan. Proses kembali ke antrean Ready dan menunggu dipilih kembali oleh penjadwal (dispatcher) untuk masuk ke keadaan Running."
			},
			{
				"id": "pabrik-2", "title": "Urutan Penjadwalan", "type": "order",
				"prompt": "Urutkan langkah berikut sehingga sebuah proses dapat berjalan pertama kali di CPU.",
				"items": [
					"Proses baru dibuat dan masuk ke antrean ready",
					"Dispatcher memilih proses dari antrean ready",
					"Proses berjalan pada CPU (running)",
					"Proses meminta I/O lalu berpindah ke waiting",
					"I/O selesai dan proses kembali ke ready"
				],
				"explain": "Alur keadaan proses: New → Ready → Running → Waiting → Ready. Dispatcher hanya memilih proses yang berada di antrean ready, dan proses yang menunggu I/O tidak dapat dijalankan sampai I/O-nya selesai."
			},
			{
				"id": "pabrik-3", "title": "Memilih Penjadwalan", "type": "mcq",
				"prompt": "Empat proses tiba bersamaan dengan burst time berikut. Manakah pernyataan yang benar?",
				"table": {
					"head": ["Proses", "Burst time"],
					"rows": [["P1", "8"], ["P2", "4"], ["P3", "2"], ["P4", "6"]]
				},
				"options": [
					"FCFS memberi rata-rata waktu tunggu 8,5 dan lebih baik daripada SJF",
					"SJF memberi rata-rata waktu tunggu 5,0 dan lebih baik daripada FCFS",
					"FCFS memberi rata-rata waktu tunggu 5,0 dan lebih baik daripada SJF",
					"Keduanya memberi rata-rata waktu tunggu yang sama, yaitu 6,0"
				],
				"answer": 1,
				"explain": "FCFS (P1,P2,P3,P4): tunggu = 0+8+12+14 = 34, rata-rata 8,5. SJF (P3,P2,P4,P1): tunggu = 0+2+6+12 = 20, rata-rata 5,0. SJF memilih burst time terkecil lebih dulu sehingga rata-rata waktu tunggu lebih kecil."
			},
			{
				"id": "pabrik-4", "title": "Sumber Daya Bersama", "type": "mcq",
				"prompt": "Dua proses memakai printer yang sama. Apa tujuan penerapan mutual exclusion pada sumber daya tersebut?",
				"options": [
					"Memastikan hanya satu proses yang memakai sumber daya pada satu waktu, sehingga data tidak tercampur",
					"Memastikan kedua proses dapat memakai sumber daya secara bersamaan agar lebih cepat",
					"Menghapus sumber daya dari sistem agar tidak diperebutkan",
					"Memberi prioritas permanen kepada proses yang pertama kali datang"
				],
				"answer": 0,
				"explain": "Mutual exclusion menjamin bahwa pada satu waktu hanya satu proses berada di critical section yang memakai sumber daya bersama. Tanpa itu, hasil kedua proses dapat bercampur (race condition) dan keluaran menjadi rusak."
			},
			{
				"id": "pabrik-5", "title": "Tantangan Akhir: Dampak Kesalahan", "type": "mcq", "final": true,
				"prompt": "P1 memegang resource X dan menunggu Y, sementara P2 memegang Y dan menunggu X. Apa dampaknya bagi sistem, dan bagaimana memperbaikinya?",
				"options": [
					"Terjadi deadlock; sistem berhenti melayani proses lain, dan dapat diperbaiki dengan membebaskan salah satu resource serta menyeragamkan urutan permintaan resource",
					"Terjadi starvation; sistem tetap berjalan cepat, dan cukup menambah proses baru",
					"Terjadi race condition; cukup mengulang kedua proses tanpa mengubah apa pun",
					"Tidak terjadi masalah; kedua proses akan selesai sendiri karena CPU cepat"
				],
				"answer": 0,
				"explain": "Kondisi tersebut adalah deadlock (saling menunggu) akibat circular wait. Karena kedua proses tidak dapat melanjutkan, seluruh antrean ikut tertahan. Penanganannya antara lain preemption (membebaskan resource satu proses) dan penetapan urutan permintaan resource yang konsisten untuk mencegah siklus terulang."
			}
		]
	},
	{
		"id": "candi", "name": "Candi Kuno", "material": "Kriptografi",
		"desc": "Prasasti menyimpan pesan terenkripsi tentang penyebab kerusakan lingkungan.",
		"badge": "cipher", "badge_name": "Cipher Key",
		"npc_name": "Penjaga Arsip", "npc_role": "Penjaga prasasti", "npc_sprite": "penjaga",
		"req_badge": "core", "req_clear": "",
		"intro": [
			"Prasasti ini ditulis oleh leluhur kami. Isinya tidak boleh dibaca sembarang orang, jadi mereka menguncinya dengan sandi.",
			"Aku hanya bisa memberi petunjuk, bukan jawabannya. Kau harus mengenali polanya sendiri."
		],
		"challenges": [
			{
				"id": "candi-1", "title": "Mengenali Sandi", "type": "mcq",
				"prompt": "Teks UHELUWK tidak terbaca, tetapi setiap huruf tampak bergeser tiga posisi dari huruf aslinya. Metode apakah yang dipakai?",
				"options": ["Caesar cipher", "SHA-256", "RSA", "MQTT"],
				"answer": 0,
				"explain": "Caesar cipher menggeser setiap huruf dengan jumlah tetap, sehingga polanya masih terlihat. SHA-256 adalah fungsi hash satu arah (tidak dapat dikembalikan), RSA memakai kunci publik-privat, dan MQTT adalah protokol komunikasi IoT, bukan sandi."
			},
			{
				"id": "candi-2", "title": "Memutar Cakram", "type": "cipher",
				"prompt": "Putar cakram sandi sampai pesan terbaca. Prasasti menampilkan ciphertext berikut.",
				"ciphertext": "UHELUWK",
				"answer": "REBIRTH",
				"answer_shift": 3,
				"explain": "Dengan pergeseran 3 ke belakang, U→R, H→E, E→B, L→I, U→R, W→T, K→H, sehingga terbaca REBIRTH."
			},
			{
				"id": "candi-3", "title": "Analisis Frekuensi", "type": "mcq",
				"prompt": "Pada ciphertext yang panjang, huruf yang paling sering muncul adalah H. Dalam bahasa Indonesia huruf yang paling sering muncul adalah E. Berapa pergeseran yang paling mungkin dipakai?",
				"options": ["2", "3", "5", "7"],
				"answer": 1,
				"explain": "Jika H mewakili E, maka setiap huruf telah digeser 3 ke depan (E→F→G→H). Analisis frekuensi memanfaatkan kenyataan bahwa pola kemunculan huruf pada teks asli masih terbawa ke ciphertext."
			},
			{
				"id": "candi-4", "title": "Tantangan Akhir: Memilih Metode", "type": "mcq", "final": true,
				"prompt": "Arsip candi menyimpan dua kebutuhan berbeda: menyimpan kata sandi penjaga, dan mengirim pesan rahasia kepada sekutu yang memegang kunci publik. Pasangan metode yang tepat adalah?",
				"options": [
					"SHA-256 untuk menyimpan kata sandi, RSA untuk mengirim pesan dengan kunci publik",
					"Caesar cipher untuk menyimpan kata sandi, SHA-256 untuk mengirim pesan",
					"RSA untuk menyimpan kata sandi, Vigenere untuk mengirim pesan",
					"Vigenere untuk keduanya, karena paling mudah dihitung manual"
				],
				"answer": 0,
				"explain": "Kata sandi tidak perlu dibaca kembali, sehingga cukup disimpan sebagai hash satu arah (SHA-256). Pesan rahasia kepada penerima yang memegang kunci publik memerlukan enkripsi dua kunci (RSA). Caesar dan Vigenere adalah sandi substitusi simetris yang mudah dipecahkan dengan analisis frekuensi."
			}
		]
	},
	{
		"id": "danau", "name": "Danau Citra", "material": "Internet of Things",
		"desc": "Danau tercemar dan perlu sistem pemantauan kualitas air dari sensor hingga dasbor.",
		"badge": "aqua", "badge_name": "Aqua Signal Core",
		"npc_name": "Inventor", "npc_role": "Perakit perangkat", "npc_sprite": "inventor",
		"req_badge": "cipher", "req_clear": "",
		"intro": [
			"Danau ini tercemar, dan kami butuh alat pemantau kualitas air. Masalahnya, komponennya tidak ada di wilayah ini — semuanya harus dibeli di toko Kota Unggul.",
			"Ada empat komponen yang kau perlukan: sensor pH air, papan rangkaian dan kabel jumper, mikrokontroler berkemampuan WiFi, serta sumber daya berupa kabel USB atau baterai.",
			"Uang dari puzzle di Hutan, Pabrik, dan Candi cukup untuk membelinya. Setelah keempat komponen lengkap, kembali ke sini dan rakit perangkatnya."
		],
		"challenges": [
			{
				"id": "danau-1", "title": "Memilih Komponen", "type": "mcq",
				"prompt": "Komponen apa yang berfungsi mengubah besaran fisik (pH air) menjadi sinyal listrik?",
				"options": ["Sensor pH", "Mikrokontroler", "Modul WiFi", "Broker MQTT"],
				"answer": 0,
				"explain": "Sensor berperan sebagai komponen input yang mengubah besaran fisik menjadi sinyal listrik. Mikrokontroler mengolah sinyal menjadi data digital, modul WiFi mengirim data, dan broker MQTT meneruskan data ke penerima."
			},
			{
				"id": "danau-2", "title": "Fungsi Daya dan Pengolahan", "type": "mcq",
				"prompt": "Perangkat pemantau tidak menyala sama sekali, padahal sensor dan mikrokontroler sudah terpasang. Bagian mana yang harus diperiksa lebih dahulu?",
				"options": [
					"Sumber daya (kabel USB atau baterai), karena tanpa daya tidak ada komponen yang dapat bekerja",
					"Broker MQTT, karena broker mengatur pengiriman data",
					"Dasbor, karena dasbor menampilkan hasil pembacaan",
					"Kabel jaringan, karena data tidak sampai ke server"
				],
				"answer": 0,
				"explain": "Daya adalah prasyarat seluruh rangkaian. Tanpa catu daya, sensor tidak menghasilkan sinyal, mikrokontroler tidak menyala, dan modul WiFi tidak dapat terhubung. Urutan pemeriksaan yang benar: daya → input → pengolahan → pengiriman → penyajian."
			},
			{
				"id": "danau-3", "title": "Merakit Perangkat", "type": "craft",
				"prompt": "Pasang empat komponen yang kau beli di Kota Unggul ke slot yang benar, dari dasar perakitan sampai perangkat menyala.",
				"slots": ["Papan Rangkaian & Kabel Jumper", "Sensor pH Air", "Mikrokontroler Berkemampuan WiFi", "Sumber Daya"],
				"pool": ["Papan Rangkaian & Kabel Jumper", "Sensor pH Air", "Mikrokontroler Berkemampuan WiFi", "Sumber Daya", "Kipas Pendingin", "Lampu LED"],
				"explain": "Perakitan dimulai dari papan rangkaian sebagai dasar, lalu sensor pH dipasang sebagai masukan, mikrokontroler sebagai pengolah data, dan sumber daya agar seluruh rangkaian menyala. Broker MQTT dan dasbor bukan komponen fisik yang dibeli — keduanya berada di sisi jaringan."
			},
			{
				"id": "danau-4", "title": "Alur Data ke Dasbor", "type": "order",
				"prompt": "Urutkan alur pengiriman data dari danau sampai tampil di dasbor.",
				"items": [
					"Sensor pH membaca kondisi air dan mengirim sinyal listrik",
					"Mikrokontroler mengubah sinyal menjadi data digital",
					"Modul WiFi mengirim data melalui jaringan WiFi",
					"Broker MQTT meneruskan data ke topik yang sesuai",
					"Dasbor menampilkan data sehingga kondisi air dapat dipantau"
				],
				"explain": "Data mengalir dari sensor (input) ke mikrokontroler (pengolahan), lalu dikirim melalui WiFi menggunakan protokol MQTT ke broker, dan diteruskan ke dasbor sebagai topik yang dilanggani. Jika satu mata rantai terputus, data tidak akan pernah tampil."
			},
			{
				"id": "danau-5", "title": "Tantangan Akhir: Membaca Data Sensor", "type": "mcq", "final": true,
				"prompt": "Pembacaan tiga perangkat tampil di serial monitor dan diteruskan ke dasbor. Ambang pH normal ditetapkan 6,5 sampai 8,5. Perangkat mana yang menunjukkan kondisi di luar ambang?",
				"table": {
					"head": ["Perangkat", "Lokasi", "pH"],
					"rows": [["Sensor A", "Muara", "5.2"], ["Sensor B", "Tengah danau", "7.1"], ["Sensor C", "Inlet", "8.9"]]
				},
				"options": [
					"Sensor A dan Sensor C",
					"Hanya Sensor B",
					"Ketiga sensor berada di luar ambang",
					"Hanya Sensor A"
				],
				"answer": 0,
				"explain": "pH 5,2 berada di bawah 6,5 (terlalu asam) dan pH 8,9 berada di atas 8,5 (terlalu basa). Hanya Sensor B (7,1) yang berada dalam rentang normal, sehingga dua perangkat lain perlu ditindaklanjuti. Angka yang sama terbaca di serial monitor sebelum dikirim ke dasbor, jadi kesalahan pembacaan dapat ditelusuri dari sensor sampai tampilan."
			}
		]
	},
	{
		"id": "source", "name": "The Source", "material": "Integrasi 4 Bidang",
		"desc": "Final dungeon. Semua yang kau pelajari diuji sekaligus, lalu post-test dikerjakan di sini.",
		"badge": "", "badge_name": "",
		"npc_name": "Guardian", "npc_role": "Penjaga sumber", "npc_sprite": "guardian",
		"req_badge": "aqua", "req_clear": "",
		"intro": [
			"Kau sampai juga. Di sini tidak ada petunjuk bertahap. Data, sistem, sandi, dan perangkat harus kau pakai bersamaan.",
			"Empat ujian terakhir. Jika kau lulus, sumber kerusakan akan berhenti dan Terra pulih."
		],
		"boss": {"name": "The Source", "hp": 4},
		"challenges": [
			{
				"id": "source-1", "title": "Ujian Data", "type": "mcq",
				"prompt": "Query mana yang menampilkan rata-rata pH tiap lokasi yang rata-ratanya di bawah 6,5?",
				"options": [
					"SELECT l.nama_lokasi, AVG(s.ph) FROM sumber_air s JOIN lokasi l ON s.id_lokasi = l.id_lokasi GROUP BY l.nama_lokasi HAVING AVG(s.ph) < 6.5",
					"SELECT l.nama_lokasi, AVG(s.ph) FROM sumber_air s JOIN lokasi l ON s.id_lokasi = l.id_lokasi WHERE AVG(s.ph) < 6.5",
					"SELECT nama_lokasi, SUM(ph) FROM sumber_air GROUP BY ph HAVING SUM(ph) < 6.5",
					"SELECT l.nama_lokasi FROM lokasi l ORDER BY AVG(ph) < 6.5"
				],
				"answer": 0,
				"explain": "Fungsi agregat seperti AVG tidak dapat disaring dengan WHERE, melainkan dengan HAVING setelah GROUP BY. Klausa WHERE menyaring baris sebelum pengelompokan, sedangkan HAVING menyaring hasil kelompok."
			},
			{
				"id": "source-2", "title": "Ujian Sandi", "type": "mcq",
				"prompt": "Prasasti terakhir menampilkan ciphertext VXPEHU dan terbaca sebagai SUMBER. Berapa pergeseran yang dipakai?",
				"options": ["2", "3", "4", "5"],
				"answer": 1,
				"explain": "S→V, U→X, M→P, B→E, E→H, R→U: setiap huruf digeser 3 ke depan. Dengan mengurangkan 3, ciphertext kembali menjadi SUMBER."
			},
			{
				"id": "source-3", "title": "Ujian Sistem", "type": "mcq",
				"prompt": "P1 memegang resource X dan menunggu Y, sementara P2 memegang Y dan menunggu X. Tindakan apa yang tepat untuk memulihkan mesin?",
				"options": [
					"Membebaskan salah satu resource dan menetapkan urutan permintaan resource yang sama untuk semua proses",
					"Menambahkan proses baru agar antrean lebih panjang",
					"Mematikan seluruh sistem lalu menyalakannya kembali",
					"Mengulang kedua proses tanpa mengubah apa pun"
				],
				"answer": 0,
				"explain": "Kondisi tersebut adalah deadlock (saling menunggu). Salah satu penanganannya adalah memaksa satu proses melepas resource (preemption) dan mencegahnya terulang dengan menetapkan urutan permintaan resource yang konsisten."
			},
			{
				"id": "source-4", "title": "Ujian Perangkat", "type": "mcq", "final": true,
				"prompt": "Perangkat pemantau sudah mengirim data, tetapi dasbor tetap kosong. Dua kemungkinan penyebab yang paling tepat adalah?",
				"options": [
					"Perangkat tidak terhubung ke WiFi, atau dasbor tidak berlangganan topik MQTT yang sama",
					"Sensor rusak, atau baterai habis",
					"Mikrokontroler terlalu cepat, atau kabel terlalu panjang",
					"Ambang pH salah ditetapkan, atau data terlalu banyak"
				],
				"answer": 0,
				"explain": "Jika data tidak pernah tampil padahal perangkat menyala, rantai pengiriman yang terputus berada di jaringan (WiFi) atau di topik MQTT yang dilanggani dasbor. Sensor rusak atau daya habis akan terlihat lebih awal pada serial monitor, bukan pada dasbor yang kosong."
			}
		]
	}
]

## Post-test: 20 soal pilihan ganda, 5 soal untuk setiap materi (Bab III 3.9).
## Setiap butir diberi tanda materi agar skor per bidang dapat dilaporkan.
const TEST_ITEMS := [
	# ---------------- Basis Data (5)
	{"m": "Basis Data",
	 "q": "Apa perbedaan utama antara primary key dan foreign key?",
	 "o": ["Primary key boleh kosong, foreign key tidak boleh kosong",
		   "Primary key unik untuk tiap baris, foreign key merujuk ke primary key tabel lain",
		   "Keduanya sama, hanya berbeda nama",
		   "Foreign key harus unik, primary key boleh berulang"],
	 "a": 1},
	{"m": "Basis Data",
	 "q": "Pada relasi satu ke banyak antara tabel lokasi dan tabel sumber_air, di mana foreign key diletakkan?",
	 "o": ["Di tabel lokasi sebagai kolom id_sumber",
		   "Di tabel sumber_air sebagai kolom id_lokasi",
		   "Di tabel perantara yang dibuat khusus",
		   "Tidak diperlukan foreign key"],
	 "a": 1},
	{"m": "Basis Data",
	 "q": "Klausa mana yang dipakai untuk menyaring hasil fungsi agregat?",
	 "o": ["WHERE", "ORDER BY", "HAVING", "GROUP BY"], "a": 2},
	{"m": "Basis Data",
	 "q": "Klausa mana yang menentukan urutan baris hasil query dari pH terendah ke tertinggi?",
	 "o": ["GROUP BY ph", "ORDER BY ph ASC", "WHERE ph ASC", "HAVING ph ASC"], "a": 1},
	{"m": "Basis Data",
	 "q": "Laporan harus menampilkan semua lokasi, termasuk yang belum memiliki data sumber air. JOIN yang tepat adalah?",
	 "o": ["INNER JOIN",
		   "CROSS JOIN",
		   "Tanpa JOIN",
		   "LEFT JOIN dengan lokasi sebagai tabel kiri"],
	 "a": 3},

	# ---------------- Sistem Operasi (5)
	{"m": "Sistem Operasi",
	 "q": "Proses yang menunggu operasi I/O berada pada keadaan?",
	 "o": ["Running", "Ready", "Waiting", "Terminated"], "a": 2},
	{"m": "Sistem Operasi",
	 "q": "Setelah operasi I/O selesai, proses berpindah ke keadaan?",
	 "o": ["Running", "Terminated", "New", "Ready"], "a": 3},
	{"m": "Sistem Operasi",
	 "q": "Algoritma penjadwalan yang memilih proses dengan burst time terkecil lebih dulu adalah?",
	 "o": ["SJF", "FCFS", "Round Robin", "Priority"], "a": 0},
	{"m": "Sistem Operasi",
	 "q": "Tujuan penerapan mutual exclusion pada sumber daya bersama adalah?",
	 "o": ["Semua proses memakai sumber daya secara bersamaan",
		   "Sumber daya dihapus dari sistem",
		   "Proses tercepat selalu didahulukan",
		   "Hanya satu proses memakai sumber daya pada satu waktu"],
	 "a": 3},
	{"m": "Sistem Operasi",
	 "q": "P1 memegang X dan menunggu Y, P2 memegang Y dan menunggu X. Kondisi ini disebut?",
	 "o": ["Deadlock", "Starvation", "Thrashing", "Race condition"], "a": 0},

	# ---------------- Kriptografi (5)
	{"m": "Kriptografi",
	 "q": "Caesar cipher dengan pergeseran 3 mengubah huruf A menjadi?",
	 "o": ["D", "C", "X", "B"], "a": 0},
	{"m": "Kriptografi",
	 "q": "Ciphertext UHELUWK dihasilkan dengan Caesar cipher pergeseran 3. Teks aslinya adalah?",
	 "o": ["REMOTE", "REBORN", "REBIRTH", "RETURN"], "a": 2},
	{"m": "Kriptografi",
	 "q": "Pada ciphertext panjang, huruf H paling sering muncul, sedangkan pada bahasa Indonesia huruf tersering adalah E. Pergeseran yang paling mungkin adalah?",
	 "o": ["2", "5", "3", "7"], "a": 2},
	{"m": "Kriptografi",
	 "q": "Sifat utama fungsi hash kriptografi seperti SHA-256 adalah?",
	 "o": ["Satu arah dan menghasilkan nilai dengan panjang tetap",
		   "Dapat dibalik dengan mudah menggunakan kunci",
		   "Selalu menghasilkan ciphertext yang bisa didekripsi",
		   "Hanya bekerja pada data angka"],
	 "a": 0},
	{"m": "Kriptografi",
	 "q": "Untuk menyimpan kata sandi pengguna, metode yang paling tepat adalah?",
	 "o": ["Caesar cipher",
		   "Vigenere cipher",
		   "Enkripsi RSA dengan kunci publik",
		   "Fungsi hash seperti SHA-256"],
	 "a": 3},

	# ---------------- Internet of Things (5)
	{"m": "Internet of Things",
	 "q": "Komponen IoT yang mengubah besaran fisik menjadi sinyal listrik adalah?",
	 "o": ["Sensor", "Aktuator", "Broker", "Gateway"], "a": 0},
	{"m": "Internet of Things",
	 "q": "Fungsi utama mikrokontroler pada perangkat IoT adalah?",
	 "o": ["Menyimpan data permanen di cloud",
		   "Membaca sinyal sensor dan mengubahnya menjadi data digital",
		   "Menampilkan grafik pada dasbor",
		   "Menyediakan sambungan listrik dari jaringan PLN"],
	 "a": 1},
	{"m": "Internet of Things",
	 "q": "Protokol pesan ringan yang umum dipakai perangkat IoT untuk mengirim data ke broker adalah?",
	 "o": ["HTTP", "MQTT", "FTP", "SMTP"], "a": 1},
	{"m": "Internet of Things",
	 "q": "Urutan alur data pada sistem pemantauan kualitas air yang benar adalah?",
	 "o": ["Sensor → broker MQTT → mikrokontroler → dasbor → modul WiFi",
		   "Dasbor → broker MQTT → sensor → mikrokontroler → modul WiFi",
		   "Mikrokontroler → sensor → dasbor → broker MQTT → modul WiFi",
		   "Sensor → mikrokontroler → modul WiFi → broker MQTT → dasbor"],
	 "a": 3},
	{"m": "Internet of Things",
	 "q": "Ambang pH normal 6,5–8,5. Pembacaan 5,2 dan 8,9 termasuk?",
	 "o": ["Keduanya di dalam ambang",
		   "Hanya 5,2 yang di luar ambang",
		   "Keduanya di luar ambang: terlalu asam dan terlalu basa",
		   "Hanya 8,9 yang di luar ambang"],
	 "a": 2}
]

## Kuesioner SUS (10 butir, skala 1-5) — instrumen Bab III 3.9, interpretasi mengacu Tabel 3.4.
const SUS_ITEMS := [
	"Saya ingin sering menggunakan game ini.",
	"Saya merasa game ini terlalu rumit.",
	"Saya merasa game ini mudah digunakan.",
	"Saya membutuhkan bantuan teknis untuk dapat memainkan game ini.",
	"Saya merasa fitur-fitur dalam game ini berjalan dengan baik.",
	"Saya merasa terlalu banyak hal yang tidak konsisten dalam game ini.",
	"Saya membayangkan kebanyakan orang akan cepat memahami cara memainkan game ini.",
	"Saya merasa game ini membingungkan saat dimainkan.",
	"Saya merasa percaya diri saat memainkan game ini.",
	"Saya perlu belajar banyak hal sebelum bisa memainkan game ini."
]

static func map_by_id(id: String) -> Dictionary:
	for m in MAPS:
		if m["id"] == id:
			return m
	return {}

static func map_index(id: String) -> int:
	for i in range(MAPS.size()):
		if MAPS[i]["id"] == id:
			return i
	return -1

## Nama badge berdasarkan id badge.
static func badge_name_of(badge_id: String) -> String:
	for m in MAPS:
		if str(m.get("badge", "")) == badge_id:
			return str(m.get("badge_name", badge_id))
	return badge_id

## Nama map berdasarkan id badge yang diberikan.
static func map_name_of_badge(badge_id: String) -> String:
	for m in MAPS:
		if str(m.get("badge", "")) == badge_id:
			return str(m.get("name", ""))
	return ""

## Jumlah badge yang bisa diperoleh (map dengan badge, yaitu Map 2-5).
static func badge_total() -> int:
	var n := 0
	for m in MAPS:
		if str(m.get("badge", "")) != "":
			n += 1
	return n

static func total_challenges() -> int:
	var n := 0
	for m in MAPS:
		n += (m["challenges"] as Array).size()
	return n

## Jumlah soal post-test untuk satu materi.
## Kunci jawaban post-test dalam bentuk larik (dipakai uji otomatis & demo).
static func answer_key() -> Array:
	var out: Array = []
	for it in TEST_ITEMS:
		out.append(int(it["a"]))
	return out

static func test_count_for(materi: String) -> int:
	var n := 0
	for it in TEST_ITEMS:
		if str(it["m"]) == materi:
			n += 1
	return n

## Daftar NPC pada satu map. Map yang belum punya daftar sendiri
## memakai satu NPC pemberi tugas dari data lama.
static func npcs_of(m: Dictionary) -> Array:
	if m.has("npcs"):
		return m["npcs"]
	return [{
		"id": "utama",
		"name": str(m.get("npc_name", "NPC")),
		"role": str(m.get("npc_role", "")),
		"sprite": str(m.get("npc_sprite", "kepala")),
		"action": "quest",
	}]

static func npc_by_id(m: Dictionary, npc_id: String) -> Dictionary:
	for n in npcs_of(m):
		if str(n.get("id", "")) == npc_id:
			return n
	return {}
