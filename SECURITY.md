# Kebijakan Keamanan

## Versi yang didukung

NusaCode masih pra-rilis. Seri `0.1.x` dan cabang `main` menerima perbaikan
keamanan berdasarkan upaya terbaik; belum ada jaminan dukungan jangka panjang.

## Melaporkan kerentanan

Jangan melaporkan kerentanan melalui isu, diskusi, atau pull request publik.

1. Gunakan fitur **Report a vulnerability** pada tab **Security** repositori
   untuk membuat private vulnerability report apabila fitur tersebut tersedia.
2. Jika fitur itu tidak tersedia, hubungi pemelihara secara privat melalui
   kanal kontak yang tercantum pada profil pemilik repositori.
3. Sertakan versi atau commit, platform, prasyarat, langkah reproduksi minimal,
   dampak, dan saran mitigasi bila ada.
4. Hindari menyertakan data nyata, kredensial, atau eksploitasi destruktif.

Pemelihara akan berusaha mengakui laporan dalam 7 hari kalender, melakukan
triase dalam 14 hari, dan memberi pembaruan berkala hingga penyelesaian. Waktu
perbaikan bergantung pada dampak dan kompleksitas. Mohon beri kesempatan untuk
menerbitkan perbaikan sebelum pengungkapan publik dikoordinasikan.

## Ruang lingkup

Laporan yang relevan mencakup interpreter, pemrosesan berkas `.nusa`, workflow
rilis, dan ekstensi editor yang diterbitkan proyek. Masalah penggunaan bahasa
yang tidak berdampak pada kerahasiaan, integritas, atau ketersediaan sebaiknya
dilaporkan sebagai bug biasa.

Interpreter belum memiliki sandbox, batas waktu, atau batas konsumsi memori.
Jangan menjalankan sumber `.nusa` yang tidak tepercaya. Laporan denial of service,
panic, pelolosan batas interpreter, injeksi command pada integrasi editor, path
traversal, serta manipulasi artefak rilis sangat diprioritaskan.
