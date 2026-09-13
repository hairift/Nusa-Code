# ============================================================
#  Nusa — kontainer: daftar dan kamus
#  ------------------------------------------------------------
#  Struktur daftar (payload nilai TIPE_DAFTAR menunjuk ke sini):
#      +0  dword   terisi (banyak nilai)
#      +4  dword   kapasitas
#      +8  byte[]  nilai-nilai (8 byte per entri)
#
#  Struktur kamus (payload nilai TIPE_KAMUS menunjuk ke sini):
#      +0  dword   terisi (banyak pasangan)
#      +4  dword   kapasitas (banyak ember, pangkat dua)
#      +8  byte[]  ember, 16 byte per pasang:
#                  kunci (8 byte nilai) + nilai (8 byte nilai);
#                  ember kosong ditandai byte kunci = TIPE_BELUM
#
#  Pencarian kamus memakai fungsi acak (hash) djb2 dan
#  pemeriksaan linear. Kunci harus bertipe teks.
#
#  Konvensi: fungsi di sini tidak mengubah ebx, esi, edi, ebp.
#  Kesalahan mencetak pesan lalu menghentikan program.
# ============================================================

.intel_syntax noprefix

.section .text
.extern alokasikan
.extern buat_teks_baru
.extern kirim_teks_awet
.extern lapor_dan_berhenti

.section .data
pesan_indeks:   .ascii "kesalahan: indeks di luar jangkauan\n"
panj_p_indeks:  .long 37
pesan_kunci:    .ascii "kesalahan: kunci kamus harus teks\n"
panj_p_kunci:   .long 34
pesan_daftar:   .ascii "kesalahan: daftar sudah penuh\n"
panj_p_daftar:  .long 30
pesan_kamus:    .ascii "kesalahan: kamus sudah penuh\n"
panj_p_kamus:   .long 29
pesan_teks_ubah:.ascii "kesalahan: teks tidak bisa diubah\n"
panj_p_teks_ubah: .long 34

.section .text

# ============================================================
#  daftar_baru
#  Masukan : ecx = banyak nilai, edx = alamat nilai ke-0.
#  Keluaran: eax = payload daftar baru.
# ============================================================
.globl daftar_baru
daftar_baru:
    push ebx
    push esi
    push edi
    push ecx                    # [esp+4] = n
    push edx                    # [esp]   = alamat nilai
    mov  eax, ecx               # n
    shl  eax, 1
    add  eax, 4                 # kapasitas = 2*n + 4
    mov  ebx, eax               # ebx = kapasitas
    lea  ecx, [eax*8 + 8]       # besar blok = 8 + kapasitas*8
    call alokasikan             # eax = payload daftar
    mov  edx, eax
    mov  esi, [esp]             # esi = alamat nilai ke-0
    mov  ecx, [esp + 4]         # ecx = n
    mov  [edx], ecx             # terisi = n
    mov  [edx + 4], ebx         # kapasitas
    lea  edi, [edx + 8]         # tujuan nilai
    mov  eax, ecx               # n
    shl  eax, 3                 # n * 8 byte
    mov  ecx, eax
    rep  movsb
    mov  eax, edx               # hasil = payload
    pop  edx
    pop  ecx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  kamus_baru
#  Masukan : ecx = banyak pasangan, edx = alamat pasangan ke-0
#            (tiap pasangan: 8 byte kunci + 8 byte nilai).
#  Keluaran: eax = payload kamus baru.
# ============================================================
.globl kamus_baru
kamus_baru:
    push ebx
    push esi
    push edi
    push ecx                    # [esp+4] = n
    push edx                    # [esp]   = alamat pasangan
    mov  ebx, 8                 # kapasitas ember (pangkat dua)
    mov  eax, ecx
    shl  eax, 1                 # 2*n
kamus_kap_loop:
    cmp  ebx, eax
    jae  kamus_kap_siap
    shl  ebx, 1
    jmp  kamus_kap_loop
kamus_kap_siap:
    lea  eax, [ebx + ebx]       # eax = 2*kapasitas
    lea  ecx, [eax*8 + 8]       # besar = 8 + kapasitas*16
    call alokasikan             # eax = payload kamus
    mov  edx, eax
mov  esi, [esp]             # esi = alamat pasangan
    mov  ecx, [esp + 4]         # ecx = n
    mov  dword ptr [edx], 0     # terisi = 0 (diisi pemasangan)
    mov  [edx + 4], ebx         # kapasitas
    lea  edi, [edx + 8]         # basis ember
    mov  eax, ebx               # banyak ember
kamus_bersih_loop:
    test eax, eax
    jz   kamus_bersih_siap
    mov  byte ptr [edi], TIPE_BELUM
    add  edi, 16
    dec  eax
    jmp  kamus_bersih_loop
kamus_bersih_siap:
    xor  ebx, ebx               # i
kamus_ins_loop:
    cmp  ebx, ecx
    jae  kamus_ins_selesai
lea  eax, [ebx + ebx]       # eax = i*2
    lea  eax, [esi + eax*8]     # alamat pasangan (i*16)
    push ecx                    # simpan n
    push edx                    # simpan kamus
    mov  ecx, edx               # kamus payload
    mov  edx, eax               # alamat pasangan
    call sisip_pasangan
    pop  edx                    # pulihkan kamus
    pop  ecx                    # pulihkan n
    inc  ebx
    jmp  kamus_ins_loop
kamus_ins_selesai:
    mov  eax, edx               # hasil = payload
    pop  edx
    pop  ecx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  sisip_pasangan
#  Masukan : edx = alamat pasangan (kunci 8 byte + nilai 8 byte),
#            ecx = payload kamus.
# ============================================================
sisip_pasangan:
    push ebx
    push esi
    push edi
    mov  ebx, [edx]             # tipe kunci
    cmp  ebx, TIPE_TEKS
    jne  sp_kunci_eror
push edx                    # [esp]   = alamat pasangan
    push ecx                    # [esp+4] = kamus
    push dword ptr [edx + 4]    # [esp+8] = payload kunci
    mov  edx, ecx               # kamus
    mov  esi, [esp]             # payload kunci (puncak tumpukan)
    call cari_slot_kamus        # eax = slot / -1
    pop  esi                    # buang payload kunci
    pop  ecx                    # ecx = kamus
    pop  edx                    # edx = alamat pasangan
    cmp  eax, -1
    je   sp_penuh
    cmp  byte ptr [eax], TIPE_BELUM
    je   sp_slot_kosong
    # ganti nilai pasangan lama
    mov  ebx, [edx + 8]
    mov  edi, [edx + 12]
    mov  [eax + 8], ebx
    mov  [eax + 12], edi
    jmp  sp_selesai
sp_slot_kosong:
    # periksa ruang
    mov  ebx, [ecx]             # terisi
    cmp  ebx, [ecx + 4]         # kapasitas
    jae  sp_penuh
    mov  ebx, [edx + 4]         # payload kunci
    mov  byte ptr [eax], TIPE_TEKS
    mov  [eax + 4], ebx
    mov  ebx, [edx + 8]
    mov  edi, [edx + 12]
    mov  [eax + 8], ebx
    mov  [eax + 12], edi
    inc  dword ptr [ecx]        # terisi bertambah
    jmp  sp_selesai
sp_penuh:
    mov  eax, offset pesan_kamus
    mov  ecx, [panj_p_kamus]
    call kirim_teks_awet
    call lapor_dan_berhenti
sp_kunci_eror:
    mov  eax, offset pesan_kunci
    mov  ecx, [panj_p_kunci]
    call kirim_teks_awet
    call lapor_dan_berhenti
sp_selesai:
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  cari_slot_kamus
#  Masukan : edx = payload kamus, esi = payload kunci teks.
#  Keluaran: eax = alamat slot:
#              byte [eax] = TIPE_BELUM  => ember kosong (siap pasang)
#              byte [eax] = TIPE_TEKS   => kunci cocok (nilai di +8)
#              eax = -1                 => kamus penuh
# ============================================================
cari_slot_kamus:
    push ebp
    push ebx
    push edi
push ecx                    # [esp+8]  = panjang kunci
    push esi                    # [esp+4]  = payload kunci
    push edx                    # [esp]    = kamus payload
    mov  ecx, [esi - 4]         # panjang kunci (dihitung ulang)
    mov  [esp + 8], ecx         # simpan panjang sejati bagi cari_banding
    mov  ebx, 5381
    mov  edi, esi
cari_hash:
    test ecx, ecx
    jz   cari_hash_siap
    movzx eax, byte ptr [edi]
    imul ebx, ebx, 33
    add  ebx, eax
    inc  edi
    dec  ecx
    jmp  cari_hash
cari_hash_siap:
    mov  edx, [esp]             # kamus payload
    mov  ebp, [edx + 4]         # countdown = kapasitas
    mov  eax, [edx + 4]
    dec  eax                    # mask (kapasitas-1)
    and  ebx, eax               # indeks awal dalam 0..kapasitas-1
cari_probe:
    lea  eax, [ebx + ebx]       # eax = indeks*2 (untuk skala 8)
    lea  ecx, [edx + eax*8 + 8] # ecx = alamat slot (kamus+8 + indeks*16)
    cmp  byte ptr [ecx], TIPE_BELUM
    je   cari_kosong            # ember kosong: siap dipasang
    cmp  byte ptr [ecx], TIPE_TEKS
    jne  cari_lanjut
    # bandingkan isi kunci
    mov  esi, [ecx + 4]         # isi kunci pada slot
    mov  edi, [esp + 4]         # isi kunci yang dicari
    mov  eax, [esp + 8]         # panjang kunci
    cmp  eax, [esi - 4]         # panjang slot sama?
    jne  cari_lanjut
cari_banding:
    test eax, eax
    jz   cari_cocok
    mov  dl, [esi]
    cmp  dl, [edi]
    jne  cari_lanjut
    inc  esi
    inc  edi
    dec  eax
    jmp  cari_banding
cari_lanjut:
    dec  ebp                    # satu ember terlewat
    jz   cari_penuh             # sudah menelusuri seluruh ember
    inc  ebx                    # indeks berikutnya
    mov  edx, [esp]             # pulihkan kamus (dl bisa rusak oleh cari_banding)
    mov  eax, [edx + 4]         # kapasitas
    cmp  ebx, eax
    jb   cari_probe
    xor  ebx, ebx               # kembali ke ember ke-0 (melingkar)
    jmp  cari_probe
cari_kosong:
    mov  eax, ecx               # alamat ember kosong
pop  edx
    pop  esi
    pop  ecx
    pop  edi
    pop  ebx
    pop  ebp
    ret
cari_cocok:
    mov  eax, ecx               # alamat ember dengan kunci cocok
pop  edx
    pop  esi
    pop  ecx
    pop  edi
    pop  ebx
    pop  ebp
    ret
cari_penuh:
    mov  eax, -1                # kamus penuh (tidak ada ember kosong)
pop  edx
    pop  esi
    pop  ecx
    pop  edi
    pop  ebx
    pop  ebp
    ret

# ============================================================
#  unsur_ambil
#  Membaca unsur kontainer.
#  Masukan : edx = alamat nilai kontainer (8 byte),
#            ecx = alamat nilai indeks/kunci (8 byte).
#  Keluaran: hasil 8 byte dipetakan ke eax (dword 0) dan
#            ecx (dword 4); byte terendah eax memuat tipe.
# ============================================================
.globl unsur_ambil
unsur_ambil:
    push ebx
    push esi
    push edi
    mov  al, [edx]              # tipe kontainer
    cmp  al, TIPE_DAFTAR
    je   ambil_daftar
    cmp  al, TIPE_KAMUS
    je   ambil_kamus
    cmp  al, TIPE_TEKS
    je   ambil_teks
    jmp  ua_indeks_eror
ambil_daftar:
    mov  ebx, [edx + 4]         # payload daftar
    mov  al, [ecx]              # tipe indeks
    cmp  al, TIPE_BILANGAN
    jne  ua_indeks_eror
    mov  eax, [ecx + 4]         # k
    test eax, eax
    js   ua_indeks_eror
    cmp  eax, [ebx]             # k >= terisi?
    jae  ua_indeks_eror
    lea  edx, [ebx + 8 + eax*8] # alamat unsur
    mov  eax, [edx]
    mov  ecx, [edx + 4]
    pop  edi
    pop  esi
    pop  ebx
    ret
ambil_kamus:
    mov  al, [ecx]              # tipe kunci
    cmp  al, TIPE_TEKS
    jne  ua_kunci_eror
    mov  esi, [ecx + 4]         # payload kunci
    mov  edx, [edx + 4]         # payload kamus
    call cari_slot_kamus        # eax = slot / -1
    cmp  eax, -1
    je   ambil_kamus_kosong
    cmp  byte ptr [eax], TIPE_BELUM
    je   ambil_kamus_kosong
    mov  edx, [eax + 8]         # dword 0 nilai
    mov  ecx, [eax + 12]        # dword 1 nilai
    mov  eax, edx
    pop  edi
    pop  esi
    pop  ebx
    ret
ambil_kamus_kosong:
    mov  eax, TIPE_KOSONG
    xor  ecx, ecx
    pop  edi
    pop  esi
    pop  ebx
    ret
ambil_teks:
    mov  ebx, [edx + 4]         # payload teks
    mov  al, [ecx]
    cmp  al, TIPE_BILANGAN
    jne  ua_indeks_eror
    mov  eax, [ecx + 4]         # k
    test eax, eax
    js   ua_indeks_eror
    cmp  eax, [ebx - 4]         # k >= panjang?
    jae  ua_indeks_eror
    mov  esi, eax               # k
    movzx eax, byte ptr [ebx + esi]
    push eax                    # simpan byte
    mov  ecx, 1
    call buat_teks_baru         # eax = payload teks 1 byte
    pop  ecx                    # byte
    mov  [eax], cl
    mov  edx, eax               # payload
    mov  eax, TIPE_TEKS         # dword 0 hasil
    mov  ecx, edx               # dword 1 hasil
    pop  edi
    pop  esi
    pop  ebx
    ret
ua_kunci_eror:
    mov  eax, offset pesan_kunci
    mov  ecx, [panj_p_kunci]
    call kirim_teks_awet
    call lapor_dan_berhenti
ua_indeks_eror:
    mov  eax, offset pesan_indeks
    mov  ecx, [panj_p_indeks]
    call kirim_teks_awet
    call lapor_dan_berhenti

# ============================================================
#  unsur_simpan
#  Menulis unsur ke kontainer.
#  Masukan : edx = alamat nilai kontainer (8 byte),
#            ecx = alamat nilai indeks/kunci (8 byte),
#            eax = alamat nilai baru (8 byte).
# ============================================================
.globl unsur_simpan
unsur_simpan:
    push ebx
    push esi
    push edi
    mov  edi, eax               # alamat nilai baru (sebelum al merusak eax)
    mov  al, [edx]
    cmp  al, TIPE_DAFTAR
    je   simpan_daftar
    cmp  al, TIPE_KAMUS
    je   simpan_kamus
    cmp  al, TIPE_TEKS
    je   us_teks_eror
    jmp  us_tipe_eror
simpan_daftar:
    mov  ebx, [edx + 4]         # payload daftar
    mov  al, [ecx]              # tipe indeks
    cmp  al, TIPE_BILANGAN
    jne  us_indeks_eror
    mov  eax, [ecx + 4]         # k
    test eax, eax
    js   us_indeks_eror
    cmp  eax, [ebx]             # k vs terisi
    jb   simpan_slot_daftar
    jne  us_indeks_eror         # k > terisi: di luar jangkauan
    # k == terisi: tambah di belakang
    mov  esi, [ebx]             # terisi
    cmp  esi, [ebx + 4]         # kapasitas
    jae  us_daftar_penuh
    mov  [ebx], esi             # (terisi tetap; esi = k)
    inc  dword ptr [ebx]        # terisi bertambah
simpan_slot_daftar:
    # slot = payload + 8 + k*8
    mov  esi, eax               # k
    lea  edx, [ebx + 8 + eax*8] # alamat slot
    mov  eax, [edi]             # salin nilai baru
    mov  ecx, [edi + 4]
    mov  [edx], eax
    mov  [edx + 4], ecx
    pop  edi
    pop  esi
    pop  ebx
    ret
simpan_kamus:
    mov  al, [ecx]              # tipe kunci
    cmp  al, TIPE_TEKS
    jne  us_kunci_eror
    mov  esi, [ecx + 4]         # payload kunci
    mov  edx, [edx + 4]         # payload kamus
    push edi
    push edx
    push esi
    mov  edx, [esp + 4]         # kamus
    call cari_slot_kamus        # eax = slot / -1
    pop  esi
    pop  edx                    # kamus
    pop  edi                    # alamat nilai baru
    cmp  eax, -1
    je   us_kamus_penuh
    cmp  byte ptr [eax], TIPE_BELUM
    je   us_kamus_baru
    # ganti nilai pasangan lama
    mov  ebx, [edi]
    mov  ecx, [edi + 4]
    mov  [eax + 8], ebx
    mov  [eax + 12], ecx
    pop  edi
    pop  esi
    pop  ebx
    ret
us_kamus_baru:
    mov  ebx, [edx]             # terisi
    cmp  ebx, [edx + 4]         # kapasitas
    jae  us_kamus_penuh
    mov  byte ptr [eax], TIPE_TEKS
    mov  [eax + 4], esi         # payload kunci ( esi already kunci payload? yes from pops? ) 
    mov  ebx, [edi]
    mov  ecx, [edi + 4]
    mov  [eax + 8], ebx
    mov  [eax + 12], ecx
    inc  dword ptr [edx]        # terisi bertambah
    pop  edi
    pop  esi
    pop  ebx
    ret
us_teks_eror:
    mov  eax, offset pesan_teks_ubah
    mov  ecx, [panj_p_teks_ubah]
    call kirim_teks_awet
    call lapor_dan_berhenti
us_indeks_eror:
    mov  eax, offset pesan_indeks
    mov  ecx, [panj_p_indeks]
    call kirim_teks_awet
    call lapor_dan_berhenti
us_kunci_eror:
    mov  eax, offset pesan_kunci
    mov  ecx, [panj_p_kunci]
    call kirim_teks_awet
    call lapor_dan_berhenti
us_tipe_eror:
    mov  eax, offset pesan_indeks
    mov  ecx, [panj_p_indeks]
    call kirim_teks_awet
    call lapor_dan_berhenti
us_daftar_penuh:
    mov  eax, offset pesan_daftar
    mov  ecx, [panj_p_daftar]
    call kirim_teks_awet
    call lapor_dan_berhenti
us_kamus_penuh:
    mov  eax, offset pesan_kamus
    mov  ecx, [panj_p_kamus]
    call kirim_teks_awet
    call lapor_dan_berhenti
