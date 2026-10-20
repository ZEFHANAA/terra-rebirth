class_name Content
extends RefCounted

## Seluruh materi permainan Terra Rebirth.
## Dipisah dari logika agar mudah diperbarui tanpa menyentuh kode UI.

const XP_PER_CHALLENGE := 30
const LEVELS := [0, 60, 140, 230, 320, 410]

const MAPS := [
	{
		"id": "kota", "name": "Kota Unggul", "material": "Tutorial & Hub",
		"desc": "Pusat kota. Temui Kepala Kota, terima tugas awal, dan pelajari aturan main.",
		"badge": "", "badge_name": "",
		"npc_name": "Kepala Kota", "npc_role": "Pemberi tugas", "npc_sprite": "kepala",
		"npcs": [
			{"id": "kepala", "name": "Kepala Kota", "role": "Pemberi tugas", "sprite": "kepala", "x": 30, "y": 10, "action": "quest"},
			{"id": "gerbang", "name": "Penjaga Gerbang", "role": "Penjaga jalan", "sprite": "penjaga", "x": 33, "y": 13, "action": "gate",
				"dialog": [
					"Gerbang ini hanya terbuka bagi yang sudah membuktikan diri. Bukan karena aku pelit, tapi karena wilayah di luar sana tidak bersahabat bagi yang belum siap.",
					"Dua syaratnya: level minimum, dan badge dari wilayah sebelumnya. Selesaikan tantangan di wilayah ini dulu, lalu kembali ke sini."
				]},
			{"id": "pedagang", "name": "Pedagang", "role": "Penjual item", "sprite": "pedagang", "x": 16, "y": 10, "action": "shop",
				"dialog": [
					"Keping data? Aku terima. Setiap tantangan yang kau selesaikan menghasilkan keping, dan keping itu bisa ditukar di sini.",
					"Lensa Analisis paling laris. Sekali pakai, tapi cukup untuk membuka petunjuk saat kau benar-benar buntu."
				]},
			{"id": "peneliti", "name": "Peneliti Lingkungan", "role": "Peneliti", "sprite": "peneliti", "x": 24, "y": 15, "action": "info",
				"dialog": [
					"Aku mencatat kerusakan lingkungan di enam wilayah. Polanya selalu sama: data kacau, mesin berhenti, pesan tak terbaca, lalu alat pemantau mati.",
					"Karena itu perjalananmu disusun berurutan: Basis Data di Hutan, Sistem Operasi di Pabrik, Kriptografi di Candi, lalu IoT di Danau. Yang terakhir adalah sumbernya.",
					"Jangan lompat urutan. Konsep di wilayah awal dipakai lagi di wilayah akhir."
				]},
		],
		"req_level": 1, "req_badge": "",
		"intro": [
			"Selamat datang di Kota Unggul, pengembara. Dulu kota ini makmur, sampai catatan data, mesin, sandi, dan perangkat pemantau kami rusak satu per satu.",
			"Kami butuh seseorang yang memahami cara kerja keempatnya. Bukan sekadar menghafal, tetapi mampu memakainya saat keadaan mendesak.",
			"Aturannya sederhana: selesaikan setiap tantangan untuk mendapat XP. Naikkan levelmu, dan kumpulkan badge di akhir setiap wilayah. Badge itulah yang membuka jalan berikutnya."
		],
		"challenges": [
			{
				"id": "kota-1", "title": "Aturan Perjalanan", "type": "mcq",
				"prompt": "Kepala Kota menjelaskan syarat membuka wilayah baru. Manakah yang benar?",
				"options": [
					"Menyelesaikan seluruh tantangan wilayah dan memenuhi level minimum",
					"Membeli item pembuka di pedagang kota",
					"Berbicara dengan semua NPC yang ada di kota",
					"Menunggu waktu permainan berjalan cukup lama"
				],
				"answer": 0,
				"explain": "Akses wilayah ditentukan oleh dua syarat sekaligus: level minimum dan badge wilayah sebelumnya. XP dari penyelesaian tantangan menaikkan level, sedangkan badge diberikan setelah tantangan akhir wilayah selesai."
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
		"req_level": 2, "req_badge": "",
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
			{"id": "hutan-cari-2", "label": "Catatan Lapangan", "x": 38, "y": 11, "challenge": "hutan-2",
				"text": [
					"Catatan ini menyebut dua tabel yang terpisah: sumber air dan lokasi. Tidak ada query yang bisa menggabungkannya.",
					"Kalau kau bisa menulis query yang menghubungkan keduanya, daftar titik tercemar bisa disusun ulang."
				]},
			{"id": "hutan-cari-3", "label": "Sampel Air", "x": 33, "y": 20, "challenge": "hutan-3",
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
				"id": "hutan-2", "title": "Menyusun Query", "type": "build",
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
				"id": "hutan-3", "title": "Membaca Hasil", "type": "mcq",
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
		"req_level": 3, "req_badge": "nature",
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
			}
		]
	},
	{
		"id": "candi", "name": "Candi Kuno", "material": "Kriptografi",
		"desc": "Prasasti menyimpan pesan terenkripsi tentang penyebab kerusakan lingkungan.",
		"badge": "cipher", "badge_name": "Cipher Key",
		"npc_name": "Penjaga Arsip", "npc_role": "Penjaga prasasti", "npc_sprite": "penjaga",
		"req_level": 4, "req_badge": "core",
		"intro": [
			"Prasasti ini ditulis oleh leluhur kami. Isinya tidak boleh dibaca sembarang orang, jadi mereka menguncinya dengan sandi.",
			"Aku hanya bisa memberi petunjuk, bukan jawabannya. Kau harus mengenali polanya sendiri."
		],
		"challenges": [
			{
				"id": "candi-1", "title": "Mengenali Sandi", "type": "mcq",
				"prompt": "Teks UHODK tidak terbaca, tetapi setiap huruf tampak bergeser tiga posisi dari huruf aslinya. Metode apakah yang dipakai?",
				"options": ["Caesar cipher", "SHA-256", "RSA", "MQTT"],
				"answer": 0,
				"explain": "Caesar cipher menggeser setiap huruf dengan jumlah tetap, sehingga polanya masih terlihat. SHA-256 adalah fungsi hash satu arah (tidak dapat dikembalikan), RSA memakai kunci publik-privat, dan MQTT adalah protokol komunikasi IoT, bukan sandi."
			},
			{
				"id": "candi-2", "title": "Memutar Cakram", "type": "cipher",
				"prompt": "Putar cakram sandi sampai pesan terbaca. Prasasti menampilkan ciphertext berikut.",
				"ciphertext": "UHELUWK",
				"answer_shift": 3,
				"explain": "Dengan pergeseran 3 ke belakang, U→R, H→E, E→B, L→I, U→R, W→T, K→H, sehingga terbaca REBIRTH."
			},
			{
				"id": "candi-3", "title": "Analisis Frekuensi", "type": "mcq",
				"prompt": "Pada ciphertext yang panjang, huruf yang paling sering muncul adalah H. Dalam bahasa Indonesia huruf yang paling sering muncul adalah E. Berapa pergeseran yang paling mungkin dipakai?",
				"options": ["2", "3", "5", "7"],
				"answer": 1,
				"explain": "Jika H mewakili E, maka setiap huruf telah digeser 3 ke depan (E→F→G→H). Analisis frekuensi memanfaatkan kenyataan bahwa pola kemunculan huruf pada teks asli masih terbawa ke ciphertext."
			}
		]
	},
	{
		"id": "danau", "name": "Danau Citra", "material": "Internet of Things",
		"desc": "Danau tercemar dan perlu sistem pemantauan kualitas air dari sensor hingga dasbor.",
		"badge": "aqua", "badge_name": "Aqua Signal Core",
		"npc_name": "Inventor", "npc_role": "Perakit perangkat", "npc_sprite": "inventor",
		"req_level": 5, "req_badge": "cipher",
		"intro": [
			"Aku punya sensor, mikrokontroler, dan modul WiFi. Yang belum ada adalah orang yang tahu bagaimana menyusunnya menjadi satu sistem.",
			"Rakit perangkatnya, lalu pastikan data dari danau benar-benar sampai ke dasbor."
		],
		"objects": [
			{"id": "danau-kom-1", "label": "Sensor pH", "x": 29, "y": 3, "gives": "sensor",
				"text": ["Komponen pertama: sensor pH. Alat ini mengubah tingkat keasaman air menjadi sinyal listrik.", "Bawa ke inventor."]},
			{"id": "danau-kom-2", "label": "Mikrokontroler", "x": 34, "y": 5, "gives": "mcu",
				"text": ["Komponen kedua: mikrokontroler. Papan ini membaca sinyal sensor dan mengubahnya menjadi data digital.", "Bawa ke inventor."]},
			{"id": "danau-kom-3", "label": "Modul WiFi", "x": 30, "y": 16, "gives": "wifi",
				"text": ["Komponen ketiga: modul WiFi. Tanpa modul ini, data hanya tersimpan di perangkat dan tidak pernah sampai ke dasbor.", "Bawa ke inventor."]}
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
				"id": "danau-2", "title": "Merakit Perangkat", "type": "craft",
				"prompt": "Pasang komponen yang kau temukan ke slot yang benar, dari input sampai data terkirim.",
				"slots": ["Sensor pH", "Mikrokontroler", "Modul WiFi", "Broker MQTT"],
				"pool": ["Sensor pH", "Mikrokontroler", "Modul WiFi", "Broker MQTT", "Kipas Pendingin", "Lampu LED"],
				"explain": "Alur IoT berjalan dari input (sensor) → pengolahan (mikrokontroler) → pengiriman (WiFi) → perantara pesan (broker MQTT) → penyajian (dasbor). Urutan ini harus benar agar data tidak hilang di tengah jalan."
			},
			{
				"id": "danau-3", "title": "Membaca Data Sensor", "type": "mcq",
				"prompt": "Ambang pH normal ditetapkan 6,5 sampai 8,5. Perangkat mana yang menunjukkan kondisi di luar ambang?",
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
				"explain": "pH 5,2 berada di bawah 6,5 (terlalu asam) dan pH 8,9 berada di atas 8,5 (terlalu basa). Hanya Sensor B (7,1) yang berada dalam rentang normal, sehingga dua perangkat lain perlu ditindaklanjuti."
			}
		]
	},
	{
		"id": "source", "name": "The Source", "material": "Integrasi 4 Bidang",
		"desc": "Final dungeon. Semua yang kau pelajari diuji sekaligus.",
		"badge": "guardian", "badge_name": "Guardian Device",
		"npc_name": "Guardian", "npc_role": "Penjaga sumber", "npc_sprite": "guardian",
		"req_level": 6, "req_badge": "aqua",
		"intro": [
			"Kau sampai juga. Di sini tidak ada petunjuk bertahap. Data, sistem, sandi, dan perangkat harus kau pakai bersamaan.",
			"Tiga ujian terakhir. Jika kau lulus, sumber kerusakan akan berhenti dan Terra pulih."
		],
		"boss": {"name": "The Source", "hp": 3},
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
			}
		]
	}
]

## Instrumen pre-test / post-test (8 butir, 2 per bidang)
const TEST_ITEMS := [
	{"q": "Apa perbedaan utama antara primary key dan foreign key?",
	 "o": ["Primary key unik untuk tiap baris, foreign key merujuk ke primary key tabel lain",
		   "Primary key boleh kosong, foreign key tidak boleh kosong",
		   "Keduanya sama, hanya berbeda nama",
		   "Foreign key harus unik, primary key boleh berulang"],
	 "a": 0},
	{"q": "Klausa mana yang dipakai untuk menyaring hasil fungsi agregat?",
	 "o": ["WHERE", "HAVING", "ORDER BY", "GROUP BY"], "a": 1},
	{"q": "Proses yang menunggu operasi I/O berada pada keadaan?",
	 "o": ["Running", "Ready", "Waiting", "Terminated"], "a": 2},
	{"q": "Algoritma penjadwalan yang memilih proses dengan burst time terkecil lebih dulu adalah?",
	 "o": ["FCFS", "SJF", "Round Robin", "Priority"], "a": 1},
	{"q": "Caesar cipher dengan pergeseran 3 mengubah huruf A menjadi?",
	 "o": ["D", "C", "X", "B"], "a": 0},
	{"q": "Sifat utama fungsi hash kriptografi adalah?",
	 "o": ["Dapat dibalik dengan mudah", "Satu arah dan menghasilkan nilai tetap panjangnya", "Selalu menghasilkan ciphertext yang bisa didekripsi", "Hanya bekerja pada angka"], "a": 1},
	{"q": "Komponen IoT yang mengubah besaran fisik menjadi sinyal listrik adalah?",
	 "o": ["Aktuator", "Sensor", "Broker", "Gateway"], "a": 1},
	{"q": "Protokol pesan ringan yang umum dipakai perangkat IoT adalah?",
	 "o": ["HTTP", "FTP", "MQTT", "SMTP"], "a": 2}
]

## Kuesioner SUS (10 butir, skala 1-5)
const SUS_ITEMS := [
	"Saya ingin sering menggunakan game ini.",
	"Saya merasa game ini terlalu rumit (tidak perlu).",
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

static func level_for_xp(xp: int) -> int:
	var lv := 1
	for i in range(LEVELS.size()):
		if xp >= LEVELS[i]:
			lv = i + 1
	return lv

static func xp_for_next_level(xp: int) -> int:
	var lv := level_for_xp(xp)
	if lv >= LEVELS.size():
		return LEVELS[LEVELS.size() - 1]
	return LEVELS[lv]

static func total_challenges() -> int:
	var n := 0
	for m in MAPS:
		n += m["challenges"].size()
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
