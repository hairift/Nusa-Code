# Berkontribusi ke NusaCode

NusaCode adalah implementasi referensi pra-1.0. Perubahan bahasa, runtime, dan CLI
dapat terjadi, tetapi harus didokumentasikan dan diuji.

## Sebelum memulai

1. Baca `docs/STATUS_IMPLEMENTASI.md` dan `ROADMAP.md`.
2. Cari isu yang sudah ada.
3. Buka usulan lebih dahulu untuk grammar, arsitektur, dependensi, atau API baru.
4. Jangan menyertakan rahasia, data pribadi, atau binary yang tidak diperlukan.

## Lingkungan

Pasang Rust stable dengan `rustfmt` dan `clippy`.

```text
cargo fmt --all -- --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
cargo build --release
```

Untuk website:

```text
cd website
npm ci
npm run build
```

Backend assembly membutuhkan MinGW 32-bit dan dibangun dengan `build.ps1`.

## Alur kontribusi

1. Fork repository dan buat branch yang fokus.
2. Tambahkan implementasi, pengujian, dokumentasi, dan changelog terkait.
3. Jalankan pemeriksaan lokal.
4. Buka pull request dan jelaskan masalah, solusi, kompatibilitas, serta validasi.

## Standar

- Gunakan Bahasa Indonesia baku untuk diagnostik dan dokumentasi utama.
- Setiap kata kunci Indonesia baru harus mempertimbangkan alias Inggris dengan
  semantik identik.
- Jangan mengubah grammar tanpa pengujian positif, negatif, dan prioritas operator.
- Jangan mengubah perilaku publik diam-diam; catat migrasi pra-1.0.
- Gunakan arithmetic terperiksa untuk bilangan bulat.
- Hindari dependensi baru kecuali manfaat, lisensi, keamanan, dan pemeliharaannya
  dijelaskan.
- Untuk assembly, pertahankan gaya GNU `as`, konvensi register, dan dokumentasi
  opcode/ABI.
- Website wajib aksesibel, responsif, bebas tracker, dan lulus build TypeScript.
- Extension tidak boleh menambahkan telemetri tanpa keputusan governance terbuka.

## Pengujian

Program `.nusa` baru harus dapat dijalankan oleh CLI atau diberi label roadmap
yang jelas. Bug parser/runtime sebaiknya memiliki pengujian regresi minimal.
Perubahan extension harus memvalidasi JavaScript dan seluruh JSON; perubahan UI
website perlu diperiksa pada viewport desktop serta mobile.

## Lisensi

Dengan berkontribusi, Anda menyetujui kontribusi dilisensikan berdasarkan MIT
License dan mematuhi `CODE_OF_CONDUCT.md`.
