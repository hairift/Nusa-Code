# Status Implementasi Referensi

Dokumen ini mencatat kemampuan yang dapat diverifikasi pada rilis `0.1.0`.
NusaCode masih pra-1.0; sintaks dan API dapat berubah.

## Implementasi utama

Implementasi referensi aktif adalah interpreter tree-walk berbasis Rust:

```text
sumber .nusa → lexer → token → parser → AST → evaluator → keluaran
```

CLI `nusa` menerima berkas `.nusa`, memeriksa sintaksis, dan menyediakan REPL.
Backend assembly x86-32 di `src/*.asm` adalah jalur riset historis dan bukan
binary utama Cargo.

## Matriks kemampuan

| Kemampuan | Status | Validasi |
|---|---|---|
| Menjalankan `.nusa` | Aktif | `cargo run -- examples/halo.nusa` |
| Pemeriksaan sintaksis | Aktif | `cargo run -- check examples/fungsi.nusa` |
| REPL | Aktif | `cargo run -- repl` |
| Kata kunci Indonesia–Inggris | Aktif | Pengujian `english_aliases_have_identical_behavior` |
| Bilangan, teks, logika, kosong | Aktif | Pengujian integrasi runtime |
| Daftar, kamus, indeks | Aktif | Pengujian `lists_maps_and_indexing_work` |
| Jika, selama, untuk | Aktif | Pengujian `control_flow_ranges_and_assignment` |
| Fungsi, closure, rekursi | Aktif | Pengujian `functions_recurse_and_return` |
| Diagnostik posisi sumber | Aktif | Pengujian lexer, parser, dan runtime |
| VS Code highlighting/snippet | Aktif | Extension deklaratif di `editors/vscode` |
| VS Code Run/Check | Aktif | Memanggil binary `nusa` melalui terminal editor |
| Modul dan import | Belum | Roadmap 0.2 |
| Package manager | Belum | Roadmap 0.3 |
| LSP, formatter, debugger | Belum | Roadmap pra-1.0 |
| Sandbox keamanan | Belum | Jangan menjalankan kode tak tepercaya |
| Standard library aplikasi | Belum | Web, desktop, mobile, dan game adalah sasaran jangka panjang |

## Kontrak runtime awal

- Bilangan bulat menggunakan `i64`; desimal menggunakan `f64`.
- Rentang `untuk` bersifat inklusif dan menerima langkah negatif.
- Langkah nol adalah kesalahan runtime.
- `dan/and` dan `atau/or` melakukan short-circuit serta mengembalikan operand.
- Fungsi menangkap lingkungan deklarasinya dan dibatasi hingga 1.000 tingkat
  panggilan.
- Daftar dan kamus saat ini memakai nilai semantik. `dorong/push` menghasilkan
  daftar baru, sehingga hasilnya perlu ditugaskan kembali.
- `baca/input` mengakses stdin proses. Belum ada sandbox atau model izin.

## Jalur assembly

`build.ps1` masih membangun program VM statis dari sebagian modul assembly untuk
Windows 32-bit. Jalur ini berguna untuk riset VM tingkat rendah, tetapi belum
mengurai berkas `.nusa`. Fitur pengguna harus dinilai dari binary Cargo, bukan
`nusa.exe` lama di root.

## Kriteria stabilitas 1.0

Versi 1.0 membutuhkan grammar yang dibekukan, sistem modul, kebijakan kompatibilitas,
model error yang stabil, audit keamanan, benchmark, distribusi binary bertanda,
dan dokumentasi standard library. Lihat `../ROADMAP.md`.
