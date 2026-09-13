# Proses Rilis

NusaCode belum memiliki rilis stabil. Semua rilis `0.x` adalah pra-rilis dan
memerlukan persetujuan manusia.

## Versi

Tag berbentuk `vMAJOR.MINOR.PATCH`, misalnya `v0.1.0`. Selama `0.y.z`, grammar,
CLI, dan API dapat berubah. Perubahan wajib dicatat di `CHANGELOG.md`.

## Persiapan

1. Pastikan CI hijau pada Windows, Linux, dan macOS.
2. Perbarui changelog, status implementasi, dan panduan migrasi.
3. Jalankan format, Clippy, pengujian, build website, serta pemeriksaan extension.
4. Tinjau dependensi, lisensi, kebijakan keamanan, dan isi artefak.
5. Pastikan versi `Cargo.toml`, extension, website, dan tag konsisten.

## Otomasi

Push tag `v*.*.*` menjalankan `.github/workflows/release.yml`. Workflow:

- menguji workspace;
- membangun binary Linux x86-64, Windows x86-64, macOS x86-64, dan macOS ARM64;
- memberi nama artefak berdasarkan versi dan target;
- menghasilkan `SHA256SUMS.txt`;
- membuat draft GitHub Release.

Workflow tidak mempublikasikan draft secara otomatis. Pemelihara harus memeriksa
catatan, checksum, dan hasil unduhan sebelum menekan **Publish release**.

## Keamanan supply chain

Artefak lokal manual tidak boleh diunggah sebagai rilis resmi. Penandatanganan,
SBOM, provenance SLSA, dan build reproducible penuh adalah target sebelum 1.0.
Dependensi GitHub Actions, Cargo, dan npm dipantau Dependabot.

## Rilis bermasalah

Jangan memindahkan tag yang telah dipublikasikan. Buat patch baru untuk perbaikan.
Untuk kerentanan kritis, koordinasikan pengungkapan menurut `../SECURITY.md`,
tandai atau tarik artefak terdampak, lalu terbitkan versi perbaikan.
