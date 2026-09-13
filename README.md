<p align="center">
  <img src="NusaCode.jpg" alt="Maskot NusaCode" width="820">
</p>

<h1 align="center">NusaCode</h1>

<p align="center">
  Bahasa pemrograman dwibahasa dari Indonesia untuk pembelajaran, riset, dan pengembangan perangkat lunak.
</p>

<p align="center">
  <a href="https://github.com/hairift/Nusa-Code/actions/workflows/ci.yml">CI</a> ·
  <a href="docs/BAHASA.md">Referensi Bahasa</a> ·
  <a href="ROADMAP.md">Roadmap</a> ·
  <a href="CONTRIBUTING.md">Kontribusi</a> ·
  <a href="https://trakteer.id/fira73">Dukung NusaCode</a>
</p>

## Tentang NusaCode

NusaCode adalah bahasa pemrograman eksperimental dengan identitas sintaks sendiri:
penugasan memakai `<-`, perbandingan memakai `=`, dan blok ditutup dengan kata
kunci eksplisit seperti `akhir_jika`. Kata kunci Indonesia dan Inggris memiliki
perilaku yang sama sehingga bahasa ini mudah dipelajari secara lokal tanpa
menutup kolaborasi internasional.

Implementasi referensi ditulis dengan Rust dan dapat menjalankan berkas `.nusa`
pada Windows, Linux, dan macOS. Implementasi assembly x86-32 yang mengawali riset
proyek tetap dipertahankan di `src/*.asm` sebagai backend eksperimental.

NusaCode diciptakan oleh **Muhammad Arif Triyana**, mahasiswa Teknik Informatika
di **Universitas Catur Insan Cendekia**.

> Status: rilis awal `0.1.0`. Interpreter sudah dapat dipakai untuk eksperimen
> dan pembelajaran, tetapi kompatibilitas sintaks, API, keamanan sandbox, dan
> performa belum dijamin untuk beban produksi sebelum versi 1.0.

## Contoh

```nusa
fungsi faktorial(n) maka
    jika n <= 1 maka
        kembalikan 1
    akhir_jika
    kembalikan n * faktorial(n - 1)
akhir_fungsi

ubah hasil <- faktorial(6)
tulis("Hasil: " + ubah_teks(hasil))
```

Padanan Inggris dapat dipakai dalam program yang sama:

```nusa
function kuadrat(x) do
    return x * x
end_function

let nilai <- kuadrat(9)
print(nilai)
```

## Kemampuan rilis 0.1

- CLI `run`, `check`, dan REPL interaktif.
- Lexer Unicode dengan posisi baris dan kolom.
- Parser ekspresi dengan prioritas operator dan blok eksplisit.
- Bilangan bulat 64-bit, desimal 64-bit, teks Unicode, logika, dan `kosong`.
- Daftar, kamus, pengindeksan, serta indeks negatif untuk daftar dan teks.
- Percabangan, perulangan `selama`, dan rentang `untuk` inklusif.
- Fungsi, closure, rekursi, nilai kembali, dan pembatas kedalaman panggilan.
- Alias kata kunci dan fungsi baku Indonesia–Inggris.
- Diagnostik berbahasa Indonesia dengan lokasi sumber.
- Dukungan VS Code untuk highlighting, snippet, ikon, Run, dan Check.
- Situs dokumentasi React + TypeScript di `website/`.

Lihat matriks terverifikasi di [`docs/STATUS_IMPLEMENTASI.md`](docs/STATUS_IMPLEMENTASI.md).

## Memasang dan membangun

Prasyarat: [Rust stable](https://www.rust-lang.org/tools/install).

```bash
git clone https://github.com/hairift/Nusa-Code.git
cd Nusa-Code
cargo build --release
```

Binary berada di `target/release/nusa` atau `target/release/nusa.exe`.

### Menjalankan program

```bash
cargo run -- examples/halo.nusa
cargo run -- run examples/fungsi.nusa
cargo run -- check examples/kendali_alur.nusa
cargo run -- repl
```

Setelah build rilis, jalankan binary secara langsung:

```bash
./target/release/nusa examples/halo.nusa
```

## Menguji

```bash
cargo fmt --all -- --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
```

## Dukungan VS Code

Extension berada di [`editors/vscode`](editors/vscode). Dari direktori tersebut:

```bash
npm install --global @vscode/vsce
vsce package
code --install-extension nusacode-language-support-0.1.0.vsix
```

Extension menyediakan grammar TextMate, konfigurasi bahasa, snippet,
ikon `.nusa`, dan perintah **NusaCode: Jalankan Berkas Aktif** serta
**NusaCode: Periksa Berkas Aktif**. Perintah runtime membutuhkan binary `nusa`
di `PATH` atau pengaturan `nusacode.runtimePath`.

## Website

```bash
cd website
npm install
npm run dev
npm run build
```

Website dapat dipublikasikan terpisah ke repository
[`hairift/Web-App-NusaCode`](https://github.com/hairift/Web-App-NusaCode).

## Dokumentasi

- [`docs/README.md`](docs/README.md) — indeks dokumentasi.
- [`docs/BAHASA.md`](docs/BAHASA.md) — sintaks dan semantik.
- [`docs/ARSITEKTUR.md`](docs/ARSITEKTUR.md) — arsitektur implementasi.
- [`docs/INSTALASI.md`](docs/INSTALASI.md) — instalasi dan distribusi.
- [`docs/PERALATAN.md`](docs/PERALATAN.md) — CLI dan editor.
- [`ROADMAP.md`](ROADMAP.md) — arah pengembangan menuju 1.0.
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — panduan kontribusi.
- [`SECURITY.md`](SECURITY.md) — pelaporan kerentanan.

## Struktur repository

```text
NusaCode/
├── src/*.rs             Interpreter referensi Rust dan CLI
├── src/*.asm            Backend assembly eksperimental
├── tests/               Pengujian integrasi bahasa
├── examples/            Program Nusa yang dapat dijalankan
├── docs/                Referensi dan dokumentasi teknis
├── editors/vscode/      Extension Visual Studio Code
├── website/             Website React + TypeScript
└── .github/             CI, release, dan template komunitas
```

## Prinsip proyek

NusaCode mengambil pelajaran umum dari bahasa-bahasa matang tanpa menyalin
implementasi atau identitas mereka. Sasaran jangka panjang mencakup sistem modul,
package manager, language server, formatter, FFI, backend bytecode/kompilasi, dan
pustaka aplikasi. Setiap kemampuan baru harus disertai spesifikasi, pengujian,
dan status dukungan yang jujur.

## Lisensi dan dukungan

NusaCode tersedia sebagai perangkat lunak sumber terbuka di bawah
[MIT License](LICENSE). Kontribusi tunduk pada lisensi yang sama.

Pengembangan mandiri dapat didukung melalui
[Trakteer](https://trakteer.id/fira73).
