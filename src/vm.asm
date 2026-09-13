# ============================================================
#  Nusa — mesin virtual bytecode (inti eksekusi)
#  ------------------------------------------------------------
#  Register VM (dijaga sepanjang lingkaran utama):
#      esi = penunjuk instruksi (alamat bytecode)
#      edi = puncak tumpukan nilai (alamat berikutnya)
#      ebx = dasar variabel lokal fungsi aktif
#
#  Tumpukan nilai  : 8192 entri (uk. 8 byte), di .bss
#  Tumpukan bingkai: 4096 bingkai pemanggilan (12 byte)
#
#  Konvensi fungsi baku (BAKAWAN):
#      Masuk : edx = alamat nilai arg ke-0 (wilayah tumpukan),
#              eax = banyak argumen
#      Keluar: hasil 8 byte ditulis ke [edx] oleh fungsi baku
#      Wajib : tidak mengubah ebx, esi, edi, edx
#      Boleh : mengubah eax, ecx (dan tumpukan x86)
# ============================================================

.intel_syntax noprefix

.section .bss
ip:              .space 4        # penunjuk instruksi (absolut)
tumpukan_nilai:  .space UK_TUMPUKAN
tumpukan_bingkai:.space UK_FRAME
banyak_bingkai:  .space 4        # banyak bingkai aktif
tabel_fungsi:    .space 4096     # 256 entri x 8 byte
kolam_teks:      .space 4096     # 1024 entri x 4 byte (payload)
kolam_desimal:   .space 2048     # 256 entri x 8 byte (double)
buffer_kode:     .space UK_KODE  # kawasan bytecode hasil parser

# dipakai bersama: parser.asm dan main (uji)
.globl ip
.globl tabel_fungsi
.globl kolam_teks
.globl kolam_desimal
.globl buffer_kode
.globl banyak_bingkai

.section .data
# --- pesan kesalahan mesin virtual ---
pesan_tumpakan_penuh: .ascii "kesalahan: tumpukan nilai penuh\n"
panj_p_tump:          .long 32
pesan_kosong:         .ascii "kesalahan: tumpukan nilai kosong\n"
panj_p_kosong:        .long 33
pesan_op_aneh:        .ascii "kesalahan: opcode tidak dikenal\n"
panj_p_aneh:          .long 32
pesan_tipe:           .ascii "kesalahan: tipe nilai tidak cocok\n"
panj_p_tipe:          .long 34
pesan_nol:            .ascii "kesalahan: pembagian dengan nol\n"
panj_p_nol:           .long 33
pesan_meluap:         .ascii "kesalahan: hasil meluap (bilangan 32-bit)\n"
panj_p_meluap:        .long 42
pesan_bingkai:        .ascii "kesalahan: kedalaman pemanggilan maksimum\n"
panj_p_bingkai:       .long 42
pesan_kembali:        .ascii "kesalahan: kembalikan di luar fungsi\n"
panj_p_kembali:       .long 38
pesan_fungsi_1:       .ascii "kesalahan: fungsi belum ada\n"
panj_p_fungsi_1:      .long 28
pesan_fungsi_2:       .ascii "kesalahan: fungsi belum dikompilasi\n"
panj_p_fungsi_2:      .long 37
pesan_fungsi_3:       .ascii "kesalahan: jumlah parameter tidak cocok\n"
panj_p_fungsi_3:      .long 40
pesan_bawaan:         .ascii "kesalahan: fungsi baku tidak dikenal\n"
panj_p_bawaan:        .long 37

.section .text
.extern kirim_teks_awet
.extern teks_gabungkan
.extern teks_bandingkan
.extern buat_desimal_baru
.extern unsur_ambil
.extern unsur_simpan
.extern daftar_baru
.extern kamus_baru
.extern tabel_bawaan
.extern ubah_bilangan_ke_teks
.extern kirim_keluar

# ------------------------------------------------------------
#  jalankan_vm
#  Menjalankan bytecode dari alamat pada variabel global `ip`.
#  Keluaran: eax = kode keluar (0 sukses, 1 kesalahan).
#  Memakai: esi, edi, ebx tanpa menyimpannya (register VM).
# ------------------------------------------------------------
.globl jalankan_vm
jalankan_vm:
    mov  esi, [ip]
    lea  edi, [tumpukan_nilai]
    mov  ebx, edi                        # dasar lokal frame utama
    mov  dword ptr [banyak_bingkai], 0

ambil_opcode:                            # --- lingkaran utama ---
    movzx eax, byte ptr [esi]
    inc  esi
    cmp  eax, OP_HENTI
    je   laksana_henti
    cmp  eax, OP_DORONG_K
    je   laksana_dorong_k
    cmp  eax, OP_DORONG_T
    je   laksana_dorong_t
    cmp  eax, OP_DORONG_D
    je   laksana_dorong_d
    cmp  eax, OP_DORONG_B
    je   laksana_dorong_b
    cmp  eax, OP_DORONG_KOSONG
    je   laksana_dorong_kosong
    cmp  eax, OP_DORONG_L
    je   laksana_dorong_l
    cmp  eax, OP_SIMPAN_L
    je   laksana_simpan_l
    cmp  eax, OP_TAMBAH
    je   laksana_tambah
    cmp  eax, OP_KURANG
    je   laksana_kurang
    cmp  eax, OP_KALI
    je   laksana_kali
    cmp  eax, OP_BAGI
    je   laksana_bagi
    cmp  eax, OP_BAGI_BULAT
    je   laksana_bagi_bulat
    cmp  eax, OP_SISA
    je   laksana_sisa
    cmp  eax, OP_PANGKAT
    je   laksana_pangkat
    cmp  eax, OP_NEGATIF
    je   laksana_negatif
    cmp  eax, OP_TIDAK
    je   laksana_tidak
    cmp  eax, OP_SAMA
    je   laksana_sama
    cmp  eax, OP_TIDAK_SAMA
    je   laksana_tidak_sama
    cmp  eax, OP_KURANG_DARI
    je   laksana_kurang_dari
    cmp  eax, OP_LEBIH_DARI
    je   laksana_lebih_dari
    cmp  eax, OP_KURANG_SAMA
    je   laksana_kurang_sama
    cmp  eax, OP_LEBIH_SAMA
    je   laksana_lebih_sama
    cmp  eax, OP_DAN
    je   laksana_dan
    cmp  eax, OP_ATAU
    je   laksana_atau
    cmp  eax, OP_LONCAT
    je   laksana_loncat
    cmp  eax, OP_LONCAT_SALAH
    je   laksana_loncat_salah
    cmp  eax, OP_LONCAT_BENAR
    je   laksana_loncat_benar
    cmp  eax, OP_DUP
    je   laksana_dup
    cmp  eax, OP_POP
    je   laksana_pop
    cmp  eax, OP_PANGGIL
    je   laksana_panggil
    cmp  eax, OP_KEMBALI
    je   laksana_kembali
    cmp  eax, OP_BAKAWAN
    je   laksana_bakawan
    cmp  eax, OP_AMBIL_UNSUR
    je   laksana_ambil_unsur
    cmp  eax, OP_SIMPAN_UNSUR
    je   laksana_simpan_unsur
    cmp  eax, OP_BUAT_DAFTAR
    je   laksana_buat_daftar
    cmp  eax, OP_BUAT_KAMUS
    je   laksana_buat_kamus
    jmp  e_op_aneh

# ---------------- penghentian ----------------
laksana_henti:
    xor  eax, eax
    jmp  akhiri_vm

# ---------------- dorong konstanta/operan ----------------
laksana_dorong_k:
    call cek_ruang_tumpukan
    mov  eax, [esi]                      # konstanta 4 byte little-endian
    add  esi, 4
    mov  dword ptr [edi], TIPE_BILANGAN
    mov  [edi + 4], eax
    add  edi, 8
    jmp  ambil_opcode

laksana_dorong_t:
    call cek_ruang_tumpukan
    movzx eax, word ptr [esi]
    add  esi, 2
    mov  eax, [kolam_teks + eax*4]       # payload teks
    mov  dword ptr [edi], TIPE_TEKS
    mov  [edi + 4], eax
    add  edi, 8
    jmp  ambil_opcode

laksana_dorong_d:
    call cek_ruang_tumpukan
    movzx eax, word ptr [esi]
    add  esi, 2
    lea  edx, [kolam_desimal + eax*8]    # alamat 8-byte double
    mov  dword ptr [edi], TIPE_DESIMAL
    mov  [edi + 4], edx
    add  edi, 8
    jmp  ambil_opcode

laksana_dorong_b:
    call cek_ruang_tumpukan
    movzx eax, byte ptr [esi]
    inc  esi
    mov  dword ptr [edi], TIPE_LOGIKA
    mov  [edi + 4], eax
    add  edi, 8
    jmp  ambil_opcode

laksana_dorong_kosong:
    call cek_ruang_tumpukan
    mov  dword ptr [edi], TIPE_KOSONG
    mov  dword ptr [edi + 4], 0
    add  edi, 8
    jmp  ambil_opcode

laksana_dorong_l:
    call cek_ruang_tumpukan
    movzx eax, byte ptr [esi]
    inc  esi
    mov  edx, [ebx + eax*8]
    mov  ecx, [ebx + eax*8 + 4]
    mov  [edi], edx
    mov  [edi + 4], ecx
    add  edi, 8
    jmp  ambil_opcode

laksana_simpan_l:
    call cek_satu_tumpukan
    movzx eax, byte ptr [esi]
    inc  esi
    mov  edx, [edi - 8]
    mov  ecx, [edi - 4]
    mov  [ebx + eax*8], edx
    mov  [ebx + eax*8 + 4], ecx
    sub  edi, 8
    jmp  ambil_opcode

# ---------------- aritmetika ----------------
laksana_tambah:
    call cek_dua_tumpukan
    mov  al, [edi - 16]
    mov  cl, [edi - 8]
    cmp  al, TIPE_TEKS
    jne  tambah_cek_a_bil_des
    cmp  cl, TIPE_TEKS
    je   tambah_teks_teks
    jmp  e_tipe_tak_cocok
tambah_cek_a_bil_des:
    cmp  al, TIPE_BILANGAN
    je   tambah_a_bilangan
    cmp  al, TIPE_DESIMAL
    jne  e_tipe_tak_cocok
tambah_a_desimal:
    cmp  cl, TIPE_BILANGAN
    je   tambah_campur
    cmp  cl, TIPE_DESIMAL
    je   tambah_campur
    jmp  e_tipe_tak_cocok
tambah_a_bilangan:
    cmp  cl, TIPE_DESIMAL
    je   tambah_campur
    cmp  cl, TIPE_BILANGAN
    jne  e_tipe_tak_cocok
    # int + int
    mov  eax, [edi - 12]
    add  eax, [edi - 4]
    mov  [edi - 12], eax
    mov  dword ptr [edi - 16], TIPE_BILANGAN
    sub  edi, 8
    jmp  ambil_opcode
tambah_teks_teks:
    mov  eax, [edi - 12]
    mov  edx, [edi - 4]
    call teks_gabungkan
    mov  [edi - 12], eax
    mov  dword ptr [edi - 16], TIPE_TEKS
    sub  edi, 8
    jmp  ambil_opcode
tambah_campur:
    call hasil_desimal_dua_add
    mov  [edi - 12], eax
    mov  dword ptr [edi - 16], TIPE_DESIMAL
    sub  edi, 8
    jmp  ambil_opcode

# hasil_desimal_dua_add: st0 = a + b (a di [edi-16], b di [edi-8])
hasil_desimal_dua_add:
    push edx
    call muat_double_a
    call muat_double_b
    faddp st(1), st(0)
    call simpan_double_hasil
    pop  edx
    ret

laksana_kurang:
    call cek_dua_tumpukan
    mov  al, [edi - 16]
    mov  cl, [edi - 8]
    cmp  al, TIPE_BILANGAN
    jne  kurang_cek
    cmp  cl, TIPE_BILANGAN
    jne  kurang_cek
    # int - int
    mov  eax, [edi - 12]
    sub  eax, [edi - 4]
    mov  [edi - 12], eax
    mov  dword ptr [edi - 16], TIPE_BILANGAN
    sub  edi, 8
    jmp  ambil_opcode
kurang_cek:
    cmp  al, TIPE_DESIMAL
    je   kurang_campur
    cmp  cl, TIPE_DESIMAL
    je   kurang_campur
    cmp  al, TIPE_BILANGAN
    je   kurang_campur
    jmp  e_tipe_tak_cocok
kurang_campur:
    push edx
    call muat_double_a
    call muat_double_b
    fsubp st(1), st(0)                     # a - b
    call simpan_double_hasil
    pop  edx
    mov  [edi - 12], eax
    mov  dword ptr [edi - 16], TIPE_DESIMAL
    sub  edi, 8
    jmp  ambil_opcode

laksana_kali:
    call cek_dua_tumpukan
    mov  al, [edi - 16]
    mov  cl, [edi - 8]
    cmp  al, TIPE_BILANGAN
    jne  kali_cek
    cmp  cl, TIPE_BILANGAN
    je   kali_int
kali_cek:
    cmp  al, TIPE_DESIMAL
    je   kali_campur
    cmp  cl, TIPE_DESIMAL
    je   kali_campur
    cmp  al, TIPE_BILANGAN
    je   kali_campur
    jmp  e_tipe_tak_cocok
kali_int:
    mov  eax, [edi - 12]
    imul eax, [edi - 4]
    jo   e_meluap
    mov  [edi - 12], eax
    mov  dword ptr [edi - 16], TIPE_BILANGAN
    sub  edi, 8
    jmp  ambil_opcode
kali_campur:
    push edx
    call muat_double_a
    call muat_double_b
    fmulp st(1), st(0)
    call simpan_double_hasil
    pop  edx
    mov  [edi - 12], eax
    mov  dword ptr [edi - 16], TIPE_DESIMAL
    sub  edi, 8
    jmp  ambil_opcode

laksana_bagi:
    call cek_dua_tumpukan
    mov  al, [edi - 16]
    mov  cl, [edi - 8]
    cmp  al, TIPE_BILANGAN
    jne  bagi_cek_campur
    cmp  cl, TIPE_BILANGAN
    jne  bagi_cek_campur
    # int / int
    mov  eax, [edi - 12]
    mov  ecx, [edi - 4]
    test ecx, ecx
    jz   e_bagi_nol
    cmp  ecx, -1
    jne  bagi_idiv_aman
    cmp  eax, 0x80000000
    je   e_meluap
bagi_idiv_aman:
    xor  edx, edx
    idiv ecx
    test edx, edx
    jnz  bagi_jadi_desimal            # tidak habis -> desimal
    mov  [edi - 12], eax
    mov  dword ptr [edi - 16], TIPE_BILANGAN
    sub  edi, 8
    jmp  ambil_opcode
bagi_cek_campur:
    cmp  al, TIPE_DESIMAL
    je   bagi_desimal_murni
    cmp  cl, TIPE_DESIMAL
    je   bagi_desimal_murni
    cmp  al, TIPE_BILANGAN
    je   bagi_desimal_murni
    jmp  e_tipe_tak_cocok
bagi_jadi_desimal:
    # hasil int habis dibagi? tidak: ulangi sebagai desimal
bagi_desimal_murni:
    push edx
    call muat_double_a
    call muat_double_b
    call cek_pembagi_tak_nol
    fdivp st(1), st(0)                     # a / b
    call simpan_double_hasil
    pop  edx
    mov  [edi - 12], eax
    mov  dword ptr [edi - 16], TIPE_DESIMAL
    sub  edi, 8
    jmp  ambil_opcode

# cek_pembagi_tak_nol: pastikan st0 (pembagi) bukan nol#
# st0 TETAP di FPU setelah pemeriksaan.
cek_pembagi_tak_nol:
    ftst
    fnstsw ax
    sahf
    je   e_bagi_nol
    ret

laksana_bagi_bulat:
    call cek_dua_tumpukan
    mov  al, [edi - 16]
    mov  cl, [edi - 8]
    cmp  al, TIPE_BILANGAN
    jne  e_tipe_tak_cocok
    cmp  cl, TIPE_BILANGAN
    jne  e_tipe_tak_cocok
    mov  eax, [edi - 12]
    mov  ecx, [edi - 4]
    test ecx, ecx
    jz   e_bagi_nol
    cmp  ecx, -1
    jne  bb_aman
    cmp  eax, 0x80000000
    je   e_meluap
bb_aman:
    xor  edx, edx
    idiv ecx                           # eax = hasil (pangkas ke nol)
    test edx, edx
    jz   bb_selesai                    # habis: pangkas = lantai
    mov  edx, [edi - 12]
    xor  edx, [edi - 4]                # bit tanda beda?
    test edx, edx
    jns  bb_selesai
    dec  eax                           # arahkan ke lantai (ke bawah)
bb_selesai:
    mov  [edi - 12], eax
    mov  dword ptr [edi - 16], TIPE_BILANGAN
    sub  edi, 8
    jmp  ambil_opcode

laksana_sisa:
    call cek_dua_tumpukan
    mov  al, [edi - 16]
    mov  cl, [edi - 8]
    cmp  al, TIPE_BILANGAN
    jne  e_tipe_tak_cocok
    cmp  cl, TIPE_BILANGAN
    jne  e_tipe_tak_cocok
    mov  eax, [edi - 12]
    mov  ecx, [edi - 4]
    test ecx, ecx
    jz   e_bagi_nol
    cmp  ecx, -1
    jne  sis_aman
    cmp  eax, 0x80000000
    je   e_meluap
sis_aman:
    xor  edx, edx
    idiv ecx
    test edx, edx
    jz   sis_selesai
    mov  edx, [edi - 12]
    xor  edx, [edi - 4]
    test edx, edx
    jns  sis_selesai
    dec  eax
sis_selesai:
    # sisa = a - b * lantai(a/b)
    push eax                           # lantai
    mov  eax, ecx                      # b
    imul eax, [esp]                    # b * lantai
    mov  ecx, [edi - 12]               # a
    sub  ecx, eax
    pop  eax
    mov  [edi - 12], ecx
    mov  dword ptr [edi - 16], TIPE_BILANGAN
    sub  edi, 8
    # (catatan: edi/[esp] hati-hati, [esp] memakai stack x86)
    jmp  ambil_opcode

laksana_pangkat:
    call cek_dua_tumpukan
    mov  al, [edi - 16]
    mov  cl, [edi - 8]
    cmp  al, TIPE_BILANGAN
    jne  pangkat_cek
    cmp  cl, TIPE_BILANGAN
    jne  pangkat_cek
    # int ** int
    mov  eax, [edi - 12]               # dasar
    mov  ecx, [edi - 4]                # pangkat
    test ecx, ecx
    jns  pangkat_int_pos
    test eax, eax
    jz   e_bagi_nol                    # 0 pangkat negatif
    neg  ecx
    push dword ptr 0                   # penanda: hasil dibalik (1/x)
    jmp  pangkat_int_hitung
pangkat_int_pos:
    push dword ptr 1                   # penanda: hasil langsung
pangkat_int_hitung:
    mov  ebp, 1                        # hasil sementara
pangkat_loop:
    test ecx, ecx
    jz   pangkat_int_selesai
    imul ebp, eax
    jo   e_meluap
    dec  ecx
    jmp  pangkat_loop
pangkat_int_selesai:
    # buang penanda (hasil langsung / dibalik)
    pop  eax
    test eax, eax
    jnz  pangkat_int_tulis            # langsung
    # dibalik: hasil desimal 1/ebp
    push ebp
    fld1
    fild dword ptr [esp]
    fdivp st(1), st(0)
    pop  ebp
    call simpan_double_hasil
    mov  [edi - 12], eax
    mov  dword ptr [edi - 16], TIPE_DESIMAL
    sub  edi, 8
    jmp  ambil_opcode
pangkat_int_tulis:
    mov  [edi - 12], ebp
    mov  dword ptr [edi - 16], TIPE_BILANGAN
    sub  edi, 8
    jmp  ambil_opcode
pangkat_cek:
    cmp  al, TIPE_DESIMAL
    je   pangkat_float
    cmp  cl, TIPE_DESIMAL
    je   pangkat_float
    cmp  al, TIPE_BILANGAN
    je   pangkat_float
    jmp  e_tipe_tak_cocok
pangkat_float:
    # pangkat desimal: hasil = 2^(p*lb) memakai deret x87
    push edx
    call muat_double_a                 # st0 = dasar
    call muat_double_b                 # st0 = pangkat, st1 = dasar
    fyl2x                              # st0 = pangkat * lb2(dasar)
    fld  st(0)                           # st0 = L, st1 = L
    frndint                            # st0 = pembulatan L
    fsub st(1), st(0)                      # st1 = pecahan L
    fxch st(1)                           # st0 = pecahan, st1 = bulat
    f2xm1                              # st0 = 2^pecahan - 1
    fld1
    faddp st(1), st(0)                     # st0 = 2^pecahan
    fscale                             # st0 = 2^pecahan * 2^bulat
    fstp st(1)                           # buang bagian bulat
    call simpan_double_hasil
    pop  edx
    mov  [edi - 12], eax
    mov  dword ptr [edi - 16], TIPE_DESIMAL
    sub  edi, 8
    jmp  ambil_opcode

laksana_negatif:
    call cek_satu_tumpukan
    mov  al, [edi - 8]
    cmp  al, TIPE_BILANGAN
    je   negatif_int
    cmp  al, TIPE_DESIMAL
    je   negatif_des
    jmp  e_tipe_tak_cocok
negatif_int:
    neg  dword ptr [edi - 4]
    jmp  ambil_opcode
negatif_des:
    mov  eax, [edi - 4]
    fld  qword ptr [eax]
    fchs
    call simpan_double_hasil
    mov  [edi - 4], eax
    jmp  ambil_opcode

laksana_tidak:
    call cek_satu_tumpukan
    lea  edx, [edi - 8]
    call nilai_benar
    xor  eax, 1
    mov  byte ptr [edi - 8], TIPE_LOGIKA
    mov  [edi - 4], eax
    jmp  ambil_opcode

# ---------------- perbandingan ----------------
laksana_sama:
    call cek_dua_tumpukan
    call banding_dua
    test eax, eax
    jnz  banding_false
    jmp  banding_true
laksana_tidak_sama:
    call cek_dua_tumpukan
    call banding_dua
    test eax, eax
    jnz  banding_true
    jmp  banding_false
laksana_kurang_dari:
    call cek_dua_tumpukan
    call banding_dua
    test eax, eax
    jl   banding_true
    jmp  banding_false
laksana_lebih_dari:
    call cek_dua_tumpukan
    call banding_dua
    test eax, eax
    jg   banding_true
    jmp  banding_false
laksana_kurang_sama:
    call cek_dua_tumpukan
    call banding_dua
    test eax, eax
    jle  banding_true
    jmp  banding_false
laksana_lebih_sama:
    call cek_dua_tumpukan
    call banding_dua
    test eax, eax
    jge  banding_true
    jmp  banding_false
banding_true:
    mov  dword ptr [edi - 16], TIPE_LOGIKA
    mov  dword ptr [edi - 12], 1
    sub  edi, 8
    jmp  ambil_opcode
banding_false:
    mov  dword ptr [edi - 16], TIPE_LOGIKA
    mov  dword ptr [edi - 12], 0
    sub  edi, 8
    jmp  ambil_opcode

# banding_dua: membandingkan nilai [edi-16] dan [edi-8]
# Keluaran: eax = -1 / 0 / 1. Memakai FPU bila desimal.
banding_dua:
    mov  al, [edi - 16]
    mov  dl, [edi - 8]
    cmp  al, dl
    je   banding_sejenis
    # tipe beda: hanya int dengan desimal yang boleh
    cmp  al, TIPE_BILANGAN
    je   banding_campur
    cmp  al, TIPE_DESIMAL
    je   banding_campur
    jmp  e_tipe_tak_cocok
banding_campur:
    cmp  dl, TIPE_BILANGAN
    je   banding_desimal
    cmp  dl, TIPE_DESIMAL
    je   banding_desimal
    jmp  e_tipe_tak_cocok
banding_sejenis:
    cmp  al, TIPE_BILANGAN
    je   banding_int
    cmp  al, TIPE_DESIMAL
    je   banding_desimal
    cmp  al, TIPE_TEKS
    je   banding_teks
    cmp  al, TIPE_LOGIKA
    je   banding_int
    cmp  al, TIPE_KOSONG
    je   banding_sama_hasil
    jmp  e_tipe_tak_cocok
banding_int:
    mov  eax, [edi - 12]
    mov  ecx, [edi - 4]
    cmp  eax, ecx
    jl   banding_kurang_hasil
    jg   banding_lebih_hasil
banding_sama_hasil:
    xor  eax, eax
    ret
banding_kurang_hasil:
    mov  eax, -1
    ret
banding_lebih_hasil:
    mov  eax, 1
    ret
banding_teks:
    mov  eax, [edi - 12]
    mov  edx, [edi - 4]
    jmp  teks_bandingkan
banding_desimal:
    call muat_double_a                 # st0 = a
    call muat_double_b                 # st0 = b, st1 = a
    fcompp                             # bandingkan b dengan a, buang keduanya
    fnstsw ax
    sahf                               # ZF: sama, CF: b < a
    jb   banding_lebih_hasil           # b < a  -> a lebih besar
    je   banding_sama_hasil
    jmp  banding_kurang_hasil          # b > a  -> a lebih kecil

# ---------------- logika ----------------
laksana_dan:
    call cek_dua_tumpukan
    lea  edx, [edi - 16]
    call nilai_benar
    test eax, eax
    jz   logika_false
    lea  edx, [edi - 8]
    call nilai_benar
    test eax, eax
    jz   logika_false
    mov  dword ptr [edi - 16], TIPE_LOGIKA
    mov  dword ptr [edi - 12], 1
    sub  edi, 8
    jmp  ambil_opcode
laksana_atau:
    call cek_dua_tumpukan
    lea  edx, [edi - 16]
    call nilai_benar
    test eax, eax
    jnz  logika_true
    lea  edx, [edi - 8]
    call nilai_benar
    test eax, eax
    jnz  logika_true
    jmp  logika_false
logika_true:
    mov  dword ptr [edi - 16], TIPE_LOGIKA
    mov  dword ptr [edi - 12], 1
    sub  edi, 8
    jmp  ambil_opcode
logika_false:
    mov  dword ptr [edi - 16], TIPE_LOGIKA
    mov  dword ptr [edi - 12], 0
    sub  edi, 8
    jmp  ambil_opcode

# nilai_benar: menguji nilai 8 byte di alamat edx.
# Keluaran: eax = 1 (benar) / 0 (salah). Mengubah eax saja.
nilai_benar:
    cmp  byte ptr [edx], TIPE_LOGIKA
    je   nb_logika
    cmp  byte ptr [edx], TIPE_KOSONG
    je   nb_salah
    cmp  byte ptr [edx], TIPE_BILANGAN
    jne  nb_benar
    cmp  dword ptr [edx + 4], 0
    je   nb_salah
nb_benar:
    mov  eax, 1
    ret
nb_salah:
    xor  eax, eax
    ret
nb_logika:
    mov  eax, [edx + 4]
    test eax, eax
    jz   nb_salah
    jmp  nb_benar

# ---------------- lompatan ----------------
laksana_loncat:
    movsx eax, word ptr [esi]
    add  esi, 2
    add  esi, eax
    jmp  ambil_opcode

laksana_loncat_salah:
    call cek_satu_tumpukan
    movsx edx, word ptr [esi]
    add  esi, 2
    lea  eax, [edi - 8]
    push edx
    mov  edx, eax
    call nilai_benar
    pop  edx
    sub  edi, 8
    test eax, eax
    jnz  ambil_opcode                  # benar: lanjut
    add  esi, edx
    jmp  ambil_opcode

laksana_loncat_benar:
    call cek_satu_tumpukan
    movsx edx, word ptr [esi]
    add  esi, 2
    lea  eax, [edi - 8]
    push edx
    mov  edx, eax
    call nilai_benar
    pop  edx
    sub  edi, 8
    test eax, eax
    jz   ambil_opcode                  # salah: lanjut
    add  esi, edx
    jmp  ambil_opcode

# ---------------- tumpukan ----------------
laksana_dup:
    call cek_ruang_tumpukan
    call cek_satu_tumpukan
    mov  edx, [edi - 8]
    mov  ecx, [edi - 4]
    mov  [edi], edx
    mov  [edi + 4], ecx
    add  edi, 8
    jmp  ambil_opcode

laksana_pop:
    call cek_satu_tumpukan
    sub  edi, 8
    jmp  ambil_opcode

# ---------------- pemanggilan fungsi ----------------
laksana_panggil:
    movzx eax, byte ptr [esi]          # indeks fungsi
    inc  esi
    movzx ecx, byte ptr [esi]          # banyak argumen
    inc  esi
    cmp  eax, JUMLAH_FUNGSI
    jae  e_fungsi_tak_ada
    lea  edx, [tabel_fungsi + eax*8]
    cmp  byte ptr [edx + 6], 1
    jne  e_fungsi_belum_jadi
    cmp  byte ptr [edx + 4], cl
    jne  e_jumlah_param
    mov  eax, [edx]                    # alamat kode (offset)
    movzx edx, byte ptr [edx + 5]      # banyak lokal
    push edx                           # [esp+0] = M
    push eax                           # [esp+4] = alamat kode
    push ecx                           # [esp+8] = banyak argumen
    # dasar arg = edi - argc*8
    shl  ecx, 3
    sub  edi, ecx
    cmp  edi, offset tumpukan_nilai
    jb   e_stack_kosong
    # periksa ruang untuk M lokal
    mov  eax, [esp]
    shl  eax, 3
    lea  edx, [edi + eax]
    lea  eax, [tumpukan_nilai + UK_TUMPUKAN]
    cmp  edx, eax
    jae  e_stack_penuh
    # dorong bingkai
    mov  eax, [banyak_bingkai]
    cmp  eax, JUMLAH_BINGKAI
    jae  e_bingkai_penuh
    lea  edx, [eax + eax*2]          # indeks*3
    lea  eax, [tumpukan_bingkai + edx*4]   # (indeks*12)
    mov  [eax], esi                    # ip pemanggil
    mov  [eax + 4], ebx                # dasar lokal pemanggil
    mov  [eax + 8], edi                # puncak pemanggil (= dasar arg)
    inc  dword ptr [banyak_bingkai]
    mov  ebx, edi                      # dasar lokal baru
    # isi M slot lokal dengan kosong
    mov  ecx, [esp]                    # M
    xor  eax, eax
isi_lokal_ulang:
    cmp  eax, ecx
    jae  isi_lokal_selesai
    mov  dword ptr [ebx + eax*8], TIPE_KOSONG
    mov  dword ptr [ebx + eax*8 + 4], 0
    inc  eax
    jmp  isi_lokal_ulang
isi_lokal_selesai:
    # puncak = dasar + (argc + M) * 8
    mov  edi, ebx
    mov  eax, [esp + 8]                # argc
    add  eax, ecx                      # argc + M
    shl  eax, 3
    add  edi, eax
    # ip = alamat kode
    mov  esi, [esp + 4]
    add  esi, offset buffer_kode
    add  esp, 12
    jmp  ambil_opcode

laksana_kembali:
    # nilai hasil di [edi-8]
    lea  edx, [edi - 8]
    cmp  edx, offset tumpukan_nilai
    jb   e_stack_kosong
    mov  eax, [banyak_bingkai]
    test eax, eax
    jz   e_kembali_luar
    dec  eax
    mov  [banyak_bingkai], eax
    lea  edx, [eax + eax*2]          # indeks*3
    lea  eax, [tumpukan_bingkai + edx*4]   # (indeks*12)
    mov  esi, [eax]                    # ip pemanggil
    mov  ebx, [eax + 4]                # dasar lokal pemanggil
    mov  edi, [eax + 8]                # puncak pemanggil
    # tulis hasil di [edi]
    mov  eax, [edx]
    mov  ecx, [edx + 4]
    mov  [edi], eax
    mov  [edi + 4], ecx
    add  edi, 8
    jmp  ambil_opcode

# ---------------- fungsi baku ----------------
laksana_bakawan:
    movzx eax, byte ptr [esi]          # indeks fungsi baku
    inc  esi
    movzx ecx, byte ptr [esi]          # banyak argumen
    inc  esi
    cmp  eax, JUMLAH_BAWAAN
    jae  e_bawaan_tak_ada
    mov  ebp, ecx                      # ebp = banyak argumen (disimpan)
    mov  edx, edi
    shl  ecx, 3
    sub  edx, ecx                      # edx = alamat arg ke-0
    cmp  edx, offset tumpukan_nilai
    jb   e_stack_kosong
    mov  ecx, eax                      # ecx = indeks (dipakai tabel)
    mov  eax, ebp                      # eax = banyak argumen (konvensi)
    push ebx                           # jaga dasar lokal
    push esi                           # jaga penunjuk instruksi
    call [tabel_bawaan + ecx*4]        # konvensi: eax = argc, edx = arg[0]
    pop  esi
    pop  ebx
    lea  edi, [edx + 8]                # puncak = tempat hasil + 1
    lea  eax, [tumpukan_nilai + UK_TUMPUKAN]
    cmp  edi, eax
    jae  e_stack_penuh
    jmp  ambil_opcode

# ---------------- unsur (daftar/kamus/teks) ----------------
laksana_ambil_unsur:
    call cek_dua_tumpukan
    lea  edx, [edi - 16]               # alamat kontainer
    lea  ecx, [edi - 8]                # alamat indeks
    call unsur_ambil
    mov  [edi - 16], eax
    mov  [edi - 12], ecx
    sub  edi, 8
    jmp  ambil_opcode

laksana_simpan_unsur:
    lea  eax, [tumpukan_nilai + 24]
    cmp  edi, eax
    jb   e_stack_kosong
    lea  edx, [edi - 24]               # alamat kontainer
    lea  ecx, [edi - 16]               # alamat indeks
    lea  eax, [edi - 8]                # alamat nilai
    call unsur_simpan
    sub  edi, 24
    jmp  ambil_opcode

laksana_buat_daftar:
    movzx ecx, word ptr [esi]          # banyak nilai
    add  esi, 2
    push ecx
    shl  ecx, 3
    mov  edx, edi
    sub  edx, ecx                      # alamat nilai ke-0
    cmp  edx, offset tumpukan_nilai
    jb   e_stack_kosong
    pop  ecx
    call daftar_baru                   # eax = payload daftar
    lea  edi, [edx + 8]
    mov  byte ptr [edx], TIPE_DAFTAR
    mov  [edx + 4], eax
    jmp  ambil_opcode

laksana_buat_kamus:
    movzx ecx, word ptr [esi]          # banyak pasangan
    add  esi, 2
    push ecx
    shl  ecx, 4                        # 16 byte per pasangan
    mov  edx, edi
    sub  edx, ecx
    cmp  edx, offset tumpukan_nilai
    jb   e_stack_kosong
    pop  ecx
    call kamus_baru                    # eax = payload kamus
    lea  edi, [edx + 8]
    mov  byte ptr [edx], TIPE_KAMUS
    mov  [edx + 4], eax
    jmp  ambil_opcode

# ---------------- pembantu FPU ----------------
# muat_double_a: dorong double operan kiri ([edi-16]) ke st0
muat_double_a:
    cmp  byte ptr [edi - 16], TIPE_DESIMAL
    je   muat_a_desimal
    fild dword ptr [edi - 12]
    ret
muat_a_desimal:
    mov  eax, [edi - 12]
    fld  qword ptr [eax]
    ret

# muat_double_b: dorong double operan kanan ([edi-8]) ke st0
muat_double_b:
    cmp  byte ptr [edi - 8], TIPE_DESIMAL
    je   muat_b_desimal
    fild dword ptr [edi - 4]
    ret
muat_b_desimal:
    mov  eax, [edi - 4]
    fld  qword ptr [eax]
    ret

# simpan_double_hasil: st0 -> heap double baru.
# Keluaran: eax = alamat double. FPU menjadi kosong.
simpan_double_hasil:
    push edx
    call buat_desimal_baru
    pop  edx
    fstp qword ptr [eax]
    ret

# ---------------- pemeriksaan batas ----------------
cek_ruang_tumpukan:
    lea  eax, [tumpukan_nilai + UK_TUMPUKAN]
    cmp  edi, eax
    jae  e_stack_penuh
    ret
cek_satu_tumpukan:
    lea  eax, [tumpukan_nilai + 8]
    cmp  edi, eax
    jb   e_stack_kosong
    ret
cek_dua_tumpukan:
    lea  eax, [tumpukan_nilai + 16]
    cmp  edi, eax
    jb   e_stack_kosong
    ret

# ---------------- penanganan kesalahan ----------------
e_op_aneh:
    mov  eax, offset pesan_op_aneh
    mov  ecx, [panj_p_aneh]
    jmp  vmerror
e_stack_penuh:
    mov  eax, offset pesan_tumpakan_penuh
    mov  ecx, [panj_p_tump]
    jmp  vmerror
e_stack_kosong:
    mov  eax, offset pesan_kosong
    mov  ecx, [panj_p_kosong]
    jmp  vmerror
e_tipe_tak_cocok:
    mov  eax, offset pesan_tipe
    mov  ecx, [panj_p_tipe]
    jmp  vmerror
e_bagi_nol:
    mov  eax, offset pesan_nol
    mov  ecx, [panj_p_nol]
    jmp  vmerror
e_meluap:
    mov  eax, offset pesan_meluap
    mov  ecx, [panj_p_meluap]
    jmp  vmerror
e_bingkai_penuh:
    mov  eax, offset pesan_bingkai
    mov  ecx, [panj_p_bingkai]
    jmp  vmerror
e_kembali_luar:
    mov  eax, offset pesan_kembali
    mov  ecx, [panj_p_kembali]
    jmp  vmerror
e_fungsi_tak_ada:
    mov  eax, offset pesan_fungsi_1
    mov  ecx, [panj_p_fungsi_1]
    jmp  vmerror
e_fungsi_belum_jadi:
    mov  eax, offset pesan_fungsi_2
    mov  ecx, [panj_p_fungsi_2]
    jmp  vmerror
e_jumlah_param:
    mov  eax, offset pesan_fungsi_3
    mov  ecx, [panj_p_fungsi_3]
    jmp  vmerror
e_bawaan_tak_ada:
    mov  eax, offset pesan_bawaan
    mov  ecx, [panj_p_bawaan]
    jmp  vmerror

vmerror:
    call kirim_teks_awet
    mov  eax, 1
akhiri_vm:
    mov  [ip], esi
    ret