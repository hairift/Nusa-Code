# Referensi Bahasa Nusa

Dokumen ini mendeskripsikan perilaku implementasi referensi `0.1.0`. Seluruh
kontrak dapat berubah sebelum versi 1.0.

## Identitas

| Atribut | Nilai |
|---|---|
| Ekstensi | `.nusa` |
| Paradigma | Imperatif, fungsional ringan, scripting |
| Implementasi utama | Interpreter Rust lintas platform |
| Blok | Kata penutup eksplisit |
| Penugasan | `<-` |
| Perbandingan sama | `=` atau `==` |
| Encoding sumber | Unicode/UTF-8 |

Indentasi dianjurkan tetapi tidak memiliki makna semantik. Pernyataan dipisahkan
baris baru atau `;`.

## Kata kunci dwibahasa

Kedua bentuk pada setiap baris identik secara semantik dan boleh dicampur.

| Indonesia | Inggris |
|---|---|
| `ubah`, `var` | `let` |
| `jika` | `if` |
| `maka` | `do` |
| `atau_jika` | `else_if` |
| `selain` | `else` |
| `akhir_jika` | `end_if` |
| `selama` | `while` |
| `akhir_selama` | `end_while` |
| `untuk` | `for` |
| `dari` | `from` |
| `sampai` | `to` |
| `langkah` | `step` |
| `akhir_untuk` | `end_for` |
| `fungsi` | `function` |
| `akhir_fungsi` | `end_function` |
| `kembalikan` | `return` |
| `benar`, `salah` | `true`, `false` |
| `kosong` | `null` |
| `dan`, `atau`, `tidak` | `and`, `or`, `not` |

## Komentar dan nama

Komentar dimulai `#` hingga akhir baris. Nama dapat dimulai huruf Unicode atau
`_`, kemudian diikuti huruf, angka, atau `_`. Nama peka huruf besar-kecil.

```nusa
# Komentar satu baris
ubah café <- "Nusa"  # Unicode dapat dipakai pada nama
```

## Nilai

| Tipe | Contoh | Catatan |
|---|---|---|
| Bilangan | `42`, `-7` | signed 64-bit |
| Desimal | `3.14` | IEEE-754 64-bit |
| Teks | `"Nusa"`, `'kode'` | Unicode |
| Logika | `benar`, `salah` | boolean |
| Kosong | `kosong` | ketiadaan nilai |
| Daftar | `[1, 2, 3]` | berurutan |
| Kamus | `{"nama": "Ayu"}` | kunci sederhana |

Escape teks: `\n`, `\t`, `\r`, `\\`, `\"`, dan `\'`. Literal teks tidak dapat
melintasi baris.

## Variabel

```nusa
ubah nama <- "Nusa"
var versi = 1
nama <- nama + "Code"
```

`ubah`, `var`, dan `let` mendeklarasikan binding. `<-` adalah penugasan kanonis.
`=` diterima saat deklarasi untuk kompatibilitas awal, tetapi pada ekspresi selalu
berarti perbandingan. Menugaskan nama yang belum ada menghasilkan error.

## Operator

Urutan prioritas dari tinggi ke rendah:

| Kelompok | Operator |
|---|---|
| Postfix | panggilan `()`, indeks `[]` |
| Unary | `-`, `tidak/not` |
| Pangkat | `**` |
| Perkalian | `*`, `/`, `//`, `%` |
| Penjumlahan | `+`, `-` |
| Perbandingan | `<`, `<=`, `>`, `>=` |
| Kesamaan | `=`, `==`, `!=` |
| Logika | `dan/and`, lalu `atau/or` |

`+` mendukung bilangan, teks dengan teks, dan daftar dengan daftar. `/` dapat
menghasilkan desimal. `//` dan `%` memerlukan bilangan bulat. Pangkat asosiatif
kanan. Operasi bilangan yang tidak cocok menghasilkan diagnostik runtime.

Nilai `salah`, `kosong`, `0`, dan `0.0` dianggap salah. Operator logika melakukan
short-circuit dan mengembalikan operand terpilih.

## Percabangan

```nusa
jika nilai >= 80 maka
    tulis("baik")
atau_jika nilai >= 60 maka
    tulis("cukup")
selain
    tulis("belajar lagi")
akhir_jika
```

`maka/do` opsional pada implementasi 0.1, tetapi dianjurkan untuk keterbacaan.

## Perulangan

```nusa
ubah i <- 0
selama i < 3 maka
    tulis(i)
    i <- i + 1
akhir_selama

untuk angka dari 1 sampai 5 langkah 2 maka
    tulis(angka)
akhir_untuk
```

Rentang `untuk` inklusif. Langkah bawaan adalah `1`; langkah negatif mendukung
rentang menurun. Langkah nol menghasilkan error.

## Fungsi dan closure

```nusa
fungsi buat_penambah(x) maka
    fungsi tambah(y) maka
        kembalikan x + y
    akhir_fungsi
    kembalikan tambah
akhir_fungsi

ubah tambah_dua <- buat_penambah(2)
tulis(tambah_dua(5))
```

Parameter memiliki arity tetap. Fungsi tanpa `kembalikan` menghasilkan `kosong`.
Fungsi menangkap lingkungan leksikal dan dapat rekursif. Runtime membatasi
kedalaman panggilan hingga 1.000.

## Daftar, kamus, dan indeks

```nusa
ubah angka <- [2, 4, 6]
ubah profil <- {"nama": "Ayu", "nilai": angka}

tulis(angka[0])
tulis(angka[-1])
tulis(profil["nama"])
tulis("Nusa"[1])
```

Daftar dan teks mendukung indeks negatif. Kunci kamus dapat berupa teks,
bilangan, desimal, logika, atau kosong; implementasi 0.1 menormalisasikannya
menjadi representasi teks internal.

## Fungsi baku

| Indonesia | Inggris | Perilaku |
|---|---|---|
| `tulis(...)` | `print(...)` | cetak argumen dan baris baru |
| `tulis_tanpa_baris(...)` | `print_inline(...)` | cetak tanpa baris baru |
| `baca(prompt?)` | `input(prompt?)` | baca satu baris stdin |
| `panjang(x)` | `length(x)` | panjang teks, daftar, atau kamus |
| `ubah_teks(x)` | `string(x)`, `to_string(x)` | konversi ke teks |
| `ubah_bilangan(x)` | `integer(x)`, `to_integer(x)` | konversi ke bilangan |
| `ubah_desimal(x)` | `float(x)`, `to_float(x)` | konversi ke desimal |
| `tipe(x)` | `type(x)` | nama tipe dalam Bahasa Indonesia |
| `dorong(d, x)` | `push(d, x)` | hasilkan daftar baru dengan unsur tambahan |
| `mutlak(x)` | `absolute(x)`, `abs(x)` | nilai absolut |

Karena daftar memiliki semantik nilai pada 0.1, gunakan:

```nusa
angka <- dorong(angka, 8)
```

## Diagnostik

Error dikelompokkan sebagai leksikal, sintaksis, atau runtime dan menyertakan
baris serta kolom. CLI mengembalikan exit code non-nol saat gagal.

## Batasan

Belum tersedia modul/import, class, exception, async, pattern matching, mutasi
indeks, interpolasi teks, package manager, sandbox, formatter, debugger, dan
language server. Lihat `../ROADMAP.md` untuk arah pengembangan.
