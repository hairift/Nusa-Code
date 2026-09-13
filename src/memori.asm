# ============================================================
#  Nusa — pengelola memori (arena/alokator)
#  ------------------------------------------------------------
#  Arena adalah kawasan memori statis 16 MiB yang dipakai
#  untuk semua alokasi runtime: lintas teks, desimal,
#  daftar, kamus, dan hasil operasi.
#
#  Alokator ini sederhana: selalu berjalan maju (bump),
#  tidak membebaskan memori. Arena yang penuh menghasilkan
#  kesalahan lalu program berhenti. Pemungut sampah
#  (garbage collector) direncanakan pada versi berikutnya.
# ============================================================

.intel_syntax noprefix

.section .bss
alamat_heap:   .space UK_HEAP     # kawasan alokasi
pelacak_heap:  .long 0            # offset pengalokasian berikutnya

.section .text
.extern kirim_teks_awet

# ------------------------------------------------------------
#  alokasikan
#  Mengalokasikan memori dari arena.
#  Masukan : ecx = banyak byte yang diminta.
#  Keluaran: eax = alamat awal blok (disejajarkan 8 byte).
#  Mengubah: eax, ecx, edx. Awet: ebx, esi, edi.
# ------------------------------------------------------------
.globl alokasikan
alokasikan:
    # sejajarkan permintaan ke kelipatan 8
    add  ecx, 7
    and  ecx, 0xFFFFFFF8
    mov  eax, [pelacak_heap]
    add  eax, ecx
    cmp  eax, UK_HEAP
    ja   gagal_heap_penuh
    mov  [pelacak_heap], eax
    mov  eax, offset alamat_heap
    add  eax, [pelacak_heap]
    sub  eax, ecx
    ret
gagal_heap_penuh:
    mov  eax, offset pesan_heap_penuh
    mov  ecx, 42                 # panjang pesan
    call kirim_teks_awet
    call lapor_dan_berhenti
    ret

# ------------------------------------------------------------
#  buat_teks_baru
#  Mengalokasikan struktur teks {panjang, isi}.
#  Masukan : ecx = panjang teks.
#  Keluaran: eax = payload (alamat struct teks)# isi belum diisi.
# ------------------------------------------------------------
.globl buat_teks_baru
buat_teks_baru:
    push ecx                     # simpan panjang
    add  ecx, 4                  # 4 byte kepala + isi
    call alokasikan
    pop  ecx
    mov  [eax], ecx              # tulis panjang pada kepala
    add  eax, 4                  # payload menunjuk ke awal isi
    ret

# ------------------------------------------------------------
#  salin_teks_ke_baru
#  Menyalin teks menjadi teks baru di arena.
#  Masukan : edx = alamat isi, ecx = panjang.
#  Keluaran: eax = payload teks baru.
# ------------------------------------------------------------
.globl salin_teks_ke_baru
salin_teks_ke_baru:
    push esi
    push edi
    push ecx
    call buat_teks_baru          # eax = payload baru
    pop  ecx                     # panjang
    mov  esi, edx                # sumber
    mov  edi, eax                # tujuan
    rep  movsb
    pop  edi
    pop  esi
    ret

# ------------------------------------------------------------
#  buat_desimal_baru
#  Mengalokasikan 8 byte untuk nilai desimal (double IEEE).
#  Keluaran: eax = alamat 8 byte (belum terisi).
# ------------------------------------------------------------
.globl buat_desimal_baru
buat_desimal_baru:
    mov  ecx, 8
    jmp  alokasikan

# ------------------------------------------------------------
#  pesan kesalahan dan penghentian darurat
# ------------------------------------------------------------
.section .data
pesan_heap_penuh: .ascii "kesalahan: memori (heap) sudah penuh\n"
lapor_dan_berhenti:
    # dipanggil setelah pesan kesalahan dicetak:
    # proses diakhiri dengan kode keluar 1.
    push 1
.extern __imp__ExitProcess@4
    call [__imp__ExitProcess@4]