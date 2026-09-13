# NusaCode Language Support untuk VS Code

Extension resmi awal untuk berkas `.nusa` menyediakan:

- syntax highlighting untuk kata kunci Indonesia dan Inggris;
- komentar, pasangan tanda, indentasi, dan folding;
- snippet untuk variabel, percabangan, perulangan, dan fungsi;
- ikon berkas NusaCode;
- perintah **NusaCode: Jalankan Berkas Aktif**;
- perintah **NusaCode: Periksa Berkas Aktif**.

Extension tidak mengirim telemetri dan tidak melakukan akses jaringan.

## Persyaratan runtime

Perintah Run dan Check membutuhkan binary `nusa`. Bangun dari root repository:

```text
cargo build --release
```

Tambahkan `target/release` ke `PATH`, atau isi pengaturan
`nusacode.runtimePath` dengan jalur binary, misalnya:

```json
{
  "nusacode.runtimePath": "D:\\Project\\Nusa-Code\\target\\release\\nusa.exe"
}
```

## Pengembangan

1. Buka direktori `editors/vscode` di Visual Studio Code.
2. Tekan `F5` untuk membuka Extension Development Host.
3. Buka berkas dari `../../examples/`.
4. Jalankan perintah melalui Command Palette atau tombol Run di editor.
5. Pilih **NusaCode File Icons** melalui **Preferences: File Icon Theme**.

## Membuat paket

```text
npm install --global @vscode/vsce
vsce package
code --install-extension nusacode-language-support-0.1.0.vsix
```

Publikasi Marketplace membutuhkan publisher yang terverifikasi dan peninjauan
proses rilis. Snippet memberi autocomplete statis; completion semantik dan
navigasi simbol memerlukan language server yang ada pada roadmap.

## Lisensi

MIT. Lihat `LICENSE.txt`.
