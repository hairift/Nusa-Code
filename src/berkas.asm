# ============================================================
#  Nusa — operasi berkas
#  ------------------------------------------------------------
#  Membaca/menulis/menghapus berkas memakai API Windows
#  (kernel32). Hanya dipakai fungsi baku baca_berkas,
#  tulis_berkas, hapus_berkas, dan ada_berkas.
#
#  Teks Nusa tidak memakai penutup nol; nama berkas disalin
#  ke buffer statis lalu diberi penutup nol untuk API Windows.
#
#  Konvensi: masukan dengan payload teks; keluaran eax.
#  Fungsi di sini tidak mengubah ebx, esi, edi, ebp.
# ============================================================

.intel_syntax noprefix

.extern __imp__CreateFileA@28
.extern __imp__GetFileSize@8
.extern __imp__ReadFile@20
.extern __imp__WriteFile@20
.extern __imp__CloseHandle@4
.extern __imp__DeleteFileA@4
.extern __imp__GetFileAttributesA@4

.extern alokasikan
.extern buat_teks_baru
.extern salin_teks_ke_baru

.section .bss
nama_lengkap:   .space 4096     # nama berkas dengan penutup nol
banyak_baca:    .space 4        # byte yang benar terbaca
banyak_tertulis:.space 4        # byte yang benar tertulis

.section .text

# ------------------------------------------------------------
#  nolkan_nama
#  Menyalin nama teks (edx = payload) ke nama_lengkap,
#  lalu menambahkan byte nol. Mengubah eax, ecx, edx, esi, edi.
# ------------------------------------------------------------
nolkan_nama:
    mov  ecx, [edx - 4]         # panjang nama
    mov  esi, edx
    lea  edi, [nama_lengkap]
    push ecx
    rep  movsb
    mov  byte ptr [edi], 0
    pop  ecx
    ret

# ------------------------------------------------------------
#  baca_isi_berkas
#  Membaca seluruh isi berkas.
#  Masukan : edx = payload teks nama berkas.
#  Keluaran: eax = payload teks isi, atau 0 bila gagal.
# ------------------------------------------------------------
.globl baca_isi_berkas
baca_isi_berkas:
    push ebx
    push esi
    push edi
    call nolkan_nama
    # buka berkas untuk dibaca
    push 0                       # hTemplateFile
    push 0                       # dwFlagsAndAttributes
    push 3                       # OPEN_EXISTING
    push 0                       # lpSecurityAttributes
    push 1                       # dwShareMode = FILE_SHARE_READ
    push 0x80000000              # dwDesiredAccess = GENERIC_READ
    lea  eax, [nama_lengkap]
    push eax                     # lpFileName
    call [__imp__CreateFileA@28]
    cmp  eax, 0xFFFFFFFF         # INVALID_HANDLE_VALUE
    je   baca_gagal
    mov  ebx, eax                # ebx = handle
    push 0                       # lpFileSizeHigh
    push ebx
    call [__imp__GetFileSize@8]  # eax = besar berkas
    cmp  eax, 4194304            # batas aman 4 MiB
    ja   baca_tutup_gagal
    # alokasikan penampung isi
    push eax                     # [esp] = besar
    mov  ecx, eax
    call alokasikan              # eax = alamat penampung
    mov  edi, eax
    pop  ecx                     # besar
    # baca isi berkas
    push 0                       # lpOverlapped
    lea  eax, [banyak_baca]
    push eax                     # lpNumberOfBytesRead
    push ecx                     # nNumberOfBytesToRead
    push edi                     # lpBuffer
    push ebx                     # hFile
    call [__imp__ReadFile@20]
    test eax, eax
    jz   baca_tutup_gagal
    # tutup handle; simpan besar
    push ebx
    call [__imp__CloseHandle@4]
    mov  edx, edi                # isi
    mov  ecx, [banyak_baca]
    push esi
    call salin_teks_ke_baru      # eax = payload teks
    pop  esi
    pop  edi
    pop  esi
    pop  ebx
    ret
baca_tutup_gagal:
    push ebx
    call [__imp__CloseHandle@4]
baca_gagal:
    xor  eax, eax                # gagal
    pop  edi
    pop  esi
    pop  ebx
    ret

# ------------------------------------------------------------
#  tulis_isi_berkas
#  Menulis seluruh isi ke berkas (menimpa bila sudah ada).
#  Masukan : edx = payload teks nama, eax = payload teks isi.
#  Keluaran: eax = 1 sukses / 0 gagal.
# ------------------------------------------------------------
.globl tulis_isi_berkas
tulis_isi_berkas:
    push ebx
    push esi
    push edi
    push eax                     # simpan payload isi (nolkan_nama memakai esi)
    call nolkan_nama
    pop  esi                     # esi = payload isi
    push 0                       # hTemplateFile
    push 0x80                    # FILE_ATTRIBUTE_NORMAL
    push 2                       # CREATE_ALWAYS
    push 0                       # lpSecurityAttributes
    push 0                       # dwShareMode
    push 0x40000000              # GENERIC_WRITE
    lea  eax, [nama_lengkap]
    push eax
    call [__imp__CreateFileA@28]
    cmp  eax, 0xFFFFFFFF
    je   tulis_gagal
    mov  ebx, eax                # handle
    mov  ecx, [esi - 4]          # panjang isi
    push 0                       # lpOverlapped
    lea  eax, [banyak_tertulis]
    push eax                     # lpNumberOfBytesWritten
    push ecx                     # nNumberOfBytesToWrite
    push esi                     # lpBuffer
    push ebx                     # hFile
    call [__imp__WriteFile@20]
    test eax, eax
    jz   tulis_tutup
    push ebx
    call [__imp__CloseHandle@4]
    mov  eax, 1
    pop  edi
    pop  esi
    pop  ebx
    ret
tulis_tutup:
    push ebx
    call [__imp__CloseHandle@4]
tulis_gagal:
    xor  eax, eax
    pop  edi
    pop  esi
    pop  ebx
    ret

# ------------------------------------------------------------
#  hapus_isi_berkas
#  Masukan : edx = payload teks nama.
#  Keluaran: eax = 1 sukses / 0 gagal.
# ------------------------------------------------------------
.globl hapus_isi_berkas
hapus_isi_berkas:
    push ebx
    push esi
    push edi
    call nolkan_nama
    lea  eax, [nama_lengkap]
    push eax
    call [__imp__DeleteFileA@4]
    test eax, eax
    jz   hapus_gagal
    mov  eax, 1
    pop  edi
    pop  esi
    pop  ebx
    ret
hapus_gagal:
    xor  eax, eax
    pop  edi
    pop  esi
    pop  ebx
    ret

# ------------------------------------------------------------
#  ada_berkas
#  Masukan : edx = payload teks nama.
#  Keluaran: eax = 1 bila berkas ada / 0 bila tidak.
# ------------------------------------------------------------
.globl ada_berkas
ada_berkas:
    push ebx
    push esi
    push edi
    call nolkan_nama
    lea  eax, [nama_lengkap]
    push eax
    call [__imp__GetFileAttributesA@4]
    cmp  eax, 0xFFFFFFFF         # INVALID_FILE_ATTRIBUTES
    je   ada_tidak
    mov  eax, 1
    pop  edi
    pop  esi
    pop  ebx
    ret
ada_tidak:
    xor  eax, eax
    pop  edi
    pop  esi
    pop  ebx
    ret