# Tata Kelola Proyek

## Model pemeliharaan

NusaCode saat ini dikelola dengan model pemelihara utama. Pemelihara menetapkan
arah bahasa, meninjau kontribusi, mengelola rilis, dan menegakkan kebijakan
komunitas serta keamanan. Model ini dapat berkembang bila jumlah kontributor
dan pengguna meningkat.

## Pengambilan keputusan

Perbaikan bug dan dokumentasi dapat diputuskan melalui pull request. Perubahan
berdampak luas harus diawali isu desain, terutama untuk:

- grammar, kata kunci, atau semantik;
- format bytecode, representasi nilai, dan ABI internal;
- kompatibilitas platform atau perubahan toolchain;
- dependensi baru dan rantai pasok rilis;
- kebijakan privasi, telemetri, atau keamanan.

Usulan harus menjelaskan masalah, tujuan, alternatif, kompatibilitas, risiko,
dan strategi pengujian. Tidak adanya tanggapan bukan persetujuan. Keputusan
dicatat pada isu atau pull request terkait agar dapat ditelusuri.

## Prinsip evolusi bahasa

Bahasa Indonesia adalah bentuk sintaks kanonis. Padanan Inggris dalam dokumen
bersifat penjelas. Penambahan alias bahasa lain memerlukan proposal tersendiri
karena memengaruhi ambiguitas, pesan galat, tooling, pengujian, dan biaya
pemeliharaan.

Sebelum 1.0, perubahan yang tidak kompatibel diperbolehkan, tetapi harus masuk
`CHANGELOG.md` dan menyediakan petunjuk migrasi bila sudah memengaruhi contoh
atau pengguna.

## Peran kontribusi

- **Kontributor** mengirim isu, dokumentasi, kode, desain, atau pengujian.
- **Peninjau** memberi umpan balik teknis berdasarkan bukti dan ruang lingkup.
- **Pemelihara** memiliki wewenang merge, triase keamanan, moderasi, dan rilis.

Hak akses diberikan berdasarkan rekam jejak, kebutuhan proyek, dan kepatuhan
terhadap kode etik; bukan berdasarkan jumlah kontribusi semata.

## Kebijakan proyek

- Kontribusi mengikuti `../CONTRIBUTING.md`.
- Perilaku komunitas mengikuti `../CODE_OF_CONDUCT.md`.
- Kerentanan dilaporkan melalui `../SECURITY.md`.
- Distribusi kode mengikuti lisensi MIT pada `../LICENSE`.
