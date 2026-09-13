# ============================================================
#  Nusa - fungsi baku (BAKAWAN) dan tabel pemanggilannya
#  ------------------------------------------------------------
#  Konvensi (dari vm.asm):
#      Masuk : edx = alamat nilai arg ke-0 (wilayah tumpukan),
#              eax = banyak argumen
#      Keluar: hasil 8 byte ditulis ke [edx] oleh fungsi baku
#      Wajib : tidak mengubah ebx, esi, edi, edx
#      Boleh : mengubah eax, ecx (dan tumpukan x86)
#
#  Pola umum tiap fungsi:
#      push ebx; push esi; push edi; push edx; push eax (argc)
#      mov  esi, edx          # alamat hasil
#      ... bekerja dengan ebx/edi/edx bebas ...
#      menulis hasil ke [esi] dan [esi+4]
#      pop  eax; pop edx; pop edi; pop esi; pop ebx; ret
# ============================================================

.intel_syntax noprefix

.extern kirim_keluar
.extern kirim_ganti_baris
.extern baca_baris
.extern ubah_bilangan_ke_teks
.extern ubah_desimal_ke_teks
.extern ubah_teks_ke_bilangan
.extern ubah_teks_ke_desimal
.extern salin_teks_ke_baru
.extern buat_teks_baru
.extern buat_desimal_baru
.extern teks_gabungkan
.extern teks_cari
.extern unsur_simpan
.extern daftar_baru
.extern kamus_baru
.extern ada_berkas
.extern baca_isi_berkas
.extern tulis_isi_berkas
.extern hapus_isi_berkas

.section .data
# --- tabel fungsi baku (dipanggil vm.asm) ---
.globl tabel_bawaan
tabel_bawaan:
    .long bak_tulis
    .long bak_tulis_tanpa_baris
    .long bak_baca
    .long bak_ubah_teks
    .long bak_ubah_bilangan
    .long bak_ubah_desimal
    .long bak_panjang
    .long bak_gabung
    .long bak_potong
    .long bak_cari_teks
    .long bak_huruf
    .long bak_ada_berkas
    .long bak_baca_berkas
    .long bak_tulis_berkas
    .long bak_hapus_berkas
    .long bak_daftar
    .long bak_kamus
    .long bak_dorong
    .long bak_benarkah
    .long bak_bulat
    .long bak_desimal
    .long bak_bilangan
    .long bak_mutlak
    .long bak_acak
    .long bak_ganti_baris
    .long bak_jenis
    .skip 230 * 4              # sisanya nol (JUMLAH_BAWAAN = 26)

# --- teks statis untuk cetak_nilai dan ubah_teks ---
teks_benar:  .ascii "benar"
teks_salah:  .ascii "salah"
teks_kosong: .ascii "kosong"
teks_daftar: .ascii "daftar"
teks_kamus:  .ascii "kamus"

# --- nama tipe untuk bak_jenis ---
nama_bilangan: .ascii "bilangan"
nama_desimal:  .ascii "desimal"
nama_teks:     .ascii "teks"
nama_logika:   .ascii "logika"
nama_kosong:   .ascii "kosong"
nama_daftar:   .ascii "daftar"
nama_kamus:    .ascii "kamus"
nama_fungsi:   .ascii "fungsi"
nama_lain:     .ascii "lainnya"

# --- cadangan fungsi baku ---
benih_acak:    .long 0x9E3779B9
bw_cw:         .space 2
bw_cw_baru:    .space 2
bw_bulat:      .space 4
ganti_teks_tanya: .ascii "?"

.section .bss
vol_indeks:    .space 8         # nilai indeks sementara untuk unsur_simpan

.section .text

# ============================================================
#  cetak_nilai  (bagian dalam, tidak diekspor)
#  Mencetak nilai 8 byte ke layar tanpa baris baru.
#  Masukan: edx = alamat nilai.
#  Mengubah: eax, ecx, edx. Awet: ebx, esi, edi.
# ============================================================
cetak_nilai:
    push edx
    mov  al, [edx]
    cmp  al, TIPE_TEKS
    je   cn_teks
    cmp  al, TIPE_BILANGAN
    je   cn_bilangan
    cmp  al, TIPE_DESIMAL
    je   cn_desimal
    cmp  al, TIPE_LOGIKA
    je   cn_logika
    cmp  al, TIPE_KOSONG
    je   cn_kosong
    cmp  al, TIPE_DAFTAR
    je   cn_daftar
    cmp  al, TIPE_KAMUS
    je   cn_kamus
    jmp  cn_lain
cn_teks:
    mov  eax, [edx + 4]
    mov  ecx, [eax - 4]
    call kirim_keluar
    jmp  cn_selesai
cn_bilangan:
    mov  eax, [edx + 4]
    call ubah_bilangan_ke_teks
    call kirim_keluar
    jmp  cn_selesai
cn_desimal:
    mov  edx, [esp]
    mov  edx, [edx + 4]
    call ubah_desimal_ke_teks
    call kirim_keluar
    jmp  cn_selesai
cn_logika:
    cmp  dword ptr [edx + 4], 0
    je   cn_kata_salah
    lea  eax, [teks_benar]
    mov  ecx, 5
    call kirim_keluar
    jmp  cn_selesai
cn_kata_salah:
    lea  eax, [teks_salah]
    mov  ecx, 5
    call kirim_keluar
    jmp  cn_selesai
cn_kosong:
    lea  eax, [teks_kosong]
    mov  ecx, 6
    call kirim_keluar
    jmp  cn_selesai
cn_daftar:
    lea  eax, [teks_daftar]
    mov  ecx, 6
    call kirim_keluar
    jmp  cn_selesai
cn_kamus:
    lea  eax, [teks_kamus]
    mov  ecx, 5
    call kirim_keluar
    jmp  cn_selesai
cn_lain:
    lea  eax, [ganti_teks_tanya]
    mov  ecx, 1
    call kirim_keluar
cn_selesai:
    pop  edx
    ret

# ============================================================
#  bak_tulis
#  Mencetak nilai argumen lalu baris baru.
# ============================================================
bak_tulis:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    test eax, eax
    jz   tl_baris_saja
    mov  edx, esi
    call cetak_nilai
tl_baris_saja:
    call kirim_ganti_baris
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_tulis_tanpa_baris
#  Mencetak nilai argumen tanpa baris baru.
# ============================================================
bak_tulis_tanpa_baris:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    test eax, eax
    jz   tl_tanpa_selesai
    mov  edx, esi
    call cetak_nilai
tl_tanpa_selesai:
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_baca
#  Membaca satu baris masukan; hasilnya teks.
# ============================================================
bak_baca:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    call baca_baris
    cmp  ecx, -1
    je   bc_eof
    mov  edx, eax
    call salin_teks_ke_baru
    mov  dword ptr [esi], TIPE_TEKS
    mov  [esi + 4], eax
    jmp  bc_selesai
bc_eof:
    mov  ecx, 0
    call buat_teks_baru
    mov  dword ptr [esi], TIPE_TEKS
    mov  [esi + 4], eax
bc_selesai:
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_ubah_teks
#  Mengubah nilai apa pun menjadi teks.
# ============================================================
bak_ubah_teks:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    mov  ebx, edx
    mov  al, [ebx]
    cmp  al, TIPE_TEKS
    je   ut_teks
    cmp  al, TIPE_BILANGAN
    je   ut_bilangan
    cmp  al, TIPE_DESIMAL
    je   ut_desimal
    cmp  al, TIPE_LOGIKA
    je   ut_logika
    cmp  al, TIPE_KOSONG
    je   ut_kosong
    cmp  al, TIPE_DAFTAR
    je   ut_daftar
    cmp  al, TIPE_KAMUS
    je   ut_kamus
    jmp  ut_lain
ut_teks:
    mov  eax, [ebx + 4]
    jmp  ut_tulis
ut_bilangan:
    mov  eax, [ebx + 4]
    call ubah_bilangan_ke_teks
    mov  edx, eax
    call salin_teks_ke_baru
    jmp  ut_tulis
ut_desimal:
    mov  edx, [ebx + 4]
    call ubah_desimal_ke_teks
    mov  edx, eax
    call salin_teks_ke_baru
    jmp  ut_tulis
ut_logika:
    cmp  dword ptr [ebx + 4], 0
    je   ut_kata_salah
    lea  eax, [teks_benar]
    mov  ecx, 5
    jmp  ut_salin_stat
ut_kata_salah:
    lea  eax, [teks_salah]
    mov  ecx, 5
    jmp  ut_salin_stat
ut_kosong:
    lea  eax, [teks_kosong]
    mov  ecx, 6
    jmp  ut_salin_stat
ut_daftar:
    lea  eax, [teks_daftar]
    mov  ecx, 6
    jmp  ut_salin_stat
ut_kamus:
    lea  eax, [teks_kamus]
    mov  ecx, 5
    jmp  ut_salin_stat
ut_lain:
    lea  eax, [nama_lain]
    mov  ecx, 7
ut_salin_stat:
    mov  edx, eax
    call salin_teks_ke_baru
ut_tulis:
    mov  byte ptr [esi], TIPE_TEKS
    mov  [esi + 4], eax
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_ubah_bilangan
#  Mengubah teks menjadi bilangan bulat; gagal menjadi 0.
# ============================================================
bak_ubah_bilangan:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    cmp  byte ptr [esi], TIPE_TEKS
    jne  ub_gagal
    mov  edx, [esi + 4]
    mov  ecx, [edx - 4]
    call ubah_teks_ke_bilangan
    test ecx, ecx
    jnz  ub_gagal
    mov  dword ptr [esi], TIPE_BILANGAN
    mov  [esi + 4], eax
    jmp  ub_selesai
ub_gagal:
    mov  dword ptr [esi], TIPE_BILANGAN
    mov  dword ptr [esi + 4], 0
ub_selesai:
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_ubah_desimal
#  Mengubah teks menjadi desimal; gagal menjadi 0.0.
# ============================================================
bak_ubah_desimal:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    cmp  byte ptr [esi], TIPE_TEKS
    jne  ud_gagal
    mov  edx, [esi + 4]
    mov  ecx, [edx - 4]
    call ubah_teks_ke_desimal
    test ecx, ecx
    jnz  ud_gagal
    mov  dword ptr [esi], TIPE_DESIMAL
    mov  [esi + 4], eax
    jmp  ud_selesai
ud_gagal:
    mov  ecx, 8
    call buat_desimal_baru
    push eax
    fldz
    fstp qword ptr [esp]
    pop  eax
    mov  dword ptr [esi], TIPE_DESIMAL
    mov  [esi + 4], eax
ud_selesai:
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_panjang
#  Panjang teks, daftar, atau kamus.
# ============================================================
bak_panjang:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    mov  al, [esi]
    cmp  al, TIPE_TEKS
    je   pj_teks
    cmp  al, TIPE_DAFTAR
    je   pj_daftar
    cmp  al, TIPE_KAMUS
    je   pj_kamus
    xor  eax, eax
    jmp  pj_tulis
pj_teks:
    mov  eax, [esi + 4]
    mov  eax, [eax - 4]
    jmp  pj_tulis
pj_daftar:
    mov  eax, [esi + 4]
    mov  eax, [eax]
    jmp  pj_tulis
pj_kamus:
    mov  eax, [esi + 4]
    mov  eax, [eax]
pj_tulis:
    mov  dword ptr [esi], TIPE_BILANGAN
    mov  [esi + 4], eax
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_gabung
#  Menggabungkan dua teks menjadi teks baru.
# ============================================================
bak_gabung:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    cmp  dword ptr [esp], 2
    jl   gb_gagal
    cmp  byte ptr [esi], TIPE_TEKS
    jne  gb_gagal
    cmp  byte ptr [esi + 8], TIPE_TEKS
    jne  gb_gagal
    mov  eax, [esi + 4]
    mov  edx, [esi + 12]
    call teks_gabungkan
    mov  byte ptr [esi], TIPE_TEKS
    mov  [esi + 4], eax
    jmp  gb_selesai
gb_gagal:
    mov  dword ptr [esi], TIPE_KOSONG
    mov  dword ptr [esi + 4], 0
gb_selesai:
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_potong
#  Potong teks dari mulai sampai (eksklusif); sampai negatif
#  berarti ujung teks.
# ============================================================
bak_potong:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    mov  ebx, edx
    mov  eax, [esp]
    cmp  byte ptr [ebx], TIPE_TEKS
    jne  po_gagal
    mov  edi, [ebx + 4]
    mov  edx, [edi - 4]
    mov  ecx, 0
    cmp  eax, 2
    jl   po_mulai_siap
    cmp  byte ptr [ebx + 8], TIPE_BILANGAN
    jne  po_mulai_siap
    mov  ecx, [ebx + 12]
    test ecx, ecx
    jns  po_mulai_pakai
    xor  ecx, ecx
po_mulai_pakai:
    cmp  ecx, edx
    jb   po_mulai_siap
    mov  ecx, edx
po_mulai_siap:
    mov  ebx, edx
    cmp  eax, 3
    jl   po_sampai_pakai
    cmp  byte ptr [esi + 16], TIPE_BILANGAN
    jne  po_sampai_pakai
    mov  ebx, [esi + 20]
    test ebx, ebx
    jns  po_sampai_masuk
    mov  ebx, edx
po_sampai_masuk:
    cmp  ebx, edx
    jle  po_sampai_pakai
    mov  ebx, edx
po_sampai_pakai:
    cmp  ecx, ebx
    ja   po_gagal
    je   po_kosongan
    sub  ebx, ecx
    mov  edx, edi
    add  edx, ecx
    mov  ecx, ebx
    call salin_teks_ke_baru
    mov  byte ptr [esi], TIPE_TEKS
    mov  [esi + 4], eax
    jmp  po_selesai
po_kosongan:
    mov  ecx, 0
    call buat_teks_baru
    mov  byte ptr [esi], TIPE_TEKS
    mov  [esi + 4], eax
    jmp  po_selesai
po_gagal:
    mov  dword ptr [esi], TIPE_KOSONG
    mov  dword ptr [esi + 4], 0
po_selesai:
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_cari_teks
#  Mencari anak teks; hasilnya posisi atau -1.
# ============================================================
bak_cari_teks:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    cmp  dword ptr [esp], 2
    jl   ct_gagal
    cmp  byte ptr [esi], TIPE_TEKS
    jne  ct_gagal
    cmp  byte ptr [esi + 8], TIPE_TEKS
    jne  ct_gagal
    mov  eax, [esi + 4]
    mov  edx, [esi + 12]
    call teks_cari
    mov  dword ptr [esi], TIPE_BILANGAN
    mov  [esi + 4], eax
    jmp  ct_selesai
ct_gagal:
    mov  dword ptr [esi], TIPE_BILANGAN
    mov  dword ptr [esi + 4], -1
ct_selesai:
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_huruf
#  Mengambil satu karakter teks pada posisi tertentu.
# ============================================================
bak_huruf:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    cmp  dword ptr [esp], 2
    jl   hr_gagal
    cmp  byte ptr [esi], TIPE_TEKS
    jne  hr_gagal
    cmp  byte ptr [esi + 8], TIPE_BILANGAN
    jne  hr_gagal
    mov  ebx, [esi + 4]
    mov  ecx, [esi + 12]
    test ecx, ecx
    js   hr_gagal
    cmp  ecx, [ebx - 4]
    jae  hr_gagal
    mov  al, [ebx + ecx]
    push eax
    mov  ecx, 1
    call buat_teks_baru
    pop  ecx
    mov  [eax], cl
    mov  byte ptr [esi], TIPE_TEKS
    mov  [esi + 4], eax
    jmp  hr_selesai
hr_gagal:
    mov  dword ptr [esi], TIPE_KOSONG
    mov  dword ptr [esi + 4], 0
hr_selesai:
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_ada_berkas
#  benarkah: apakah berkas ada (hasil logika).
# ============================================================
bak_ada_berkas:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    cmp  byte ptr [esi], TIPE_TEKS
    jne  tar_gagal
    mov  edx, [esi + 4]
    call ada_berkas
    mov  byte ptr [esi], TIPE_LOGIKA
    mov  [esi + 4], eax
    jmp  tar_selesai
tar_gagal:
    mov  dword ptr [esi], TIPE_LOGIKA
    mov  dword ptr [esi + 4], 0
tar_selesai:
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_baca_berkas
#  Membaca seluruh isi berkas; hasilnya teks.
# ============================================================
bak_baca_berkas:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    cmp  byte ptr [esi], TIPE_TEKS
    jne  brk_gagal
    mov  edx, [esi + 4]
    call baca_isi_berkas
    test eax, eax
    jz   brk_gagal
    mov  byte ptr [esi], TIPE_TEKS
    mov  [esi + 4], eax
    jmp  brk_selesai
brk_gagal:
    mov  dword ptr [esi], TIPE_KOSONG
    mov  dword ptr [esi + 4], 0
brk_selesai:
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_tulis_berkas
#  Menulis teks ke berkas; hasil logika.
# ============================================================
bak_tulis_berkas:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    mov  eax, [esp]
    cmp  eax, 2
    jl   tbk_gagal
    cmp  byte ptr [esi], TIPE_TEKS
    jne  tbk_gagal
    cmp  byte ptr [esi + 8], TIPE_TEKS
    jne  tbk_gagal
    mov  edx, [esi + 4]
    mov  eax, [esi + 12]
    call tulis_isi_berkas
    mov  byte ptr [esi], TIPE_LOGIKA
    mov  [esi + 4], eax
    jmp  tbk_selesai
tbk_gagal:
    mov  dword ptr [esi], TIPE_LOGIKA
    mov  dword ptr [esi + 4], 0
tbk_selesai:
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_hapus_berkas
#  Menghapus berkas; hasil logika.
# ============================================================
bak_hapus_berkas:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    cmp  byte ptr [esi], TIPE_TEKS
    jne  hbk_gagal
    mov  edx, [esi + 4]
    call hapus_isi_berkas
    mov  byte ptr [esi], TIPE_LOGIKA
    mov  [esi + 4], eax
    jmp  hbk_selesai
hbk_gagal:
    mov  dword ptr [esi], TIPE_LOGIKA
    mov  dword ptr [esi + 4], 0
hbk_selesai:
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_daftar
#  Membuat daftar kosong.
# ============================================================
bak_daftar:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    xor  ecx, ecx
    xor  edx, edx
    call daftar_baru
    mov  byte ptr [esi], TIPE_DAFTAR
    mov  [esi + 4], eax
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_kamus
#  Membuat kamus kosong.
# ============================================================
bak_kamus:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    xor  ecx, ecx
    xor  edx, edx
    call kamus_baru
    mov  byte ptr [esi], TIPE_KAMUS
    mov  [esi + 4], eax
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_dorong
#  Menambah nilai di belakang daftar; hasil daftar.
# ============================================================
bak_dorong:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    cmp  dword ptr [esp], 2
    jl   dr_gagal
    cmp  byte ptr [esi], TIPE_DAFTAR
    jne  dr_gagal
    mov  ebx, [esi + 4]
    mov  edi, [ebx]
    mov  dword ptr [vol_indeks], TIPE_BILANGAN
    mov  [vol_indeks + 4], edi
    mov  edx, esi
    lea  ecx, [vol_indeks]
    lea  eax, [esi + 8]
    call unsur_simpan
    mov  edx, [esi]
    mov  ecx, [esi + 4]
    mov  [esi], edx
    mov  [esi + 4], ecx
    jmp  dr_selesai
dr_gagal:
    mov  dword ptr [esi], TIPE_KOSONG
    mov  dword ptr [esi + 4], 0
dr_selesai:
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_benarkah
#  Mengubah nilai menjadi logika (benar/salah).
# ============================================================
bak_benarkah:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    mov  al, [esi]
    cmp  al, TIPE_LOGIKA
    je   bk_logika
    cmp  al, TIPE_BILANGAN
    je   bk_bilangan
    cmp  al, TIPE_DESIMAL
    je   bk_desimal
    cmp  al, TIPE_KOSONG
    jne  bk_benar
    jmp  bk_salah
bk_logika:
    cmp  dword ptr [esi + 4], 0
    jne  bk_benar
    jmp  bk_salah
bk_bilangan:
    cmp  dword ptr [esi + 4], 0
    jne  bk_benar
    jmp  bk_salah
bk_desimal:
    mov  edx, [esi + 4]
    fld  qword ptr [edx]
    fldz
    fcomip st(0), st(1)
    fstp st(0)
    je   bk_salah
bk_benar:
    mov  byte ptr [esi], TIPE_LOGIKA
    mov  dword ptr [esi + 4], 1
    jmp  bk_selesai
bk_salah:
    mov  byte ptr [esi], TIPE_LOGIKA
    mov  dword ptr [esi + 4], 0
bk_selesai:
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_bulat
#  Desimal dibulatkan ke bawah menjadi bilangan.
# ============================================================
bak_bulat:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    cmp  byte ptr [esi], TIPE_DESIMAL
    jne  bt_gagal
    mov  edx, [esi + 4]
    fnstcw [bw_cw]
    mov  ax, [bw_cw]
    or   ax, 0x0C00
    mov  [bw_cw_baru], ax
    fldcw [bw_cw_baru]
    fld  qword ptr [edx]
    fistp dword ptr [bw_bulat]
    fldcw [bw_cw]
    mov  eax, [bw_bulat]
    mov  byte ptr [esi], TIPE_BILANGAN
    mov  [esi + 4], eax
    jmp  bt_selesai
bt_gagal:
    mov  dword ptr [esi], TIPE_KOSONG
    mov  dword ptr [esi + 4], 0
bt_selesai:
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_desimal
#  Bilangan diubah menjadi desimal.
# ============================================================
bak_desimal:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    cmp  byte ptr [esi], TIPE_BILANGAN
    jne  ds_gagal
    mov  eax, [esi + 4]
    push eax
    mov  ecx, 8
    call buat_desimal_baru
    fild dword ptr [esp]
    add  esp, 4
    fstp qword ptr [eax]
    mov  byte ptr [esi], TIPE_DESIMAL
    mov  [esi + 4], eax
    jmp  ds_selesai
ds_gagal:
    mov  dword ptr [esi], TIPE_KOSONG
    mov  dword ptr [esi + 4], 0
ds_selesai:
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_bilangan
#  Desimal diubah menjadi bilangan (dibulatkan ke bawah).
# ============================================================
bak_bilangan:
    jmp  bak_bulat

# ============================================================
#  bak_mutlak
#  Nilai mutlak bilangan atau desimal.
# ============================================================
bak_mutlak:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    mov  al, [esi]
    cmp  al, TIPE_BILANGAN
    je   ml_bilangan
    cmp  al, TIPE_DESIMAL
    je   ml_desimal
    jmp  ml_gagal
ml_bilangan:
    mov  eax, [esi + 4]
    test eax, eax
    jns  ml_tulis_bil
    neg  eax
ml_tulis_bil:
    mov  byte ptr [esi], TIPE_BILANGAN
    mov  [esi + 4], eax
    jmp  ml_selesai
ml_desimal:
    mov  edx, [esi + 4]
    fld  qword ptr [edx]
    fabs
    fstp qword ptr [edx]
    mov  byte ptr [esi], TIPE_DESIMAL
    mov  [esi + 4], edx
    jmp  ml_selesai
ml_gagal:
    mov  dword ptr [esi], TIPE_KOSONG
    mov  dword ptr [esi + 4], 0
ml_selesai:
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_acak
#  Bilangan acak 0..sampai-1 (benih xorshift statis).
# ============================================================
bak_acak:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    mov  eax, [benih_acak]
    mov  ebx, eax
    shl  ebx, 13
    xor  eax, ebx
    mov  ebx, eax
    shr  ebx, 17
    xor  eax, ebx
    mov  ebx, eax
    shl  ebx, 5
    xor  eax, ebx
    mov  [benih_acak], eax
    mov  ecx, [esp]
    cmp  ecx, 1
    jl   ak_tulis
    cmp  byte ptr [esi], TIPE_BILANGAN
    jne  ak_tulis
    mov  ecx, [esi + 4]
    test ecx, ecx
    jle  ak_nol
    xor  edx, edx
    div  ecx
    mov  eax, edx
    jmp  ak_tulis
ak_nol:
    xor  eax, eax
ak_tulis:
    mov  byte ptr [esi], TIPE_BILANGAN
    mov  [esi + 4], eax
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_ganti_baris
#  Teks berisi satu karakter baris baru.
# ============================================================
bak_ganti_baris:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    mov  ecx, 1
    call buat_teks_baru
    mov  byte ptr [eax], 10
    mov  byte ptr [esi], TIPE_TEKS
    mov  [esi + 4], eax
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret

# ============================================================
#  bak_jenis
#  Nama tipe nilai sebagai teks.
# ============================================================
bak_jenis:
    push ebx
    push esi
    push edi
    push edx
    push eax
    mov  esi, edx
    movzx eax, byte ptr [esi]
    cmp  al, TIPE_BILANGAN
    je   jn_bilangan
    cmp  al, TIPE_DESIMAL
    je   jn_desimal
    cmp  al, TIPE_TEKS
    je   jn_teks
    cmp  al, TIPE_LOGIKA
    je   jn_logika
    cmp  al, TIPE_KOSONG
    je   jn_kosong
    cmp  al, TIPE_DAFTAR
    je   jn_daftar
    cmp  al, TIPE_KAMUS
    je   jn_kamus
    cmp  al, TIPE_FUNGSI
    je   jn_fungsi
    lea  eax, [nama_lain]
    mov  ecx, 7
    jmp  jn_tulis
jn_bilangan:
    lea  eax, [nama_bilangan]
    mov  ecx, 8
    jmp  jn_tulis
jn_desimal:
    lea  eax, [nama_desimal]
    mov  ecx, 7
    jmp  jn_tulis
jn_teks:
    lea  eax, [nama_teks]
    mov  ecx, 4
    jmp  jn_tulis
jn_logika:
    lea  eax, [nama_logika]
    mov  ecx, 6
    jmp  jn_tulis
jn_kosong:
    lea  eax, [nama_kosong]
    mov  ecx, 6
    jmp  jn_tulis
jn_daftar:
    lea  eax, [nama_daftar]
    mov  ecx, 6
    jmp  jn_tulis
jn_kamus:
    lea  eax, [nama_kamus]
    mov  ecx, 5
    jmp  jn_tulis
jn_fungsi:
    lea  eax, [nama_fungsi]
    mov  ecx, 6
jn_tulis:
    mov  edx, eax
    call salin_teks_ke_baru      # eax = payload baru di arena
    mov  byte ptr [esi], TIPE_TEKS
    mov  [esi + 4], eax
    pop  eax
    pop  edx
    pop  edi
    pop  esi
    pop  ebx
    ret