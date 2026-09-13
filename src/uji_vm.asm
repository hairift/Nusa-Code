# ============================================================
#  Nusa — harness uji mesin virtual + fungsi baku + kontainer
#  ------------------------------------------------------------
#  Bukan bagian build resmi. Memuat bytecode statis ke
#  buffer_kode lalu menjalankan jalankan_vm. Keluaran
#  program = kode keluar (0 = semua uji dilewati tanpa
#  kesalahan VM). Hasil yang benar dapat diperiksa dari
#  cetakan tulis(...) di konsol.
# ============================================================

.intel_syntax noprefix

.extern siapkan_keluar
.extern siapkan_masuk
.extern salin_teks_ke_baru
.extern jalankan_vm
.extern buffer_kode
.extern kolam_teks
.extern ip
.extern __imp__ExitProcess@4

.section .data
# --- teks literal untuk kolam_teks (indeks 0..11) ---
k_t0:  .ascii "a"                # 0
k_t1:  .ascii "b"                # 1
k_t2:  .ascii "c"                # 2
k_t3:  .ascii "123"              # 3
k_t4:  .ascii "dunia"            # 4
k_t5:  .ascii "lorem ipsum dolor" # 5
k_t6:  .ascii "ipsum"            # 6
k_t7:  .ascii "uji_nusa.txt"     # 7
k_t8:  .ascii "Halo berkas!"     # 8
k_t9:  .ascii "-7"               # 9
k_t10: .ascii "2.5"              # 10
k_t11: .ascii "halo "            # 11

# tabel pasangan (alamat, panjang) per indeks kolam
tabel_kolam:
    .long k_t0, 1
    .long k_t1, 1
    .long k_t2, 1
    .long k_t3, 3
    .long k_t4, 5
    .long k_t5, 17
    .long k_t6, 5
    .long k_t7, 12
    .long k_t8, 12
    .long k_t9, 2
    .long k_t10, 3
    .long k_t11, 5
uk_tabel_kolam: .long 12

# --- bytecode uji ---
kode_uji:
    # daftar: d = [1, 2]
    .byte 1, 1,0,0,0            # DORONG_K 1
    .byte 1, 2,0,0,0            # DORONG_K 2
    .byte 35, 2,0               # BUAT_DAFTAR 2        -> [d]
    .byte 28                    # DUP                  -> [d,d]
    .byte 1, 0,0,0,0            # DORONG_K 0
    .byte 33                    # AMBIL_UNSUR          -> [d,1]
    .byte 32, 0, 1              # tulis(1)             -> [d,1]
    .byte 29                    # POP                  -> [d]
    .byte 28                    # DUP
    .byte 1, 1,0,0,0            # DORONG_K 1 (indeks 1 -> nilai 2)
    .byte 33                    # AMBIL_UNSUR          -> [d,2]
    .byte 32, 0, 1              # tulis(2)             -> [d,2]
    .byte 29
    .byte 28                    # DUP
    .byte 1, 2,0,0,0            # DORONG_K 2 (indeks 2 = tambah di belakang)
    .byte 1, 8,0,0,0            # DORONG_K 8 (nilai)
    .byte 34                    # SIMPAN_UNSUR         -> [d] d=[1,2,8]
    .byte 28
    .byte 1, 2,0,0,0
    .byte 33                    # AMBIL_UNSUR          -> [d,8]
    .byte 32, 0, 1              # tulis(8)
    .byte 29
    .byte 32, 6, 1              # panjang(d)           -> [3]
    .byte 32, 0, 1              # tulis(3)
    .byte 29
    # kamus: k = { "a": 10, "b": 20 }
    .byte 2, 0,0                # DORONG_T "a"
    .byte 1, 10,0,0,0
    .byte 2, 1,0                # DORONG_T "b"
    .byte 1, 20,0,0,0
    .byte 36, 2,0               # BUAT_KAMUS 2         -> [k]
    .byte 28
    .byte 2, 0,0
    .byte 33                    # AMBIL_UNSUR          -> [k,10]
    .byte 32, 0, 1              # tulis(10)
    .byte 29
    .byte 28
    .byte 2, 1,0
    .byte 33                    # AMBIL_UNSUR          -> [k,20]
    .byte 32, 0, 1              # tulis(20)
    .byte 29
    .byte 28
    .byte 2, 2,0                # DORONG_T "c"
    .byte 1, 30,0,0,0
    .byte 34                    # SIMPAN_UNSUR k["c"]=30 -> [k]
    .byte 28
    .byte 2, 2,0
    .byte 33                    # AMBIL_UNSUR          -> [k,30]
    .byte 32, 0, 1              # tulis(30)
    .byte 29
    .byte 32, 6, 1              # panjang(k) = 3
    .byte 32, 0, 1              # tulis(3)
    .byte 29
    # konversi dan fungsi baku teks
    .byte 1, 123,0,0,0
    .byte 32, 20, 1             # desimal(123) = 123.0
    .byte 32, 21, 1             # bilangan(123.0) = 123
    .byte 32, 0, 1              # tulis(123)
    .byte 29
    .byte 2, 4,0                # DORONG_T "dunia"
    .byte 32, 6, 1              # panjang = 5
    .byte 32, 0, 1              # tulis(5)
    .byte 29
    .byte 2, 5,0                # DORONG_T "lorem ipsum dolor"
    .byte 32, 6, 1              # panjang = 17
    .byte 32, 0, 1              # tulis(17)
    .byte 29
    .byte 2, 5,0
    .byte 2, 6,0                # DORONG_T "ipsum"
    .byte 32, 9, 2              # cari_teks = 6
    .byte 32, 0, 1              # tulis(6)
    .byte 29
    .byte 2, 5,0
    .byte 1, 6,0,0,0
    .byte 1, 11,0,0,0
    .byte 32, 8, 3              # potong(6,11) = "ipsum"
    .byte 32, 0, 1              # tulis("ipsum")
    .byte 29
    .byte 2, 5,0
    .byte 1, 4,0,0,0
    .byte 32, 10, 2             # huruf(4) = "m"
    .byte 32, 0, 1              # tulis("m")
    .byte 29
    .byte 1, 0x85,0xFF,0xFF,0xFF # -379
    .byte 32, 3, 1              # ubah_teks(-379) = "-379"
    .byte 32, 0, 1              # tulis("-379")
    .byte 29
    .byte 2, 3,0                # DORONG_T "123"
    .byte 32, 4, 1              # ubah_bilangan("123") = 123
    .byte 32, 0, 1              # tulis(123)
    .byte 29
    .byte 2, 9,0                # DORONG_T "-7"
    .byte 32, 4, 1              # ubah_bilangan = -7
    .byte 32, 22, 1             # mutlak(-7) = 7
    .byte 32, 0, 1              # tulis(7)
    .byte 29
    .byte 1, 5,0,0,0
    .byte 32, 25, 1             # jenis(5) = "bilangan"
    .byte 32, 0, 1              # tulis("bilangan")
    .byte 29
    .byte 1, 8,0,0,0
    .byte 32, 18, 1             # benarkah(8) = benar
    .byte 32, 3, 1              # ubah_teks = "benar"
    .byte 32, 0, 1              # tulis("benar")
    .byte 29
    .byte 2, 10,0               # DORONG_T "2.5"
    .byte 32, 5, 1              # ubah_desimal = 2.5
    .byte 32, 0, 1              # tulis("2.5")
    .byte 29
    .byte 2, 11,0               # DORONG_T "halo "
    .byte 2, 4,0                # DORONG_T "dunia"
    .byte 32, 7, 2              # gabung = "halo dunia"
    .byte 32, 0, 1              # tulis("halo dunia")
    .byte 29
    # berkas
    .byte 2, 7,0                # "uji_nusa.txt"
    .byte 2, 8,0                # "Halo berkas!"
    .byte 32, 13, 2             # tulis_berkas = benar
    .byte 32, 3, 1              # ubah_teks = "benar"
    .byte 32, 0, 1              # tulis("benar")
    .byte 29
    .byte 2, 7,0
    .byte 32, 12, 1             # baca_berkas = "Halo berkas!"
    .byte 32, 0, 1              # tulis("Halo berkas!")
    .byte 29
    .byte 2, 7,0
    .byte 32, 11, 1             # ada_berkas = benar
    .byte 32, 0, 1              # tulis("benar")
    .byte 29
    .byte 2, 7,0
    .byte 32, 14, 1             # hapus_berkas = benar
    .byte 32, 0, 1
    .byte 29
    .byte 2, 7,0
    .byte 32, 12, 1             # baca_berkas sesudah hapus = kosong
    .byte 32, 3, 1              # ubah_teks = "kosong"
    .byte 32, 0, 1              # tulis("kosong")
    .byte 29
    # acak
    .byte 1, 10,0,0,0
    .byte 32, 23, 1             # acak(10) = 0..9
    .byte 32, 0, 1
    .byte 29
    .byte 0                     # HENTI
uk_kode_uji: .long kode_uji_akhir - kode_uji

.section .data
kode_uji_akhir:

.section .text
.globl main
main:
    call siapkan_keluar
    call siapkan_masuk
    # isi kolam_teks (indeks 0..11)
    xor  ebx, ebx
kolam_loop:
    cmp  ebx, [uk_tabel_kolam]
    jae  kolam_selesai
    lea  eax, [tabel_kolam + ebx*8]
    mov  edx, [eax]
    mov  ecx, [eax + 4]
    call salin_teks_ke_baru
    mov  [kolam_teks + ebx*4], eax
    inc  ebx
    jmp  kolam_loop
kolam_selesai:
    # salin bytecode ke buffer_kode
    lea  esi, [kode_uji]
    mov  ecx, [uk_kode_uji]
    lea  edi, [buffer_kode]
    rep  movsb
    # jalankan VM (ip = alamat absolut buffer_kode)
    mov  dword ptr [ip], offset buffer_kode
    call jalankan_vm
    # keluar dengan kode yang diberikan VM
    push eax
    call [__imp__ExitProcess@4]