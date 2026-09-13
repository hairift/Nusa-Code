# ============================================================
#  Nusa — definisi bersama: tipe nilai, opcode, ukuran
#  ------------------------------------------------------------
#  Berkas ini WAJIB diurutkan paling awal pada pemanggilan
#  `as` agar semua konstanta sudah terdefinisi sebelum
#  berkas lain memakainya.
# ============================================================

.intel_syntax noprefix

# ------------------------------------------------------------
#  Tipe nilai runtime (byte 0 dari nilai 8 byte)
# ------------------------------------------------------------
.equ TIPE_BILANGAN, 0        # bilangan bulat 32-bit bertanda
.equ TIPE_DESIMAL,  1        # desimal: payload = alamat 8-byte double
.equ TIPE_TEKS,     2        # teks: payload = alamat struct teks
.equ TIPE_LOGIKA,   3        # benar/salah: payload 0 atau 1
.equ TIPE_KOSONG,   4        # kosong: payload tidak terpakai
.equ TIPE_DAFTAR,   5        # daftar: payload = alamat struct daftar
.equ TIPE_KAMUS,    6        # kamus: payload = alamat struct kamus
.equ TIPE_FUNGSI,   7        # fungsi (cadangan, belum dipakai)
.equ TIPE_BELUM,    255      # penanda slot belum diisi / ember kamus kosong

# ------------------------------------------------------------
#  Opcode bytecode (byte pertama setiap instruksi)
#  Daftar dan makna lengkap: docs/ARSITEKTUR.md
# ------------------------------------------------------------
.equ OP_HENTI,         0     # menghentikan VM, kode keluar 0
.equ OP_DORONG_K,      1     # dorong konstanta bilangan, operan 4 byte
.equ OP_DORONG_T,      2     # dorong konstanta teks, operan 2 byte (indeks kolam)
.equ OP_DORONG_D,      3     # dorong konstanta desimal, operan 2 byte (indeks kolam)
.equ OP_DORONG_B,      4     # dorong logika, operan 1 byte (0/1)
.equ OP_DORONG_KOSONG, 5     # dorong nilai kosong
.equ OP_DORONG_L,      6     # dorong variabel lokal, operan 1 byte (indeks)
.equ OP_SIMPAN_L,      7     # simpan nilai puncak ke lokal, operan 1 byte
.equ OP_TAMBAH,        8     # pop 2, push hasil penjumlahan
.equ OP_KURANG,        9     # pop 2, push hasil pengurangan
.equ OP_KALI,          10    # pop 2, push hasil perkalian
.equ OP_BAGI,          11    # pop 2, push hasil pembagian
.equ OP_BAGI_BULAT,    12    # pop 2, push hasil pembagian bulat
.equ OP_SISA,          13    # pop 2, push sisa bagi
.equ OP_PANGKAT,       14    # pop 2, push hasil pangkat
.equ OP_NEGATIF,       15    # pop 1, push negasi (unary)
.equ OP_TIDAK,         16    # pop 1, push ingkaran logika (unary)
.equ OP_SAMA,          17    # pop 2, push benar/salah: a = b
.equ OP_TIDAK_SAMA,    18    # pop 2, push benar/salah: a != b
.equ OP_KURANG_DARI,   19    # pop 2, push benar/salah: a < b
.equ OP_LEBIH_DARI,    20    # pop 2, push benar/salah: a > b
.equ OP_KURANG_SAMA,   21    # pop 2, push benar/salah: a <= b
.equ OP_LEBIH_SAMA,    22    # pop 2, push benar/salah: a >= b
.equ OP_DAN,           23    # pop 2, push a dan b (logika)
.equ OP_ATAU,          24    # pop 2, push a atau b (logika)
.equ OP_LONCAT,        25    # lompat tak bersyarat, operan 2 byte (relatif)
.equ OP_LONCAT_SALAH,  26    # pop 1, lompat bila nilai dianggap salah
.equ OP_LONCAT_BENAR,  27    # pop 1, lompat bila nilai dianggap benar
.equ OP_DUP,           28    # gandakan nilai puncak
.equ OP_POP,           29    # buang nilai puncak
.equ OP_PANGGIL,       30    # panggil fungsi, operan: indeks 1 byte, argc 1 byte
.equ OP_KEMBALI,       31    # kembalikan nilai puncak dari fungsi
.equ OP_BAKAWAN,       32    # panggil fungsi baku, operan: indeks 1 byte, argc 1 byte
.equ OP_AMBIL_UNSUR,   33    # pop indeks, pop kontainer, push unsur
.equ OP_SIMPAN_UNSUR,  34    # pop nilai, pop indeks, pop kontainer, simpan unsur
.equ OP_BUAT_DAFTAR,   35    # pop n nilai, bangun daftar, operan 2 byte (n)
.equ OP_BUAT_KAMUS,    36    # pop 2n nilai, bangun kamus, operan 2 byte (n)

# ------------------------------------------------------------
#  Jenis token hasil lexer
# ------------------------------------------------------------
.equ TOK_SELESAI,       0    # akhir dari teks sumber
.equ TOK_NAMA,          1    # nama variabel/fungsi
.equ TOK_ANGKA,         2    # literal bilangan bulat
.equ TOK_DESIMAL,       3    # literal bilangan desimal
.equ TOK_TEKS,          4    # literal teks
# --- operator dan tanda baca (isi = kode TK_* berikut) ---
# (pakai awalan TK_ agar tidak bertabrakan dengan opcode OP_*)
.equ TOK_OPERATOR,      5
.equ TK_BUKA_KURUNG,    1    # (
.equ TK_TUTUP_KURUNG,   2    # )
.equ TK_BUKA_KOTAK,     3    # [
.equ TK_TUTUP_KOTAK,    4    # ]
.equ TK_BUKA_KURAP,     5    # {
.equ TK_TUTUP_KURAP,    6    # }
.equ TK_KOMA,           7    # ,
.equ TK_ISI,            8    # <-
.equ TK_SAMA,           9    # = atau ==
.equ TK_TIDAK_SAMA,     10   # !=
.equ TK_KURANG,         11   # <
.equ TK_LEBIH,          12   # >
.equ TK_KURANG_SAMA,    13   # <=
.equ TK_LEBIH_SAMA,     14   # >=
.equ TK_TAMBAH,         15   # +
.equ TK_MINUS,          16   # -
.equ TK_KALI,           17   # *
.equ TK_BAGI,           18   # /
.equ TK_BAGI_BULAT,     19   # //
.equ TK_SISA,           20   # %
.equ TK_PANGKAT,        21   # **
# --- kata kunci ---
.equ TOK_VAR,          10
.equ TOK_JIKA,         11
.equ TOK_MAKA,         12
.equ TOK_ATAU_JIKA,    13
.equ TOK_SELAIN,       14
.equ TOK_AKHIR_JIKA,   15
.equ TOK_SELAMA,       16
.equ TOK_AKHIR_SELAMA, 17
.equ TOK_UNTUK,        18
.equ TOK_DARI,         19
.equ TOK_SAMPAI,       20
.equ TOK_LANGKAH,      21
.equ TOK_AKHIR_UNTUK,  22
.equ TOK_FUNGSI,       23
.equ TOK_AKHIR_FUNGSI, 24
.equ TOK_KEMBALIKAN,   25
.equ TOK_BENAR,        26
.equ TOK_SALAH,        27
.equ TOK_KOSONG,       28
.equ TOK_DAN,          29
.equ TOK_ATAU,         30
.equ TOK_TIDAK,        31

# ------------------------------------------------------------
#  Struktur nilai 8 byte:
#    byte 0      = tipe
#    byte 1-3    = cadangan (selalu nol)
#    byte 4-7    = isi (payload)
#  Struktur teks (payload menunjuk ke sini):
#    +0  dword   panjang (jumlah byte)
#    +4  byte[]  isi teks (tanpa penutup)
#  Struktur daftar:
#    +0  dword   panjang (terisi)
#    +4  dword   kapasitas
#    +8  byte[]  nilai-nilai (8 byte per entri)
#  Struktur kamus:
#    +0  dword   terisi
#    +4  dword   kapasitas (jumlah ember)
#    +8  byte[]  ember: 8 byte kunci + 8 byte nilai per pasang
#  Bingkai pemanggilan (12 byte):
#    +0  dword   alamat kembali (ip pemanggil)
#    +4  dword   dasar lokal pemanggil (ebx lama)
#    +8  dword   puncak tumpukan pemanggil (edi lama)
# ------------------------------------------------------------

# ------------------------------------------------------------
#  Ukuran dan batasan
# ------------------------------------------------------------
.equ UK_NILAI,         8        # ukuran satu entri nilai (byte)
.equ JUMLAH_NILAI,     8192     # kapasitas tumpukan nilai
.equ UK_TUMPUKAN,      65536    # JUMLAH_NILAI * 8
.equ JUMLAH_BINGKAI,   4096     # kapasitas tumpukan bingkai
.equ UK_BINGKAI,       12
.equ UK_FRAME,         49152    # JUMLAH_BINGKAI * 12
.equ UK_HEAP,          16777216 # ukuran arena alokasi (16 MiB)
.equ UK_KODE,          524288   # kapasitas buffer bytecode (512 KiB)
.equ JUMLAH_TOKEN,     16384    # kapasitas tabel token
.equ UK_TOKEN,         12       # ukuran satu token
.equ JUMLAH_KOLAM_TEKS, 1024    # kapasitas kolam teks literal
.equ JUMLAH_KOLAM_DES, 256      # kapasitas kolam desimal literal
.equ JUMLAH_FUNGSI,    256      # kapasitas tabel fungsi
.equ JUMLAH_LOKAL,     128      # kapasitas variabel lokal per fungsi
.equ JUMLAH_BAWAAN,    26       # banyak fungsi baku
.equ JUMLAH_ARGUMEN,   64       # banyak argumen baris perintah maksimal