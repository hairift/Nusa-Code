# ============================================================
#  Nusa — titik masuk program utama
#  ------------------------------------------------------------
#  Alur:
#      1. siapkan_keluar  -> dapatkan handle layar
#      2. ip = alamat program bytecode
#      3. jalankan_vm     -> eksekusi bytecode
#      4. ExitProcess     -> akhiri dengan kode hasil VM
# ============================================================

.intel_syntax noprefix

.extern __imp__ExitProcess@4
.extern siapkan_keluar
.extern jalankan_vm
.extern ip
.extern program

.section .text
.globl main
main:
    call siapkan_keluar

    mov  dword ptr [ip], offset program   # arahkan VM ke program uji
    call jalankan_vm                      # eax = kode keluar dari VM

    push eax
    call [__imp__ExitProcess@4]
