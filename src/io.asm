# ============================================================
#  Nusa — pustaka masukan/keluaran konsol
#  ------------------------------------------------------------
#  1. Keluaran: kirim byte/teks ke layar.
#  2. Masukan : baca_baris (dipakai baca() dan REPL).
#  3. Konversi: bilangan <-> teks, desimal <-> teks.
#
#  Konvensi:
#    - eax = alamat, ecx = panjang pada fungsi kirim/konversi.
#    - Kernel32 memakai stdcall (pemanggil tidak membersihkan).
#    - Fungsi di sini tidak mengubah ebx, esi, edi (kecuali
#      yang didokumentasikan).
# ============================================================

.intel_syntax noprefix

.extern __imp__GetStdHandle@4
.extern __imp__WriteFile@20
.extern __imp__ReadFile@20
.extern lapor_dan_berhenti
.extern buat_desimal_baru

.section .data
handle_keluar:     .long 0      # cache handle keluaran standar
handle_masuk:      .long 0      # cache handle masukan standar
jumlah_tertulis:   .long 0      # penampung byte yang benar tertulis
ganti_baris:       .byte 10     # karakter LF (baris baru)
buffer_baris_masuk:.space 1024  # penampung satu baris masukan
panjang_baris:     .long 0      # panjang baris yang terbaca
baca_kesalahan:    .ascii "kesalahan: gagal membaca masukan\n"
buffer_angka:      .space 32    # buffer konversi bilangan -> teks
buffer_desimal:    .space 48    # buffer konversi desimal -> teks
simpan_cw:         .space 2     # penyimpan control word FPU
simpan_cw_baru:    .space 2     # control word dengan pembulatan pangkas
bagian_bulat:      .space 4     # bagian bulat hasil fistp
pecahan_utuh:      .space 4     # pecahan * 1e6 hasil fistp
bil_1juta:         .long 1000000# konstanta 1.000.000 untuk FPU

.section .text

# ------------------------------------------------------------
#  siapkan_keluar
#  Dapatkan handle keluaran standar, simpan ke handle_keluar.
# ------------------------------------------------------------
.globl siapkan_keluar
siapkan_keluar:
    push -11                     # STD_OUTPUT_HANDLE
    call [__imp__GetStdHandle@4]
    mov  [handle_keluar], eax
    ret

# ------------------------------------------------------------
#  siapkan_masuk
#  Dapatkan handle masukan standar, simpan ke handle_masuk.
# ------------------------------------------------------------
.globl siapkan_masuk
siapkan_masuk:
    push -10                     # STD_INPUT_HANDLE
    call [__imp__GetStdHandle@4]
    mov  [handle_masuk], eax
    ret

# ------------------------------------------------------------
#  kirim_keluar
#  Menulis sejumlah byte ke layar.
#  Masukan: eax = alamat byte pertama, ecx = banyak byte.
# ------------------------------------------------------------
.globl kirim_keluar
kirim_keluar:
    test ecx, ecx
    jle  kirim_selesai
    push 0                       # lpOverlapped
    lea  edx, [jumlah_tertulis]
    push edx                     # lpNumberOfBytesWritten
    push ecx                     # nNumberOfBytesToWrite
    push eax                     # lpBuffer
    mov  eax, [handle_keluar]
    push eax                     # hFile
    call [__imp__WriteFile@20]
kirim_selesai:
    ret

# ------------------------------------------------------------
#  kirim_teks_awet
#  Menulis teks statis (panjang sudah diketahui saat rakitan).
#  Masukan: eax = alamat teks, ecx = panjang.
# ------------------------------------------------------------
.globl kirim_teks_awet
kirim_teks_awet:
    jmp kirim_keluar

# ------------------------------------------------------------
#  kirim_char
#  Menulis satu karakter (byte terendah eax).
# ------------------------------------------------------------
.globl kirim_char
kirim_char:
    push eax
    mov  eax, esp
    mov  ecx, 1
    call kirim_keluar
    pop  eax
    ret

# ------------------------------------------------------------
#  kirim_ganti_baris
#  Menulis satu karakter LF.
# ------------------------------------------------------------
.globl kirim_ganti_baris
kirim_ganti_baris:
    mov  eax, offset ganti_baris
    mov  ecx, 1
    jmp  kirim_keluar

# ------------------------------------------------------------
#  baca_baris
#  Membaca satu baris dari masukan standar hingga LF.
#  Keluaran: eax = alamat isi baris, ecx = panjang;
#            ecx = -1 bila akhir masukan (EOF/Ctrl-Z).
#  Karakter CR dibuang bila ada (menangani \r\n).
# ------------------------------------------------------------
.globl baca_baris
baca_baris:
    push esi
    push edi
    xor  esi, esi                # panjang baris
    lea  edi, [buffer_baris_masuk]
baca_satu_char:
    push 0                       # lpOverlapped
    lea  eax, [jumlah_tertulis]
    push eax                     # lpNumberOfBytesRead
    push 1                       # baca satu byte
    push edi                     # lpBuffer
    push [handle_masuk]          # hFile
    call [__imp__ReadFile@20]
    test eax, eax
    jz   gagal_baca
    cmp  dword ptr [jumlah_tertulis], 0
    je   akhir_masukan           # nol byte = akhir masukan
    mov  al, [edi]
    cmp  al, 10                  # LF = akhir baris
    je   baris_selesai
    cmp  al, 13                  # CR dibuang
    je   baca_satu_char
    inc  esi
    inc  edi
    cmp  esi, 1023
    jb   baca_satu_char
baris_selesai:
    mov  [panjang_baris], esi
    mov  eax, offset buffer_baris_masuk
    mov  ecx, esi
    pop  edi
    pop  esi
    ret
gagal_baca:
    mov  eax, offset baca_kesalahan
    mov  ecx, 42
    call kirim_teks_awet
    call lapor_dan_berhenti
    ret
akhir_masukan:
    mov  eax, offset buffer_baris_masuk
    mov  ecx, -1
    pop  edi
    pop  esi
    ret

# ------------------------------------------------------------
#  ubah_bilangan_ke_teks
#  Mengubah bilangan 32-bit bertanda menjadi teks desimal.
#  Masukan : eax = bilangan.
#  Keluaran: eax = alamat teks (buffer statis), ecx = panjang.
#  Catatan: fungsi ini tidak mengubah esi.
# ------------------------------------------------------------
.globl ubah_bilangan_ke_teks
ubah_bilangan_ke_teks:
    push ebx
    push edi
    mov  edi, offset buffer_angka + 31   # mulai dari ujung buffer
    xor  ebx, ebx                        # penanda negatif = tidak
    test eax, eax
    jns  mulai_angka
    mov  ebx, 1
    neg  eax
mulai_angka:
    cmp  eax, 0
    jne  bagilah
    dec  edi
    mov  byte ptr [edi], '0'
    jmp  pasang_tanda
bagilah:
    xor  edx, edx
    mov  ecx, 10
    div  ecx
    add  dl, '0'
    dec  edi
    mov  [edi], dl
    test eax, eax
    jne  bagilah
pasang_tanda:
    test ebx, ebx
    je   angka_selesai
    dec  edi
    mov  byte ptr [edi], '-'
angka_selesai:
    mov  ecx, offset buffer_angka + 31
    sub  ecx, edi
    mov  eax, edi
    pop  edi
    pop  ebx
    ret

# ------------------------------------------------------------
#  ubah_desimal_ke_teks
#  Mengubah desimal (double IEEE) menjadi teks desimal biasa.
#  Masukan : edx = alamat 8-byte double.
#  Keluaran: eax = alamat teks (buffer statis), ecx = panjang.
#  Ketentuan: hingga 6 angka di belakang koma; nol-nol di
#  ujung pecahan dibuang; pecahan yang terlalu kecil menjadi
#  tidak ditampilkan (mis. 1.0000007 -> "1").
#  Catatan: fungsi ini tidak mengubah esi.
# ------------------------------------------------------------
.globl ubah_desimal_ke_teks
ubah_desimal_ke_teks:
    push ebx
    push edi
    lea  edi, [buffer_desimal + 44]
    push esi

    # 1) Bagian bulat dengan pembulatan pangkas (truncate).
    fnstcw [simpan_cw]
    mov  ax, [simpan_cw]
    or   ax, 0x0C00
    mov  [simpan_cw_baru], ax
    fldcw [simpan_cw_baru]
    fld  qword ptr [edx]
    fistp dword ptr [bagian_bulat]
    fldcw [simpan_cw]

    # 2) Pecahan = nilai - bagian bulat. (untuk -123.456 hasilnya
    #    -0.456 karena pangkas menuju nol; ditangani di langkah 5)
    fld  qword ptr [edx]
    fild dword ptr [bagian_bulat]
    fsubp st(1), st(0)           # st0 = pecahan
    fabs                         # pecahan dimutlakkan (tanda di bagian bulat)

    # 3) Pecahan nol? Tulis bagian bulat saja.
    fldz
    fcomip st(0), st(1)
    jne  ada_pecahan
    fstp st(0)                   # buang pecahan nol dari FPU
    jmp  tulis_bulat
ada_pecahan:

    # 4) Pecahan * 1.000.000, ambil bulatan pangkasnya.
    fild dword ptr [bil_1juta]
    fmulp st(1), st(0)           # st0 = pecahan * 1e6
    fadd dword ptr [sepuluh_des_setengah]
    fldcw [simpan_cw_baru]
    fistp dword ptr [pecahan_utuh]
    fldcw [simpan_cw]
    mov  eax, [pecahan_utuh]
    test eax, eax
    jns  pecahan_positif
    neg  eax                     # nilai mutlak (pecahan bisa negatif)
pecahan_positif:
    test eax, eax
    je   tulis_bulat             # terlalu kecil: tanpa pecahan

    # 5) Buang nol-nol di ujung pecahan (mis. 500000 -> 5).
    mov  esi, 6                  # anggaran digit pecahan
buang_nol_belakang:
    mov  ebx, eax                # simpan nilai saat ini
    xor  edx, edx
    mov  ecx, 10
    div  ecx
    test edx, edx
    jne  pecahan_siap            # sisa bukan nol: nilai akhir = ebx
    dec  esi                     # satu digit nol dibuang
    jmp  buang_nol_belakang
pecahan_siap:
    mov  eax, ebx                # angka pecahan tanpa nol ujung
    call ubah_bilangan_ke_teks   # eax = teks, ecx = panjang
    push ecx                     # simpan panjang teks pecahan

    # 6) Tulis angka pecahan (menempati alamat tertinggi buffer,
    #    karena seluruh teks ditulis menurun dari ujung buffer).
    mov  ebx, eax
    add  ebx, ecx
    dec  ebx                     # ujung teks pecahan
tulis_pecahan_belakang:
    test ecx, ecx
    jle  selesai_pecahan
    mov  dl, [ebx]
    mov  [edi], dl
    dec  ebx
    dec  edi
    dec  ecx
    jmp  tulis_pecahan_belakang
selesai_pecahan:

    # 7) Nol di depan agar totalnya 6 digit posisi desimal.
    pop  ecx                     # panjang teks pecahan
    mov  eax, esi
    sub  eax, ecx
    test eax, eax
    jle  tanpa_nol_depan
tulis_nol_depan:
    mov  byte ptr [edi], '0'
    dec  edi
    dec  eax
    jnz  tulis_nol_depan
tanpa_nol_depan:

    # 8) Titik desimal.
    mov  byte ptr [edi], '.'
    dec  edi

tulis_bulat:
    # 9) Tulis tanda '-' bila perlu, lalu bagian bulat.
    mov  eax, [bagian_bulat]
    test eax, eax
    jns  tulis_digit_bulat
    mov  byte ptr [edi], '-'
    dec  edi
    neg  dword ptr [bagian_bulat]
tulis_digit_bulat:
    mov  eax, [bagian_bulat]
    call ubah_bilangan_ke_teks   # eax = teks int, ecx = panjang
    mov  esi, eax
    add  esi, ecx
    dec  esi                     # esi = ujung teks int
    mov  eax, ecx                # eax = banyak karakter int
salin_int_belakang:
    test eax, eax
    jle  selesai_angka
    mov  bl, [esi]
    mov  [edi], bl
    dec  esi
    dec  edi
    dec  eax
    jmp  salin_int_belakang

selesai_angka:
    mov  ecx, offset buffer_desimal + 44
    sub  ecx, edi                 # panjang = ujung - awal (edi = awal-1)
    inc  edi
    mov  eax, edi                 # teks mulai dari karakter pertama
    pop  esi
    pop  edi
    pop  ebx
    ret

# ------------------------------------------------------------
#  ubah_teks_ke_bilangan
#  Mengubah teks menjadi bilangan bulat 32-bit bertanda.
#  Masukan : edx = alamat teks, ecx = panjang.
#  Keluaran: eax = nilai, ecx = 0 sukses / 1 gagal.
# ------------------------------------------------------------
.globl ubah_teks_ke_bilangan
ubah_teks_ke_bilangan:
    push esi
    push edi
    push ebx
    mov  esi, edx
    mov  edi, ecx                # sisa karakter
    xor  eax, eax                # hasil
    xor  ebx, ebx                # penanda negatif
    xor  ecx, ecx                # banyak digit yang terbaca
    test edi, edi
    jle  gagal_parsa_bil
    mov  dl, [esi]               # satu karakter (dl, bukan bl — jaga penanda negatif)
    cmp  dl, '-'
    jne  parsa_cek_plus_bil
    mov  ebx, 1
    inc  esi
    dec  edi
    test edi, edi
    jle  gagal_parsa_bil
    jmp  parsa_inti_bil
parsa_cek_plus_bil:
    cmp  dl, '+'
    jne  parsa_inti_bil
    inc  esi
    dec  edi
parsa_inti_bil:
    test edi, edi
    jle  gagal_parsa_bil
parsa_loop_bil:
    test edi, edi
    jle  parsa_selesai_bil
    movzx edx, byte ptr [esi]    # satu karakter
    sub  edx, '0'
    cmp  edx, 9
    ja   gagal_parsa_bil         # bukan angka
    imul eax, eax, 10
    jo   gagal_parsa_bil         # meluap
    add  eax, edx
    jo   gagal_parsa_bil
    inc  esi
    dec  edi
    inc  ecx
    jmp  parsa_loop_bil
parsa_selesai_bil:
    test ecx, ecx
    jle  gagal_parsa_bil         # tidak ada satu angka pun
    test ebx, ebx
    je   parsa_ok_bil
    neg  eax
parsa_ok_bil:
    xor  ecx, ecx                # sukses
    pop  ebx
    pop  edi
    pop  esi
    ret
gagal_parsa_bil:
    mov  eax, 0
    mov  ecx, 1                  # gagal
    pop  ebx
    pop  edi
    pop  esi
    ret

# ------------------------------------------------------------
#  ubah_teks_ke_desimal
#  Mengubah teks menjadi desimal (double IEEE) di arena.
#  Masukan : edx = alamat teks, ecx = panjang.
#  Keluaran: eax = alamat double, ecx = 0 sukses / 1 gagal.
# ------------------------------------------------------------
.globl ubah_teks_ke_desimal
ubah_teks_ke_desimal:
    push esi
    push edi
    push ebx
    mov  esi, edx
    mov  edi, ecx                # sisa karakter
    call buat_desimal_baru
    mov  ebx, eax                # ebx = alamat hasil
    xor  ebp, ebp                # penanda negatif (ebp dijaga sendiri)
    # (perhatikan: ebp dipakai sebagai penanda; konvensi umum
    #  mesin ini tidak memakai ebp sebagai base pointer)
    test edi, edi
    jle  gagal_parsa_des
    mov  al, [esi]
    cmp  al, '-'
    jne  cek_plus_des
    mov  ebp, 1
    inc  esi
    dec  edi
    jmp  inti_des
cek_plus_des:
    cmp  al, '+'
    jne  inti_des
    inc  esi
    dec  edi
inti_des:
    test edi, edi
    jle  gagal_parsa_des
    fldz                         # st0 = hasil
    xor  ecx, ecx                # banyak digit pecahan
parsa_digit_des:
    test edi, edi
    jle  selesai_angka_des
    mov  al, [esi]
    cmp  al, '.'
    je   mulai_pecahan_des
    sub  al, '0'
    cmp  al, 9
    ja   gagal_parsa_des
    # hasil = hasil * 10 + digit
    fld  dword ptr sepuluh_des   # kala hasil sudah di st0
    fmulp st(1), st(0)           # st0 = hasil * 10
    movzx eax, al                # digit bersih (byte tinggi dibuang)
    push eax
    fild dword ptr [esp]         # st0 = digit
    add  esp, 4
    faddp st(1), st(0)           # st0 = hasil*10 + digit
    inc  esi
    dec  edi
    jmp  parsa_digit_des
mulai_pecahan_des:
    inc  esi                     # lewati titik
    dec  edi
parsa_pecahan_des:
    test edi, edi
    jle  selesai_angka_des
    mov  al, [esi]
    sub  al, '0'
    cmp  al, 9
    ja   gagal_parsa_des
    movzx eax, al                # digit bersih (byte tinggi dibuang)
    fld  dword ptr sepuluh_des   # hasil sudah di st0
    fmulp st(1), st(0)           # st0 = hasil * 10
    push eax
    fild dword ptr [esp]
    add  esp, 4
    faddp st(1), st(0)
    inc  ecx                     # satu digit pecahan lagi
    inc  esi
    dec  edi
    jmp  parsa_pecahan_des
selesai_angka_des:
    test ecx, ecx
    je   desimal_jadi            # tidak ada angka pecahan
    # bagi hasil dengan 10 sebanyak digit pecahan
bagi_sepuluh_des:
    fld  dword ptr sepuluh_des
    fdivp st(1), st(0)
    dec  ecx
    jnz  bagi_sepuluh_des
desimal_jadi:
    test ebp, ebp
    je   desimal_tersimpan
    fchs
desimal_tersimpan:
    fstp qword ptr [ebx]         # simpan hasil ke arena
    xor  ecx, ecx                # sukses
    mov  eax, ebx
    pop  ebx
    pop  edi
    pop  esi
    ret
gagal_parsa_des:
    fstp st(0)                   # bereskan FPU
    mov  eax, 0
    mov  ecx, 1                  # gagal
    pop  ebx
    pop  edi
    pop  esi
    ret

.section .data
sepuluh_des: .float 10.0         # konstanta 10 untuk FPU
sepuluh_des_setengah: .float 0.5 # bonus 0.5 agar pecahan membulat
.section .text