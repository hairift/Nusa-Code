# ============================================================
#  Nusa — operasi teks dasar
#  ------------------------------------------------------------
#  Struktur teks (payload nilai TIPE_TEKS menunjuk ke sini):
#      +0  dword   panjang (jumlah byte)
#      +4  byte[]  isi teks
#
#  Teks dianggap urutan byte (ASCII/UTF-8 diteruskan apa
#  adanya)# `panjang` menghitung byte, bukan karakter.
#
#  Konvensi: eax/ecx/edx boleh diubah, ebx/esi/edi dijaga
#  kecuali didokumentasikan berbeda.
# ============================================================

.intel_syntax noprefix

.section .text
.extern alokasikan
.extern buat_teks_baru

# ------------------------------------------------------------
#  teks_panjang
#  Mengambil panjang teks dari payload.
#  Masukan : eax = payload teks.
#  Keluaran: eax = panjang.
# ------------------------------------------------------------
.globl teks_panjang
teks_panjang:
    mov  eax, [eax - 4]          # kepala struct berada 4 byte di depan
    ret

# ------------------------------------------------------------
#  teks_salin_ke
#  Menyalin isi teks ke tujuan.
#  Masukan : eax = payload teks, edi = alamat tujuan.
#  Keluaran: edi berakhir di ujung isi yang disalin.
# ------------------------------------------------------------
.globl teks_salin_ke
teks_salin_ke:
    push esi
    mov  ecx, [eax - 4]          # panjang
    mov  esi, eax                # sumber
    rep  movsb
    pop  esi
    ret

# ------------------------------------------------------------
#  teks_bandingkan
#  Membandingkan dua teks secara leksikografis.
#  Masukan : eax = payload teks A, edx = payload teks B.
#  Keluaran: eax = -1 / 0 / 1 (A < B / A = B / A > B).
# ------------------------------------------------------------
.globl teks_bandingkan
teks_bandingkan:
    push esi
    push edi
    push ebx
    mov  esi, eax                # isi A
    mov  edi, edx                # isi B
    mov  ecx, [eax - 4]          # panjang A
    mov  ebx, [edx - 4]          # panjang B
banding_loop:
    test ecx, ecx
    jz   banding_habis_a
    test ebx, ebx
    jz   banding_a_lebih
    mov  al, [esi]
    mov  dl, [edi]
    cmp  al, dl
    jb   banding_a_kurang
    ja   banding_a_lebih
    inc  esi
    inc  edi
    dec  ecx
    dec  ebx
    jmp  banding_loop
banding_habis_a:
    test ebx, ebx
    jz   banding_sama
    jmp  banding_a_kurang
banding_a_kurang:
    mov  eax, -1
    jmp  banding_selesai
banding_a_lebih:
    mov  eax, 1
    jmp  banding_selesai
banding_sama:
    xor  eax, eax
banding_selesai:
    pop  ebx
    pop  edi
    pop  esi
    ret

# ------------------------------------------------------------
#  teks_gabungkan
#  Menggabungkan dua teks menjadi teks baru di arena.
#  Masukan : eax = payload teks A, edx = payload teks B.
#  Keluaran: eax = payload teks gabungan.
# ------------------------------------------------------------
.globl teks_gabungkan
teks_gabungkan:
    push esi
    push edi
    push ebx
    mov  ebx, eax                # simpan A
    mov  ecx, [eax - 4]
    add  ecx, [edx - 4]          # panjang A + B
    push edx
    call buat_teks_baru          # eax = payload baru
    pop  edx
    push eax                     # simpan hasil (payload)
    mov  edi, eax                # tujuan
    mov  eax, ebx                # A
    call teks_salin_ke
    mov  eax, edx                # B
    call teks_salin_ke
    pop  eax                     # hasil = payload
    pop  ebx
    pop  edi
    pop  esi
    ret

# ------------------------------------------------------------
#  teks_cari
#  Mencari anak teks di dalam teks (pencarian polos).
#  Masukan : eax = payload teks utama, edx = payload anak.
#  Keluaran: eax = indeks kemunculan pertama, atau -1.
# ------------------------------------------------------------
.globl teks_cari
teks_cari:
    push esi
    push edi
    push ebx
    mov  esi, eax                # isi utama
    mov  edi, edx                # isi anak
    mov  ecx, [eax - 4]          # panjang utama
    mov  ebx, [edx - 4]          # panjang anak
    test ebx, ebx
    jle  cari_gagal              # anak kosong -> -1
    cmp  ecx, ebx
    jl   cari_gagal              # anak lebih panjang -> -1
    # banyak posisi percobaan = panjang utama - panjang anak
    sub  ecx, ebx
    push ecx                     # [esp+4] = posisi terakhir
    push ebx                     # [esp+0] = panjang anak
    xor  edx, edx                # posisi percobaan
coba_posisi:
    lea  eax, [esi + edx]        # kandidat di teks utama
    xor  ecx, ecx                # k (0..panjang_anak-1)
banding_dalam:
    mov  bl, [eax + ecx]
    cmp  bl, [edi + ecx]
    jne  posisi_berikut
    inc  ecx
    cmp  ecx, [esp]              # semua byte cocok?
    jl   banding_dalam
    mov  eax, edx                # ketemu di posisi edx
    jmp  cari_selesai
posisi_berikut:
    inc  edx
    cmp  edx, [esp + 4]
    jle  coba_posisi
cari_gagal:
    mov  eax, -1
cari_selesai:
    add  esp, 8
    pop  ebx
    pop  edi
    pop  esi
    ret