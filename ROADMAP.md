# Peta Jalan NusaCode

Peta jalan menyatakan arah teknis, bukan janji tanggal. Kemampuan aktual ada di
`docs/STATUS_IMPLEMENTASI.md`.

## Prinsip

1. Stabilitas dan keamanan lebih penting daripada jumlah fitur.
2. Fitur wajib memiliki spesifikasi, pengujian positif/negatif, dan diagnostik.
3. Bentuk Indonesia dan Inggris harus memiliki semantik yang sama.
4. Perubahan pra-1.0 harus dicatat dengan panduan migrasi.
5. Ekosistem aplikasi dibangun setelah modul, paket, dan FFI matang.

## 0.1 — Fondasi bahasa

Status: aktif.

- Interpreter Rust lintas platform dan CLI `.nusa`.
- Nilai dasar, daftar, kamus, operator, dan pengindeksan.
- Percabangan, perulangan rentang, fungsi, closure, dan rekursi.
- Alias Indonesia–Inggris dan diagnostik posisi sumber.
- REPL, suite pengujian, website, serta dukungan VS Code awal.

## 0.2 — Modul dan kualitas bahasa

- Sistem modul dan `impor/import` dengan resolusi jalur deterministik.
- Semantic analysis sebelum evaluasi: nama, return context, dan unreachable code.
- Assignment indeks dan operasi koleksi yang konsisten.
- Error dengan cuplikan sumber dan call stack.
- Formatter resmi serta corpus konformansi grammar.
- Benchmark lexer, parser, dan runtime.

Kriteria selesai: proyek multi-berkas dapat dibangun dan diuji secara portabel.

## 0.3 — Paket dan standard library

- Manifest proyek dan package manager dengan lockfile.
- Registry design, checksum, cache, mode offline, dan kebijakan supply chain.
- Standard library terpisah untuk teks, koleksi, waktu, JSON, path, dan proses.
- Model error/hasil eksplisit dan API I/O yang dapat diuji.
- Distribusi binary dengan checksum pada Windows, Linux, dan macOS.

Kriteria selesai: dependency resolution reproducible dan aman untuk proyek nyata.

## 0.4 — Tooling profesional

- Language Server Protocol: completion semantik, hover, definition, references,
  rename, diagnostics, dan document symbols.
- Debug adapter dengan breakpoint, stack, scope, dan evaluasi ekspresi.
- Test runner, coverage, documentation generator, dan profiler.
- Extension editor menggunakan LSP, bukan hanya grammar TextMate.

## 0.5 — Runtime dan interoperabilitas

- Bytecode portabel dengan verifier dan format berversi.
- Garbage collector atau model memori yang terdokumentasi.
- FFI aman dengan C ABI dan capability boundary.
- Async runtime, concurrency model, cancellation, dan structured tasks.
- Sandbox opsional untuk pembelajaran dan eksekusi kode tak tepercaya.

## 0.6–0.9 — Ekosistem aplikasi

Dikembangkan sebagai paket resmi terpisah setelah fondasi stabil:

- HTTP, routing, database, konfigurasi, dan observability untuk backend web.
- Binding UI desktop dan mobile melalui FFI/toolkit yang dipilih.
- Matematika, audio, input, dan rendering untuk eksperimen game.
- Build service, dokumentasi web berversi, installer, dan update channel.

Status paket resmi harus dibedakan dari proyek komunitas dan eksperimen.

## 1.0 — Stabil

Kriteria minimum:

- grammar, CLI, modul, package manifest, dan standard library inti stabil;
- kebijakan kompatibilitas dan deprecation diterbitkan;
- audit keamanan parser, package manager, bytecode, FFI, dan release pipeline;
- suite konformansi lintas platform dan benchmark regresi;
- binary bertanda versi dengan checksum/SBOM;
- dokumentasi pengguna, implementor, keamanan, dan migrasi lengkap;
- proses governance dan respons kerentanan telah diuji.
