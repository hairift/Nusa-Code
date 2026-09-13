# Peralatan Pengembang

## CLI

```text
nusa run <file>     Jalankan berkas .nusa
nusa <file>         Bentuk singkat run
nusa check <file>   Lex dan parse tanpa menjalankan
nusa repl           Sesi interaktif dengan scope persisten
nusa --version      Versi interpreter
nusa --help         Bantuan
```

Binary hanya menerima ekstensi `.nusa`. Kegagalan baca, sintaksis, atau runtime
menghasilkan exit code non-nol.

## Visual Studio Code

Extension di `editors/vscode` menyediakan:

- syntax highlighting untuk bentuk Indonesia dan Inggris;
- pasangan kurung, komentar, auto-closing, dan folding berbasis blok;
- snippet untuk percabangan, perulangan, fungsi, dan program awal;
- ikon untuk berkas `.nusa`;
- perintah menjalankan dan memeriksa berkas aktif melalui terminal.

Perintah runtime mencari `nusa` di `PATH`. Jalur khusus dapat diatur melalui
`nusacode.runtimePath`.

Paket extension:

```bash
cd editors/vscode
npm install --global @vscode/vsce
vsce package
code --install-extension nusacode-language-support-0.1.0.vsix
```

## Website

Website React + TypeScript berada di `website`.

```bash
cd website
npm install
npm run dev
npm run build
```

## Tooling roadmap

Formatter, language server, semantic completion, rename symbol, debugger,
coverage, benchmark harness, dan package manager belum tersedia. Snippet VS Code
memberi completion statis; semantic autocomplete membutuhkan LSP pada tahap
berikutnya.
