use nusacode::{check, lex, run, Interpreter, NusaError};

fn output(source: &str) -> String {
    run(source).unwrap_or_else(|error| panic!("program gagal: {error}"))
}

#[test]
fn arithmetic_values_and_conversions() {
    let source = r#"
ubah angka <- 2 + 3 * 4
var pecahan = angka / 4
ubah data <- [angka, pecahan, "Nusa", benar, kosong]
tulis(angka)
print(pecahan)
tulis(panjang(data))
tulis(ubah_teks(data[2]) + "Code")
tulis(ubah_bilangan("42") + 1)
tulis(ubah_desimal("2.5") * 2)
"#;
    assert_eq!(output(source), "14\n3.5\n5\nNusaCode\n43\n5\n");
}

#[test]
fn control_flow_ranges_and_assignment() {
    let source = r#"
ubah total <- 0
untuk i dari 1 sampai 5 langkah 2 maka
    total <- total + i
akhir_untuk
selama total < 12 maka
    total <- total + 1
akhir_selama
jika total < 10 maka
    tulis("kecil")
atau_jika total = 12 maka
    tulis("tepat")
selain
    tulis("besar")
akhir_jika
"#;
    assert_eq!(output(source), "tepat\n");
}

#[test]
fn english_aliases_have_identical_behavior() {
    let source = r#"
let total <- 0
for i from 3 to 1 step -1 do
    total <- total + i
end_for
if total = 6 and not false do
    print("ok")
else
    print("bad")
end_if
"#;
    assert_eq!(output(source), "ok\n");
}

#[test]
fn functions_recurse_and_return() {
    let source = r#"
fungsi faktorial(n) maka
    jika n <= 1 maka
        kembalikan 1
    akhir_jika
    kembalikan n * faktorial(n - 1)
akhir_fungsi
print(faktorial(6))
"#;
    assert_eq!(output(source), "720\n");
}

#[test]
fn lists_maps_and_indexing_work() {
    let source = r#"
ubah orang <- {"nama": "Ayu", "nilai": [8, 9, 10]}
tulis(orang["nama"])
tulis(orang["nilai"][1])
tulis(length(orang))
"#;
    assert_eq!(output(source), "Ayu\n9\n2\n");
}

#[test]
fn integer_math_preserves_i64_precision_and_assignment_arrow() {
    let source = r#"
ubah besar <- 9007199254740993
ubah hasil <- besar - 1
tulis(hasil)
ubah x <- 1
x = 2
tulis(x)
tulis(3000000001 * 3)
"#;
    assert_eq!(output(source), "9007199254740992\n1\n9000000003\n");
}

#[test]
fn functional_collection_and_numeric_builtins_work() {
    let source = r#"
ubah angka <- [2, 4]
angka <- dorong(angka, 6)
angka <- push(angka, abs(-8))
tulis(angka)
tulis(mutlak(-2.5))
"#;
    assert_eq!(output(source), "[2, 4, 6, 8]\n2.5\n");
}

#[test]
fn semicolons_and_newlines_separate_statements() {
    assert_eq!(output("ubah a <- 1; ubah b <- 2\nprint(a + b)\n"), "3\n");
}

#[test]
fn interpreter_preserves_globals_between_executions() {
    let mut interpreter = Interpreter::new();
    interpreter.execute("ubah x <- 40\n").unwrap();
    interpreter.execute("x <- x + 2\ntulis(x)\n").unwrap();
    assert_eq!(interpreter.take_output(), "42\n");
}

#[test]
fn diagnostics_include_indonesian_position() {
    let error = check("ubah x <- [1,\n").unwrap_err();
    let message = error.to_string();
    assert!(message.contains("Kesalahan sintaksis"));
    assert!(message.contains("baris 2"));

    let error = run("tulis(tidak_ada)\n").unwrap_err();
    assert!(matches!(error, NusaError::Runtime(_)));
    assert!(error.to_string().contains("tidak didefinisikan"));
}

#[test]
fn lexer_tracks_unicode_columns() {
    let tokens = lex("ubah café <- 1\n").unwrap();
    assert_eq!(tokens[1].position.line, 1);
    assert_eq!(tokens[1].position.column, 6);
}
