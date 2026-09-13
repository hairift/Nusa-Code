# ============================================================
#  Nusa — berkas uji coba lexer (tidak dipakai pada build)
#  ------------------------------------------------------------
#  Mencetak isi teks sumber, menjalankan laksana_lexer, lalu
#  mencetak setiap token sebagai: baris jenis isi panjang.
#  Diakhiri dengan "selesai: <banyak token> token".
# ============================================================

.intel_syntax noprefix

.section .data
sumber:
    .ascii "var nama = \"dunia\"\n"
    .ascii "# komentar diabaikan\n"
    .ascii "fungsi tambah(a, b)\n"
    .ascii "jika 2 + 3 <= 5 maka\n"
    .ascii "   tulis(\"halo\")\n"
    .ascii "selain\n"
    .ascii "   tulis(1.5)\n"
    .ascii "akhir_jika\n"
    .ascii "x <- 7.25\n"
    .ascii "y != z dan 9 >= 8\n"
    .ascii "p === q\n"
    .ascii "nilai ** 2 // 3 % 4\n"
    .ascii "s = \"a\\nb\\\"c\"\n"
ujung_sumber:

pesan_gagal:   .ascii "kesalahan lexer pada baris "
panj_pesan_gagal: .long 31
pesan_selesai: .ascii "selesai: "
panj_pesan_selesai: .long 9
pesan_jumlah_token:   .ascii " token\n"
panj_pesan_jumlah_token: .long 7
teks_spasi:    .ascii " "
panj_teks_spasi: .long 1

.section .text
.extern siapkan_keluar
.extern kirim_teks_awet
.extern kirim_ganti_baris
.extern ubah_bilangan_ke_teks
.extern laksana_lexer
.extern lapor_dan_berhenti
.extern kesalahan_lex
.extern baris_kesalahan
.extern banyak_token
.extern tabel_token
.extern __imp__ExitProcess@4

.globl main
main:
    call siapkan_keluar
    mov  edx, offset sumber
    mov  ecx, offset ujung_sumber
    sub  ecx, offset sumber
    call laksana_lexer
    cmp  dword ptr [kesalahan_lex], 0
    je   cetak_token
    # cetak "kesalahan lexer pada baris <N>"
    mov  eax, offset pesan_gagal
    mov  ecx, [panj_pesan_gagal]
    call kirim_teks_awet
    movzx eax, word ptr [baris_kesalahan]
    call cetak_angka
    call kirim_ganti_baris
    call lapor_dan_berhenti
cetak_token:
    # cetak bukti: satu baris per token
    xor  ebx, ebx                # indeks token
loop_token:
    mov  eax, [banyak_token]
    cmp  ebx, eax
    jae  habis_token
    imul edx, ebx, 12
    lea  ebp, [tabel_token + edx]  # ebp = penunjuk token (tak disentuh cetak)
    movzx eax, word ptr [ebp + 1]  # baris
    call cetak_angka
    call cetak_spasi
    movzx eax, byte ptr [ebp]      # jenis
    call cetak_angka
    call cetak_spasi
    mov  eax, [ebp + 4]            # isi
    call cetak_angka
    call cetak_spasi
    mov  eax, [ebp + 8]            # panjang
    call cetak_angka
    call kirim_ganti_baris
    inc  ebx
    jmp  loop_token
habis_token:
    mov  eax, offset pesan_selesai
    mov  ecx, [panj_pesan_selesai]
    call kirim_teks_awet
    mov  eax, [banyak_token]
    call cetak_angka
    mov  eax, offset pesan_jumlah_token
    mov  ecx, [panj_pesan_jumlah_token]
    call kirim_teks_awet
    push 0
    call [__imp__ExitProcess@4]

# ------------------------------------------------------------
#  cetak_angka: mencetak nilai eax diikuti spasi.
#  Mengubah eax, ecx, edx# awet ebx, esi, edi, ebp.
# ------------------------------------------------------------
cetak_angka:
    push ebx
    push edi
    call ubah_bilangan_ke_teks   # eax = teks, ecx = panjang
    call kirim_teks_awet
    pop  edi
    pop  ebx
    ret

cetak_spasi:
    push eax
    push ecx
    mov  eax, offset teks_spasi
    mov  ecx, [panj_teks_spasi]
    call kirim_teks_awet
    pop  ecx
    pop  eax
    ret