# ============================================================
#  Nusa — lexer (pemecah token)
#  ------------------------------------------------------------
#  Mengubah teks sumber menjadi deretan token pada tabel
#  statis. Struktur token (12 byte):
#      +0  byte   jenis (TOK_*)
#      +1  word   nomor baris (untuk pesan kesalahan)
#      +3  byte   cadangan (selalu nol)
#      +4  dword  isi (nilai angka / penunjuk / posisi)
#      +8  dword  panjang (nama dan teks)
#
#  Disiplin fungsi di sini: semua register dianggap bebas
#  dipakai (fungsi ini berdiri sendiri di luar lingkaran VM)#
#  yang paling penting, setiap `push` wajib berpasangan
#  dengan `pop` sebelum meninggalkan cabangnya, karena
#  kesalahan dilaporkan dengan lompatan jauh ke bawah.
# ============================================================

.intel_syntax noprefix

.section .bss
.globl tabel_token
.globl banyak_token
.globl kesalahan_lex
.globl baris_kesalahan
.globl banyak_kolam_teks
.globl banyak_kolam_des
tabel_token:        .space 196608  # JUMLAH_TOKEN x UK_TOKEN (16384 x 12)
banyak_token:       .space 4       # banyak token yang terisi
kesalahan_lex:      .space 4       # penanda kesalahan (0/1)
baris_kesalahan:    .space 4       # nomor baris saat kesalahan
banyak_kolam_teks:  .space 4       # pencacah kolam teks literal (dipakai parser)
banyak_kolam_des:   .space 4       # pencacah kolam desimal literal (dipakai parser)
buffer_literal:     .space 4096    # penampung sementara literal teks

.section .data
# --- isi literal untuk tabel kata kunci ---
kata_var:          .ascii "var"
kata_jika:         .ascii "jika"
kata_maka:         .ascii "maka"
kata_atau_jika:    .ascii "atau_jika"
kata_selain:       .ascii "selain"
kata_akhir_jika:   .ascii "akhir_jika"
kata_selama:       .ascii "selama"
kata_akhir_selama: .ascii "akhir_selama"
kata_untuk:        .ascii "untuk"
kata_dari:         .ascii "dari"
kata_sampai:       .ascii "sampai"
kata_langkah:      .ascii "langkah"
kata_akhir_untuk:  .ascii "akhir_untuk"
kata_fungsi:       .ascii "fungsi"
kata_akhir_fungsi: .ascii "akhir_fungsi"
kata_kembalikan:   .ascii "kembalikan"
kata_benar:        .ascii "benar"
kata_salah:        .ascii "salah"
kata_kosong:       .ascii "kosong"
kata_dan:          .ascii "dan"
kata_atau:         .ascii "atau"
kata_tidak:        .ascii "tidak"

# --- tabel kata kunci: (alamat, panjang, jenis), berakhir 0 ---
tabel_kata_kunci:
    .long kata_var,          3,  TOK_VAR
    .long kata_jika,         4,  TOK_JIKA
    .long kata_maka,         4,  TOK_MAKA
    .long kata_atau_jika,    9,  TOK_ATAU_JIKA
    .long kata_selain,       6,  TOK_SELAIN
    .long kata_akhir_jika,   10, TOK_AKHIR_JIKA
    .long kata_selama,       6,  TOK_SELAMA
    .long kata_akhir_selama, 12, TOK_AKHIR_SELAMA
    .long kata_untuk,        5,  TOK_UNTUK
    .long kata_dari,         4,  TOK_DARI
    .long kata_sampai,       6,  TOK_SAMPAI
    .long kata_langkah,      7,  TOK_LANGKAH
    .long kata_akhir_untuk,  11, TOK_AKHIR_UNTUK
    .long kata_fungsi,       6,  TOK_FUNGSI
    .long kata_akhir_fungsi, 12, TOK_AKHIR_FUNGSI
    .long kata_kembalikan,   10, TOK_KEMBALIKAN
    .long kata_benar,        5,  TOK_BENAR
    .long kata_salah,        5,  TOK_SALAH
    .long kata_kosong,       6,  TOK_KOSONG
    .long kata_dan,          3,  TOK_DAN
    .long kata_atau,         4,  TOK_ATAU
    .long kata_tidak,        5,  TOK_TIDAK
    .long 0                        # penutup tabel

# --- pesan kesalahan ---
pesan_karakter:    .ascii "kesalahan: karakter tidak dikenal\n"
panj_p_karakter:   .long 34
pesan_besar:       .ascii "kesalahan: bilangan terlalu besar\n"
panj_p_besar:      .long 34
pesan_teks_buka:   .ascii "kesalahan: teks tidak ditutup\n"
panj_p_teks_buka:  .long 30
pesan_teks_panjang:.ascii "kesalahan: teks terlalu panjang\n"
panj_p_teks_panjang: .long 32
pesan_token:       .ascii "kesalahan: terlalu banyak token\n"
panj_p_token:      .long 32

.section .text
.extern kirim_teks_awet
.extern buat_teks_baru
.extern ubah_teks_ke_desimal
.extern lapor_dan_berhenti

# ============================================================
#  laksana_lexer
#  Masukan : edx = alamat teks sumber, ecx = panjang teks.
#  Keluaran: tabel token terisi, `banyak_token` terisi.
#            Bila ada kesalahan: `kesalahan_lex` = 1,
#            `baris_kesalahan` berisi baris, dan pesan sudah
#            dicetak ke layar.
# ============================================================
.globl laksana_lexer
laksana_lexer:
    push ebx
    push esi
    push edi
    push ebp
    mov  dword ptr [kesalahan_lex], 0
    mov  dword ptr [banyak_token], 0
    mov  esi, edx                # esi = posisi pembacaan
    lea  edi, [edx + ecx]        # edi = ujung teks
    mov  ebp, 1                  # ebp = nomor baris

loop_utama:
    cmp  esi, edi
    jae  akhir_teks
    movzx eax, byte ptr [esi]
    cmp  al, ' '
    je   lewati_char
    cmp  al, 9                   # tab
    je   lewati_char
    cmp  al, 13                  # carriage return dibuang
    je   lewati_char
    cmp  al, 10                  # line feed = baris baru
    je   baris_baru
    cmp  al, '#'                 # komentar sampai akhir baris
    je   lewati_komentar
    cmp  al, '"'
    je   baca_teks
    cmp  al, '0'
    jb   cek_kata_mulai
    cmp  al, '9'
    ja   cek_kata_mulai
    jmp  baca_angka
cek_kata_mulai:
    call cek_awal_kata
    jnz  bukan_kata
    jmp  baca_kata
bukan_kata:
    movzx eax, byte ptr [esi]
    jmp  operator_utama

lewati_char:
    inc  esi
    jmp  loop_utama
baris_baru:
    inc  ebp
    inc  esi
    jmp  loop_utama
lewati_komentar:
    inc  esi
    cmp  esi, edi
    jae  akhir_teks
    movzx eax, byte ptr [esi]
    cmp  al, 10
    je   baris_baru
    jmp  lewati_komentar

# ============================================================
#  cek_awal_kata
#  ZF = 1 bila al adalah huruf awal kata (a-z, A-Z, _).
#  Mengubah eax# tidak mengubah lainnya.
# ============================================================
cek_awal_kata:
    mov  cl, al
    cmp  al, '_'
    je   awal_ya
    or   al, 0x20                # huruf besar menjadi kecil
    sub  al, 'a'
    cmp  al, 25
    jbe  awal_ya
    xor  eax, eax
    inc  eax                     # bukan: ZF = 0
    ret
awal_ya:
    xor  eax, eax                # ya: ZF = 1
    ret

# ============================================================
#  cek_huruf
#  ZF = 1 bila al adalah huruf kata (a-z, A-Z, 0-9, _).
#  Mengubah eax dan ecx# tidak mengubah lainnya.
# ============================================================
cek_huruf:
    mov  cl, al
    cmp  al, '_'
    je   huruf_ya
    or   al, 0x20
    sub  al, 'a'
    cmp  al, 25
    jbe  huruf_ya
    mov  al, cl                  # pulihkan karakter asli
    sub  al, '0'
    cmp  al, 9
    jbe  huruf_ya
    xor  eax, eax
    inc  eax                     # bukan: ZF = 0
    ret
huruf_ya:
    xor  eax, eax                # ya: ZF = 1
    ret

# ============================================================
#  baca_kata: nama atau kata kunci
#  Token nama: isi = posisi kata di sumber, panjang = panjang.
#  Token kata kunci: isi = 0, panjang = 0.
# ============================================================
baca_kata:
    mov  edx, esi                # edx = awal kata
baca_kata_loop:
    cmp  esi, edi
    jae  kata_akhir
    movzx eax, byte ptr [esi]
    call cek_huruf
    jnz  kata_akhir
    inc  esi
    jmp  baca_kata_loop
kata_akhir:
    mov  eax, esi
    sub  eax, edx                # eax = panjang kata
    push eax                     # [esp+4] = panjang
    push edx                     # [esp]   = awal
    lea  ecx, [tabel_kata_kunci]
cari_kata_loop:
    mov  eax, [ecx]              # alamat kata kunci
    test eax, eax
    jz   kata_umum               # ujung tabel: bukan kata kunci
    mov  eax, [ecx + 4]          # panjang kata kunci
    cmp  [esp + 4], eax
    jne  cari_berikut
    # panjang cocok: bandingkan isi huruf demi huruf
    push ecx                     # [esp+8]  = kursor tabel
    push esi                     # [esp+4]  = posisi pembacaan
    push edi                     # [esp]    = ujung teks
    mov  ecx, [esp + 8]          # kursor tabel
    mov  eax, [ecx]              # alamat kata kunci
    mov  edx, [esp + 12]         # awal kata
    mov  ecx, [esp + 16]         # panjang kata
    call banding_sama            # ZF = 1 bila sama
    pop  edi
    pop  esi
    pop  ecx
    jnz  cari_berikut
    # ketemu: jenis kata kunci ada di [ecx + 8]
    mov  eax, [ecx + 8]
    push 0                       # panjang
    push 0                       # isi
    push eax                     # jenis
    call terbitkan_token
    add  esp, 12
    pop  edx                     # buang simpanan awal
    pop  eax                     # buang simpanan panjang
    jmp  loop_utama
cari_berikut:
    add  ecx, 12
    jmp  cari_kata_loop
kata_umum:
    pop  edx                     # awal kata
    pop  eax                     # panjang kata
    push eax                     # panjang
    push edx                     # isi = posisi
    push TOK_NAMA
    call terbitkan_token
    add  esp, 12
    jmp  loop_utama

# ============================================================
#  banding_sama
#  Membandingkan dua rangkaian byte.
#  Masukan : edx = sumber, eax = pembanding, ecx = panjang.
#  Keluaran: ZF = 1 bila sama semua, ZF = 0 bila berbeda.
#  Mengubah eax tidak, ecx, edx tidak, esi, edi.
# ============================================================
banding_sama:
    push esi
    push edi
    mov  esi, edx
    mov  edi, eax
    repe cmpsb
    pop  edi
    pop  esi
    ret

# ============================================================
#  baca_teks: literal teks dalam tanda kutip
#  Mendukung urutan pelarian: \n, \t, \", \\ .
#  Token: isi = penunjuk teks di arena, panjang = panjang.
# ============================================================
baca_teks:
    inc  esi                     # lewati tanda kutip pembuka
    lea  edx, [buffer_literal]
    xor  ecx, ecx                # panjang literal yang terkumpul
baca_teks_loop:
    cmp  esi, edi
    jae  kesalahan_teks_buka
    movzx eax, byte ptr [esi]
    cmp  al, '"'
    je   teks_selesai
    cmp  al, 10
    je   kesalahan_teks_buka     # literal tidak boleh lintas baris
    cmp  al, 92                  # '\' = urutan pelarian
    je   baca_escape
    cmp  ecx, 4095
    jae  kesalahan_teks_panjang
    mov  [edx], al
    inc  edx
    inc  ecx
    inc  esi
    jmp  baca_teks_loop
baca_escape:
    inc  esi                     # lewati tanda miring
    cmp  esi, edi
    jae  kesalahan_teks_buka
    movzx eax, byte ptr [esi]
    cmp  al, 'n'
    je   esc_baris
    cmp  al, 't'
    je   esc_tab
    cmp  al, '"'
    je   esc_kutip
    cmp  al, 92                  # '\'
    je   esc_miring
    jmp  esc_tulis               # urutan tak dikenal: apa adanya
esc_baris:
    mov  al, 10
    jmp  esc_tulis
esc_tab:
    mov  al, 9
    jmp  esc_tulis
esc_kutip:
    mov  al, '"'
    jmp  esc_tulis
esc_miring:
    mov  al, 92
esc_tulis:
    cmp  ecx, 4095
    jae  kesalahan_teks_panjang
    mov  [edx], al
    inc  edx
    inc  ecx
    inc  esi
    jmp  baca_teks_loop
teks_selesai:
    inc  esi                     # lewati tanda kutip penutup
    push esi                     # simpan posisi pembacaan
    push ecx                     # simpan panjang
    call buat_teks_baru          # eax = payload teks baru
    mov  edx, eax
    pop  ecx                     # panjang
    pop  esi                     # posisi pembacaan
    # salin isi literal ke arena
    push esi
    push edi
    push ecx
    lea  esi, [buffer_literal]
    mov  edi, edx
    rep  movsb
    pop  ecx
    pop  edi
    pop  esi
    # terbitkan token teks
    push ecx                     # panjang
    push edx                     # isi = penunjuk
    push TOK_TEKS
    call terbitkan_token
    add  esp, 12
    jmp  loop_utama

# ============================================================
#  baca_angka: bilangan bulat atau desimal
#  Token bilangan : isi = nilai 32-bit bertanda.
#  Token desimal  : isi = alamat 8-byte double di arena.
# ============================================================
baca_angka:
    mov  edx, esi                # edx = awal bilangan
    xor  eax, eax                # eax = nilai yang terkumpul
baca_angka_loop:
    cmp  esi, edi
    jae  angka_jadi
    movzx ecx, byte ptr [esi]
    sub  ecx, '0'
    cmp  ecx, 9
    ja   angka_cek_titik
    imul eax, eax, 10
    jo   kesalahan_besar
    add  eax, ecx
    jo   kesalahan_besar
    inc  esi
    jmp  baca_angka_loop
angka_cek_titik:
    cmp  byte ptr [esi], '.'
    jne  angka_jadi
    # desimal: perluas pembacaan sampai akhir pecahan
    inc  esi                     # lewati titik
baca_pecahan_loop:
    cmp  esi, edi
    jae  angka_desimal
    movzx ecx, byte ptr [esi]
    sub  ecx, '0'
    cmp  ecx, 9
    ja   angka_desimal
    inc  esi
    jmp  baca_pecahan_loop
angka_desimal:
    # ubah_teks_ke_desimal(edx = awal, ecx = panjang) memakai
    # ebp sebagai penanda negatif, jadi simpan baris dulu
    push ebp
    push edi
    push esi
    push edx
    mov  ecx, esi
    sub  ecx, edx                # panjang seluruh bilangan
    call ubah_teks_ke_desimal    # eax = alamat double, ecx = 0/1
    pop  edx
    pop  esi
    pop  edi
    pop  ebp
    test ecx, ecx
    jnz  kesalahan_besar         # tidak mungkin (digit sudah sah)
    push 0                       # panjang
    push eax                     # isi = alamat double
    push TOK_DESIMAL
    call terbitkan_token
    add  esp, 12
    jmp  loop_utama
angka_jadi:
    push 0                       # panjang
    push eax                     # isi = nilai
    push TOK_ANGKA
    call terbitkan_token
    add  esp, 12
    jmp  loop_utama

# ============================================================
#  operator_utama: tanda baca dan operator
#  Token: jenis TOK_OPERATOR, isi = kode TK_* .
# ============================================================
operator_utama:
    cmp  al, '+'
    je   op_plus
    cmp  al, '-'
    je   op_minus
    cmp  al, '*'
    je   op_bintang
    cmp  al, '/'
    je   op_slash
    cmp  al, '%'
    je   op_persen
    cmp  al, '('
    je   op_buka_kurung
    cmp  al, ')'
    je   op_tutup_kurung
    cmp  al, '['
    je   op_buka_kotak
    cmp  al, ']'
    je   op_tutup_kotak
    cmp  al, '{'
    je   op_buka_kurap
    cmp  al, '}'
    je   op_tutup_kurap
    cmp  al, ','
    je   op_koma
    cmp  al, '='
    je   op_sama
    cmp  al, '!'
    je   op_bang
    cmp  al, '<'
    je   cek_kurang_polah
    cmp  al, '>'
    je   cek_lebih_polah
    jmp  kesalahan_karakter

op_plus:
    mov  al, TK_TAMBAH
    call terbitkan_op
    inc  esi
    jmp  loop_utama
op_minus:
    mov  al, TK_MINUS
    call terbitkan_op
    inc  esi
    jmp  loop_utama
op_bintang:
    lea  eax, [esi + 1]
    cmp  eax, edi
    jae  bintang_tunggal
    cmp  byte ptr [esi + 1], '*'
    je   dua_pangkat
bintang_tunggal:
    mov  al, TK_KALI
    call terbitkan_op
    inc  esi
    jmp  loop_utama
dua_pangkat:
    mov  al, TK_PANGKAT
    call terbitkan_op
    add  esi, 2
    jmp  loop_utama
op_slash:
    lea  eax, [esi + 1]
    cmp  eax, edi
    jae  slash_tunggal
    cmp  byte ptr [esi + 1], '/'
    je   dua_bagi_bulat
slash_tunggal:
    mov  al, TK_BAGI
    call terbitkan_op
    inc  esi
    jmp  loop_utama
dua_bagi_bulat:
    mov  al, TK_BAGI_BULAT
    call terbitkan_op
    add  esi, 2
    jmp  loop_utama
op_persen:
    mov  al, TK_SISA
    call terbitkan_op
    inc  esi
    jmp  loop_utama
op_buka_kurung:
    mov  al, TK_BUKA_KURUNG
    call terbitkan_op
    inc  esi
    jmp  loop_utama
op_tutup_kurung:
    mov  al, TK_TUTUP_KURUNG
    call terbitkan_op
    inc  esi
    jmp  loop_utama
op_buka_kotak:
    mov  al, TK_BUKA_KOTAK
    call terbitkan_op
    inc  esi
    jmp  loop_utama
op_tutup_kotak:
    mov  al, TK_TUTUP_KOTAK
    call terbitkan_op
    inc  esi
    jmp  loop_utama
op_buka_kurap:
    mov  al, TK_BUKA_KURAP
    call terbitkan_op
    inc  esi
    jmp  loop_utama
op_tutup_kurap:
    mov  al, TK_TUTUP_KURAP
    call terbitkan_op
    inc  esi
    jmp  loop_utama
op_koma:
    mov  al, TK_KOMA
    call terbitkan_op
    inc  esi
    jmp  loop_utama
op_sama:
    lea  eax, [esi + 1]
    cmp  eax, edi
    jae  sama_tunggal
    cmp  byte ptr [esi + 1], '='
    je   dua_sama                # '==' = perbandingan juga
sama_tunggal:
    mov  al, TK_SAMA
    call terbitkan_op
    inc  esi
    jmp  loop_utama
dua_sama:
    mov  al, TK_SAMA
    call terbitkan_op
    add  esi, 2
    jmp  loop_utama
op_bang:
    lea  eax, [esi + 1]
    cmp  eax, edi
    jae  kesalahan_karakter      # '!' tunggal tidak dikenal
    cmp  byte ptr [esi + 1], '='
    jne  kesalahan_karakter
    mov  al, TK_TIDAK_SAMA
    call terbitkan_op
    add  esi, 2
    jmp  loop_utama
cek_kurang_polah:
    lea  eax, [esi + 1]
    cmp  eax, edi
    jae  kurang_tunggal
    movzx eax, byte ptr [esi + 1]
    cmp  al, '-'
    je   dua_isi                 # '<-' = penugasan
    cmp  al, '='
    je   dua_kurang_sama
kurang_tunggal:
    mov  al, TK_KURANG
    call terbitkan_op
    inc  esi
    jmp  loop_utama
dua_isi:
    mov  al, TK_ISI
    call terbitkan_op
    add  esi, 2
    jmp  loop_utama
dua_kurang_sama:
    mov  al, TK_KURANG_SAMA
    call terbitkan_op
    add  esi, 2
    jmp  loop_utama
cek_lebih_polah:
    lea  eax, [esi + 1]
    cmp  eax, edi
    jae  lebih_tunggal
    cmp  byte ptr [esi + 1], '='
    je   dua_lebih_sama
lebih_tunggal:
    mov  al, TK_LEBIH
    call terbitkan_op
    inc  esi
    jmp  loop_utama
dua_lebih_sama:
    mov  al, TK_LEBIH_SAMA
    call terbitkan_op
    add  esi, 2
    jmp  loop_utama

# ============================================================
#  terbitkan_op: terbitkan token operator
#  Masukan : al = kode TK_* .
#  Mengubah: eax, ebx, edx, ecx. Awet: esi, edi, ebp.
# ============================================================
terbitkan_op:
    push ebx
    movzx ebx, al
    push 0                       # panjang
    push ebx                     # isi = kode operator
    push TOK_OPERATOR
    call terbitkan_token
    add  esp, 12
    pop  ebx
    ret

# ============================================================
#  terbitkan_token
#  Masukan (tumpukan):   [esp+4] = jenis, [esp+8] = isi,
#                        [esp+12] = panjang.
#  Mengubah: eax, ebx, ecx, edx, esi, edi. Awet: ebp.
# ============================================================
terbitkan_token:
    push ebx
    push esi
    push edi
    push ebp
    mov  ebx, [esp + 20]         # jenis
    mov  esi, [esp + 24]         # isi
    mov  edi, [esp + 28]         # panjang
    mov  eax, [banyak_token]
    cmp  eax, JUMLAH_TOKEN
    jae  token_penuh
    imul edx, eax, UK_TOKEN
    lea  edx, [tabel_token + edx]
    mov  [edx], bl
    mov  word ptr [edx + 1], bp  # baris saat ini
    mov  [edx + 4], esi
    mov  [edx + 8], edi
    inc  dword ptr [banyak_token]
    pop  ebp
    pop  edi
    pop  esi
    pop  ebx
    ret
token_penuh:
    cmp  dword ptr [kesalahan_lex], 0
    jne  token_penuh_diam        # sudah dilaporkan sebelumnya
    mov  eax, offset pesan_token
    mov  ecx, [panj_p_token]
    call kirim_teks_awet
    mov  dword ptr [kesalahan_lex], 1
    mov  [baris_kesalahan], bp
token_penuh_diam:
    pop  ebp
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  Akhir teks: terbitkan TOK_SELESAI lalu pulang.
# ============================================================
akhir_teks:
    push 0                       # panjang
    push 0                       # isi
    push TOK_SELESAI
    call terbitkan_token
    add  esp, 12
    pop  ebp
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  Kesalahan: cetak pesan, tandai, pulang.
#  Di sini tumpukan selalu sudah seimbang (lihat disiplin
#  `push`/`pop` di setiap cabang di atas).
# ============================================================
kesalahan_karakter:
    mov  eax, offset pesan_karakter
    mov  ecx, [panj_p_karakter]
    jmp  ragam_kesalahan
kesalahan_besar:
    mov  eax, offset pesan_besar
    mov  ecx, [panj_p_besar]
    jmp  ragam_kesalahan
kesalahan_teks_buka:
    mov  eax, offset pesan_teks_buka
    mov  ecx, [panj_p_teks_buka]
    jmp  ragam_kesalahan
kesalahan_teks_panjang:
    mov  eax, offset pesan_teks_panjang
    mov  ecx, [panj_p_teks_panjang]
    jmp  ragam_kesalahan
ragam_kesalahan:
    call kirim_teks_awet
    mov  dword ptr [kesalahan_lex], 1
    mov  [baris_kesalahan], ebp
    pop  ebp
    pop  edi
    pop  esi
    pop  ebx
    ret