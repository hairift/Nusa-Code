# ============================================================
#  Skrip build Nusa
#  ------------------------------------------------------------
#  Cara pakai:   powershell -ExecutionPolicy Bypass -File build.ps1
#  Prasyarat:    MinGW (as, ld, gcc) sudah ada di dalam PATH
#  Hasil:        nusa.exe di direktori proyek
#
#  Alur perakitan:
#    1. as  : merakit semua berkas src\*.asm menjadi satu
#             berkas objek (urutan penting: definisi.asm
#             paling awal agar konstanta siap dipakai)
#    2. gcc : menautkan objek bersama kernel32 menjadi .exe
#             (gcc hanya pembungkus ld; kode tetap 100%
#             assembly). Argumen -Wl berisi koma sehingga
#             wajib dikutip agar PowerShell menguraikannya
#             dengan benar.
# ============================================================

$ErrorActionPreference = "Stop"

# Urutan rakit penting untuk mendefinisikan equate lebih dulu dan
# menyediakan seluruh dependensi yang dirujuk mesin virtual.
$Urutan = @(
    "definisi.asm",
    "io.asm",
    "memori.asm",
    "string.asm",
    "kontainer.asm",
    "berkas.asm",
    "tabelbawaan.asm",
    "vm.asm",
    "bytecode.asm",
    "main.asm"
)
$Berkas = $Urutan | ForEach-Object { Join-Path "$PSScriptRoot\src" $_ }

# Lokasi objek sementara di direktori temp agar proyek bersih
$Obj   = Join-Path $env:TEMP "nusa.o"
$Hasil = Join-Path $PSScriptRoot "nusa.exe"

Write-Host "[1/2] Merakit assembly dengan as..."
& as --32 -o $Obj $Berkas
if ($LASTEXITCODE -ne 0) { throw "Gagal merakit dengan as" }

Write-Host "[2/2] Menautkan dengan ld (via gcc)..."
# -nostdlib                     : tanpa runtime C, murni assembly
# -Wl,-e,main                   : titik masuk adalah label main
# -Wl,--subsystem,console       : program konsol
& gcc -nostdlib "-Wl,-e,main" "-Wl,--subsystem,console" -o $Hasil $Obj -lkernel32
if ($LASTEXITCODE -ne 0) { throw "Gagal menautkan" }

Write-Host "Selesai. Hasil: $Hasil"