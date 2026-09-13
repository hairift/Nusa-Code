# Instalasi dan Build

## Platform

Interpreter Rust mendukung target yang didukung Rust stable, termasuk Windows,
Linux, dan macOS. Pengujian CI berjalan pada ketiga sistem tersebut.

Backend assembly eksperimental hanya mendukung Windows x86-32 dan memiliki
prosedur build terpisah.

## Prasyarat

Pasang Rust stable melalui `rustup` dan pastikan tersedia:

```bash
rustc --version
cargo --version
```

Versi minimum resmi akan dikunci sebelum 1.0. Pada rilis 0.1, gunakan stable
terbaru.

## Build pengembangan

```bash
git clone https://github.com/hairift/Nusa-Code.git
cd Nusa-Code
cargo build
cargo test
```

Jalankan contoh:

```bash
cargo run -- examples/halo.nusa
cargo run -- check examples/fungsi.nusa
```

## Build rilis

```bash
cargo build --release
```

Hasil:

- Windows: `target/release/nusa.exe`
- Linux/macOS: `target/release/nusa`

Salin binary ke direktori yang ada di `PATH` bila ingin memanggil `nusa` dari
semua terminal.

## Verifikasi kualitas

```bash
cargo fmt --all -- --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
```

## Website

Node.js 22 atau versi LTS aktif direkomendasikan.

```bash
cd website
npm install
npm run build
```

Artefak statis tersedia di `website/dist`.

## Extension VS Code

```bash
npm install --global @vscode/vsce
cd editors/vscode
vsce package
```

Lihat `../editors/vscode/README.md` untuk pengaturan jalur runtime.

## Backend assembly eksperimental

Prasyarat khusus: PowerShell dan MinGW 32-bit (`as`, `gcc`).

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1
```

Binary lama menjalankan bytecode uji statis dan bukan CLI `.nusa` utama.

## Pemecahan masalah

- **`cargo` tidak ditemukan**: pasang Rust melalui `rustup` dan buka terminal baru.
- **berkas ditolak**: CLI hanya menerima ekstensi `.nusa`.
- **extension tidak menemukan runtime**: isi `nusacode.runtimePath` atau tambahkan
  direktori binary ke `PATH`.
- **build website gagal**: hapus `website/node_modules`, jalankan `npm install`,
  lalu ulangi `npm run build`.
